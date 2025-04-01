extends CharacterBody2D
class_name Player


const SPRITE_OFFSET = -9.5

@export var normal_speed: float = 25.0
@export var sprint_speed: float = 40.0
@export var height: int = 4

@export var world_manager: WorldManager
@onready var terrain: Terrain = world_manager.terrain
@onready var pause_menu: PauseMenu = world_manager.pause_menu
@onready var inventory: Inventory = world_manager.inventory

@onready var offset_objects: Array[Node2D] = [
	$Sprite,
	$CollisionShape2D
]
var start_offset: Dictionary = {}
var current_offset := 0

@onready var jump_offset_objects: Array[Node2D] = [
	$Sprite
]
var jump_offset := 0.0
var jump_velocity := 0.0
const GRAVITY = 600
var falling = false
var sprinting = false

var z = 1;

var colliding_with = {}

@onready var body: AnimatedSprite2D = $Sprite/Body
@onready var head: AnimatedSprite2D = $Sprite/Head
var velocity_before_0: Vector2 = Vector2.DOWN

@onready var mouse: Area2D = $Camera2D/Mouse

@onready var placing_objects_parent: Node2D = $PlacingObjects
@onready var placing_objects: Array[WorldObjectData] = []

var selected_objects := {}
var _selected_object: Node2D
var selected_object: Node2D:
	set(value):
		_selected_object = value
	get:
		if inventory and not inventory.is_open and not pause_menu.is_open:
			return _selected_object
		return null
var selected_object_breaking_time: float = 0
var selected_object_last_frame: Node2D

var is_selected_tile: bool = false
var selected_tile: Vector3i
var selected_tile_breaking_time: float = 0
var is_selected_tile_before_place: bool = false
var selected_tile_before_place: Vector3i
var selected_tile_last_frame: Vector3i
var last_broken_tile: Vector3i

var placing_object_data: WorldObjectData

var mouse_left_press_time: float = 0

var tools_cooldown: Array[ToolData] = []

var initialized: bool = false

var tilesets_offsets: Dictionary = {}


func _ready() -> void:
	if not world_manager:
		push_error("world_manager is null!")
		get_tree().quit(1)
	
	terrain.start.connect(init)

func init() -> void:
	if inventory:
		inventory.opened.connect(_on_inventory_opened)
		inventory.closed.connect(_on_inventory_closed)
	if pause_menu:
		pause_menu.opened.connect(_on_pause_menu_opened)
		pause_menu.closed.connect(_on_pause_menu_closed)
	
	for obj in offset_objects:
		if obj is AnimatedSprite2D:
			obj.offset.y += SPRITE_OFFSET
			start_offset[obj] = obj.offset.y
		else:
			obj.position.y += SPRITE_OFFSET
			start_offset[obj] = obj.position.y
	jump(0)
	
	initialized = true

func _physics_process(delta: float) -> void:
	if not initialized:
		return
	
	mouse.global_position = get_global_mouse_position()
	
	sprinting = Input.is_action_pressed("sprint")
	
	if terrain:
		handle_jumping(delta)
	move(delta)
	
	var anim = get_animation()
	if anim != "":
		body.play(anim, 2 if sprinting else 1)
		head.play(anim, 2 if sprinting else 1)
	
	for i in range(len(tools_cooldown) - 1, -1, -1):
		if not tools_cooldown[i]:
			tools_cooldown.remove_at(i)
			continue
		
		tools_cooldown[i].cooldown_timer -= delta
		if tools_cooldown[i].cooldown_timer <= 0:
			tools_cooldown[i].cooldown_timer = 0
			tools_cooldown.remove_at(i)
	
	var hovered_tile: Vector2 = Vector2i.ZERO
	var highest_z: int = -10000000
	is_selected_tile = false
	for z: int in terrain.layers.keys():
		terrain.layers[z].ground.material.set_shader_parameter("is_selected_tile", false)
		
		var mouse_tile: Vector2 = get_global_mouse_position() / terrain.TILE_SIZE
		mouse_tile.y -= float(z * terrain.LAYER_SHIFT) / float(terrain.TILE_SIZE)
		if terrain.get_tile(Vector3i(floor(mouse_tile.x), floor(mouse_tile.y), z))["id"] != ItemDatabase.Tile.AIR and z > highest_z:
			highest_z = z
			hovered_tile = mouse_tile
	
	var placing_object: Sprite2D = null
	inventory.dragging_slot.visible = true
	if inventory.data.holding_slot.item is InventoryPlaceableObjectData and not inventory.is_open and not pause_menu.is_open:
		var obj_data: WorldObjectData = inventory.data.holding_slot.item.get_data()
		var tile_to_place_on: Vector3i = Vector3i(floor(hovered_tile.x), floor(hovered_tile.y), highest_z)
		inventory.dragging_slot.visible = false
		for i in range(len(placing_objects) - 1, -1, -1):
			if placing_objects[i].name != obj_data.name or placing_object != null:
				placing_objects.remove_at(i)
				if placing_objects_parent.get_child(i):
					placing_objects_parent.remove_child(placing_objects_parent.get_child(i))
					placing_objects_parent.get_child(i).queue_free()
			else:
				placing_object = placing_objects_parent.get_child(i)
		if placing_object == null:
			placing_object = obj_data.get_scene().instantiate()
			placing_object_data = obj_data.duplicate()
			if placing_object is WorldObjectInstance:
				placing_object.data = placing_object_data
			if placing_object.material is ShaderMaterial:
				placing_object.material.set_shader_parameter("transparency", 0.5)
			else:
				placing_object.modulate.a = 0.5
			placing_objects_parent.add_child(placing_object)
			placing_objects.append(obj_data)
		if placing_object is WorldObjectInstance:
			if Input.is_action_just_pressed("rotate_object") and placing_object.data.can_rotate:
				placing_object.update_rotation(placing_object.data.rotation + 90)
			elif Input.is_action_just_pressed("rotate_object_reversed") and placing_object.data.can_rotate:
				placing_object.update_rotation(placing_object.data.rotation - 90)
		placing_object.global_position = Vector2(tile_to_place_on.x + obj_data.grid_size.x / 2.0, tile_to_place_on.y + obj_data.grid_size.y / 2.0) * terrain.TILE_SIZE
		placing_object.global_position.y += tile_to_place_on.z * terrain.LAYER_SHIFT     
	else:
		for child in placing_objects_parent.get_children():
			placing_objects_parent.remove_child(child)
			child.queue_free()
		placing_objects = []
	if highest_z > -10000000 and not selected_object and not inventory.is_open and not pause_menu.is_open:
		is_selected_tile = true
		selected_tile = Vector3i(floor(hovered_tile.x), floor(hovered_tile.y), highest_z)
		terrain.layers[highest_z].ground.material.set_shader_parameter("is_selected_tile", true)
		terrain.layers[highest_z].ground.material.set_shader_parameter("selected_tile", Vector2(selected_tile.x, selected_tile.y))
	
	if selected_object_last_frame != selected_object:
		selected_object_breaking_time = 0
		inventory.mining_progress.visible = false
	selected_object_last_frame = selected_object
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not inventory.is_open and not pause_menu.is_open:
		if selected_object is WorldObject and selected_object.data is PickupableObjectData:
			inventory.pickup(selected_object.data.pickup_stack.duplicate(true))
			terrain.remove_object(selected_object.coords)
		elif inventory.data.holding_slot.item is InventoryPlaceableObjectData:
			var tile_to_place_on: Vector3i = Vector3i(floor(hovered_tile.x), floor(hovered_tile.y), highest_z)
			var obj_id: ItemDatabase.Obj = inventory.data.holding_slot.item.object_to_place_id
			var obj_data: WorldObjectData = placing_object_data.duplicate()
			if terrain.can_place_object(tile_to_place_on, obj_data):
				terrain.place_object(tile_to_place_on, obj_id, obj_data, true)
				inventory.data.holding_slot.count -= 1
				if inventory.data.holding_slot.count <= 0:
					inventory.data.holding_slot.count = 0
					inventory.data.holding_slot.item = null
		if selected_object is WorldObject and selected_object.data is UIMenuObjectData:
			inventory.open_with_extension_node(selected_object.data.get_ui_menu())
		elif is_selected_tile:
			if selected_tile != selected_tile_last_frame:
				selected_tile_breaking_time = 0
				selected_tile_last_frame = selected_tile
				inventory.mining_progress.visible = false
			var selected_tile_id: ItemDatabase.Tile = terrain.get_tile(selected_tile)["id"] as ItemDatabase.Tile
			var data: WorldTileData = ItemDatabase.get_tile(selected_tile_id)
			if data is WorldDamagableTileData and inventory.data.holding_slot.item is ToolData:
				for tool_break_time: ToolWithValue in data.tools_break_time:
					if tool_break_time.tool.name == inventory.data.holding_slot.item.name:
						selected_tile_breaking_time += delta
						if selected_tile_breaking_time >= tool_break_time.value:
							selected_tile_breaking_time = 0
							inventory.mining_progress.visible = false
							terrain.set_tile(selected_tile, ItemDatabase.Tile.AIR)
							last_broken_tile = selected_tile
							inventory.data.holding_slot.item.health -= 1
							if inventory.data.holding_slot.item.health <= 0:
								inventory.data.holding_slot.item = null
								inventory.data.holding_slot.count = 0
							for stack_range: ItemStackRange in data.drop_itmes:
								var stack: ItemStack = ItemStack.new()
								stack.item = stack_range.item
								stack.count = stack_range.get_count()
								inventory.pickup(stack)
						else:
							inventory.mining_progress.max_health = tool_break_time.value
							inventory.mining_progress.health = selected_tile_breaking_time
							inventory.mining_progress.visible = true
						break
			if inventory.data.holding_slot.item is InventoryPlaceableTileData and (selected_tile != selected_tile_before_place or not is_selected_tile_before_place):
				var coords: Vector3i = selected_tile
				var mouse_in_tile: Vector2 = terrain.layers[coords.z].ground.get_local_mouse_position() - terrain.layers[coords.z].ground.map_to_local(Vector2i(coords.x, coords.y))
				if mouse_in_tile.y >= 3 and terrain.get_tile(Vector3i(selected_tile.x, selected_tile.y + 1, selected_tile.z))["id"] == ItemDatabase.Tile.AIR:
					coords.y += 1
				else:
					coords.z += 1
				if terrain.get_tile(coords)["id"] == ItemDatabase.Tile.AIR:
					if coords.z == selected_tile.z:
						selected_tile_before_place = selected_tile
						is_selected_tile_before_place = true
					else:
						selected_tile_before_place = Vector3i(selected_tile.x, selected_tile.y, selected_tile.z + 1)
						is_selected_tile_before_place = true
					terrain.set_tile(coords, inventory.data.holding_slot.item.tile_to_place)
					inventory.data.holding_slot.count -= 1
					if inventory.data.holding_slot.count <= 0:
						inventory.data.holding_slot.count = 0
						inventory.data.holding_slot.item = null
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not inventory.is_open and not pause_menu.is_open:
		if selected_object is WorldObject:
			if selected_object.data is PickupableObjectData:
				inventory.pickup(selected_object.data.pickup_stack.duplicate(true))
				terrain.remove_object(selected_object.coords)
			elif selected_object.data is WorldDamagableObjectData and not selected_object.data.broked:
				selected_object_breaking_time += delta
				var mining_with_tool: bool = false
				for tool_break_time: ToolWithValue in selected_object.data.tools_break_time:
					if inventory.data.holding_slot.item and tool_break_time.tool.name == inventory.data.holding_slot.item.name:
						inventory.mining_progress.max_health = tool_break_time.value
						inventory.mining_progress.health = selected_object_breaking_time
						inventory.mining_progress.visible = true
						mining_with_tool = true
						if selected_object_breaking_time >= tool_break_time.value:
							selected_object_breaking_time = 0
							terrain.remove_object(selected_object.coords)
							inventory.data.holding_slot.item.damage()
							tools_cooldown.append(inventory.data.holding_slot.item)
							break
				if not mining_with_tool and selected_object.data.fist_break_time > 0:
					inventory.mining_progress.max_health = selected_object.data.fist_break_time
					inventory.mining_progress.health = selected_object_breaking_time
					inventory.mining_progress.visible = true
					if selected_object_breaking_time >= selected_object.data.fist_break_time:
						selected_object_breaking_time = 0
						selected_object
						terrain.remove_object(selected_object.coords)
			else:
				selected_object_breaking_time = 0
	else:
		selected_tile_breaking_time = 0
		selected_object_breaking_time = 0
		inventory.mining_progress.visible = false
		is_selected_tile_before_place = false


func move(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	var speed = sprint_speed if sprinting else normal_speed
	velocity = direction.normalized() * speed * 1000 * delta * global_scale
	if velocity != Vector2.ZERO:
		velocity_before_0 = velocity
	move_and_slide()

func handle_jumping(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and jump_offset == 0:
		jump(-150)
	
	var jump_offset_before = jump_offset
	if falling:
		jump_offset += jump_velocity * delta
		var current_z: int = z + jump_offset / terrain.LAYER_SHIFT + (1 if jump_velocity > 0 else 0)
		if colliding_with.has(current_z) and colliding_with[current_z]:
			if jump_offset > (current_z - z) * terrain.LAYER_SHIFT:
				z = current_z
				reset_jump()
		jump_velocity += GRAVITY * delta
	else:
		jump_offset = 0
		if colliding_with.has(z) and not colliding_with[z]:
			jump(0)
	
	if jump_offset != jump_offset_before:
		for obj in jump_offset_objects:
			if obj is AnimatedSprite2D: obj.offset.y = start_offset[obj] + current_offset + jump_offset
			else: obj.position.y = start_offset[obj] + current_offset + jump_offset

func jump(velocity: float) -> void:
	jump_velocity = velocity
	falling = true
	collision_layer = 0b1000
	collision_mask = 0b1000

func reset_jump() -> void:
	jump_offset = 0
	jump_velocity = 0
	falling = false
	collision_layer = 0b0001
	collision_mask = 0b0001
	
	var new_z := -100000
	for i in range(terrain.MIN_ELEVATION, terrain.MAX_ELEVATION + 1):
		if not colliding_with.has(i):
			continue
		if colliding_with[i]:
			new_z = i
	if new_z > -10000:
		z = new_z
		for z in range(terrain.MIN_ELEVATION, terrain.MAX_ELEVATION + 1):
			var tileset: TileSet = terrain.layers[z].ground.tile_set
			if z <= new_z or z > new_z + height:
				if tileset.get_physics_layer_collision_layer(1) != 0b0010:
					tileset.set_physics_layer_collision_layer(1, 0b0010)
			else:
				if tileset.get_physics_layer_collision_layer(1) != 0b0001:
					tileset.set_physics_layer_collision_layer(1, 0b0001)
				offset_tileset_collisions(tileset, (new_z - z + 1) * terrain.LAYER_SHIFT * Vector2.DOWN)
	set_offset(z * terrain.LAYER_SHIFT)

func get_animation() -> String:
	var state = "idle" if abs(velocity.x) < 1 and abs(velocity.y) < 1 or falling else "walk"
	var direction = ""
	
	if velocity_before_0.y > 0:
		direction += "down"
	elif velocity_before_0.y < 0:
		direction += "up"
	if velocity_before_0.x > 0:
		if state == "idle":
			direction += "right"
		else:
			direction = "right"
	elif velocity_before_0.x < 0:
		if state == "idle":
			direction += "left"
		else:
			direction = "left"
	
	var anim_name = state + "-" + direction
	if direction == "":
		anim_name = ""
	
	return anim_name

func set_offset(offset: int) -> void:
	current_offset = offset
	for obj in offset_objects:
		if obj is AnimatedSprite2D: obj.offset.y = start_offset[obj] + offset
		else: obj.position.y = start_offset[obj] + offset

func _on_terrain_area_body_entered(body: Node2D) -> void:
	if terrain and body.get_parent() is TerrainLayer and body.is_in_group("terrain-ground"):
		var body_z: int = body.get_parent().get_z()
		colliding_with[body_z] = true

func _on_terrain_area_body_exited(body: Node2D) -> void:
	if terrain and body.get_parent() is TerrainLayer and body.is_in_group("terrain-ground"):
		var body_z: int = body.get_parent().get_z()
		colliding_with[body_z] = false

func _on_mouse_area_entered(area: Area2D) -> void:
	var obj: Node2D = area.get_parent().get_parent()
	if obj is WorldObject:
		selected_objects[obj] = obj.position.y
		update_selected_object()

func _on_mouse_area_exited(area: Area2D) -> void:
	var obj: Node2D = area.get_parent().get_parent()
	if obj is WorldObject:
		if selected_objects.has(obj):
			selected_objects.erase(obj)
		obj.set_outline_enabled(false)
		selected_object = null
		update_selected_object()

func update_selected_object():
	if not selected_objects.is_empty():
		var max: int = -2147483648
		for obj: Node2D in selected_objects.keys():
			if selected_objects[obj] > max:
				max = selected_objects[obj]
				selected_object = obj
			if obj is WorldObject:
				obj.set_outline_enabled(false)
		
		if selected_object is WorldObject and not inventory.is_open and not pause_menu.is_open:
			selected_object.set_outline_enabled(true)

func _on_inventory_opened():
	if _selected_object is WorldObject:
		_selected_object.set_outline_enabled(false)

func _on_inventory_closed():
	if _selected_object is WorldObject and not pause_menu.is_open:
		_selected_object.set_outline_enabled(true)

func _on_pause_menu_opened() -> void:
	if _selected_object is WorldObject:
		_selected_object.set_outline_enabled(false)

func _on_pause_menu_closed() -> void:
	if _selected_object is WorldObject and not inventory.is_open:
		_selected_object.set_outline_enabled(true)

func offset_tileset_collisions(tileset: TileSet, offset: Vector2 = Vector2.ZERO) -> void:
	var offsetted_offset: Vector2 = offset
	if tilesets_offsets.has(tileset):
		offsetted_offset -= tilesets_offsets[tileset]
	tilesets_offsets[tileset] = offset
	
	for source_index in tileset.get_source_count():
		var source_id = tileset.get_source_id(source_index)
		var source: TileSetSource = tileset.get_source(source_id)
		if source is TileSetAtlasSource:
			var grid_size = source.get_atlas_grid_size()
			
			for x in range(grid_size.x):
				for y in range(grid_size.y):
					var tile_coords = Vector2i(x, y)
					if source.has_tile(tile_coords):
						for alt_id: int in source.get_alternative_tiles_count(tile_coords):
							var tile_data: TileData = source.get_tile_data(tile_coords, alt_id)
							apply_offset_to_tile(tileset, tile_data, offsetted_offset)

func apply_offset_to_tile(tileset: TileSet, tile_data: TileData, offset: Vector2) -> void:
	for layer_id in range(tileset.get_physics_layers_count()):
		var polygon_count = tile_data.get_collision_polygons_count(layer_id)
		for polygon_index in range(polygon_count):
			var points: PackedVector2Array = tile_data.get_collision_polygon_points(layer_id, polygon_index)
			for i in range(points.size()):
				points[i] += offset
			tile_data.set_collision_polygon_points(layer_id, polygon_index, points)
