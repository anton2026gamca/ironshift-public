extends Node2D
class_name Terrain


const MIN_ELEVATION: int = -20
const MAX_ELEVATION: int = 20

@onready var chunk_loader: Node = $"ChunkLoader"
@onready var layer_template: TerrainLayer = $Layer
@onready var tileset_duplicator: TilesetDuplicator = $TilesetDuplicator
var object_template: PackedScene = preload("res://Scenes/Terrain/object.tscn")

const TILE_SIZE: int = 16
const LAYER_SHIFT: int = -5
var layers: Dictionary = {}

var world_save_path: String = ""
var world: WorldSave

const CHUNK_SIZE: int = 8
var displayed_chunks: Array[Vector2] = []

var visible_chunks_x: int
var visible_chunks_y: int
var unload_distance: int = 20

#@warning_ignore("shadowed_global_identifier")
#var seed: int = randi() #385220940

enum Biome { OCEAN, MEADOW, OAK_FOREST, SPRUCE_FOREST, MOUNTAINS }

var thread: Thread = Thread.new()
var mutex: Mutex = Mutex.new()

var unloading_chunks: bool = false

var chunks_to_load: Array[Vector2]
var loading_chunks: bool = false
var chunks_to_display: Array[Vector2]
var displaying_chunk: bool = false

@export var world_manager: WorldManager
@onready var player: Player = world_manager.player
@onready var loading_screen: Control = world_manager.loading_screen

signal start


func create_layer(elevation: int, tileset: TileSet) -> void:
	var layer: TerrainLayer = layer_template.duplicate()
	layer.name = "Z " + str(elevation)
	layer.visible = true
	layer.z = elevation
	layer.ground = layer.get_node("Ground")
	layer.objects = layer.get_node("Objects")
	layer.ground.position = Vector2(0, elevation * LAYER_SHIFT)
	layer.ground.tile_set = tileset
	layer.ground.y_sort_origin = -elevation * LAYER_SHIFT
	layer.ground.material = layer.ground.material.duplicate()
	add_child(layer)
	layers[elevation] = layer


func _ready() -> void:
	if loading_screen:
		loading_screen.visible = true
		await get_tree().process_frame
	
	if not world_manager:
		push_error("world_manager is null!")
		get_tree().quit(1)
	if not player:
		push_error("player is null!")
		await world_manager.quit_world()
	
	world_save_path = SceneSwitcher.get_param("world_save_path")
	if not world_save_path:
		push_error("Couldn't load world \"\"!")
		await world_manager.quit_world()
	if not FileAccess.file_exists(world_save_path):
		push_error("Couldn't load world \"" + world_save_path + "\"!")
		await world_manager.quit_world()
	await load_world(world_save_path)
	
	visible_chunks_x = ceil(get_viewport().size.x / float(CHUNK_SIZE) / float(TILE_SIZE * scale.x)) + 4 + 5
	visible_chunks_y = ceil(get_viewport().size.y / float(CHUNK_SIZE) / float(TILE_SIZE * scale.y)) + 4 + 5
	var ground_tileset: TileSet = layer_template.ground.tile_set
	var duplicate_count: int = MAX_ELEVATION - MIN_ELEVATION + 1
	var tilesets: Array = tileset_duplicator.duplicate_tileset(ground_tileset, duplicate_count, OS.get_processor_count())
	for z: int in range(MIN_ELEVATION, MAX_ELEVATION + 1):
		create_layer(z, tilesets[z - MIN_ELEVATION])
	for z: int in range(MIN_ELEVATION, MAX_ELEVATION + 1):
		layers[z].ground.time_passed = float(z - MIN_ELEVATION) / float(MAX_ELEVATION - MIN_ELEVATION) * layers[z].ground.update_interval
	await initial_load_chunks(player.position)
	
	if loading_screen:
		loading_screen.visible = false
	start.emit()

func _process(_delta: float) -> void:
	visible_chunks_x = ceil(get_viewport().size.x / float(CHUNK_SIZE) / float(TILE_SIZE * scale.x)) + 4
	visible_chunks_y = ceil(get_viewport().size.y / float(CHUNK_SIZE) / float(TILE_SIZE * scale.y)) + 4
	unload_distance = ceil((visible_chunks_x + 4) / 2.0)
	
	if not loading_chunks:
		chunks_to_load = get_chunks_to_load(player.position)
		if len(chunks_to_load) > 0:
			if thread.is_started():
				thread.wait_to_finish()
			thread.start.call_deferred(load_chunks.bind(chunks_to_load))
	
	if not displaying_chunk:
		if len(chunks_to_display) > 0:
			display_chunk.call_deferred(chunks_to_display[0])
			chunks_to_display.remove_at(0)
		else:
			chunks_to_display = get_chunks_to_display(player.position)
	
	unload_chunks(1)


func initial_load_chunks(camera_position: Vector2) -> void:
	load_chunks(get_chunks_to_load(camera_position))
	chunks_to_display = get_chunks_to_display(camera_position)
	while len(chunks_to_display) > 0: 
		display_chunk(chunks_to_display[0], true)
		chunks_to_display.remove_at(0)
		if loading_screen:
			await get_tree().process_frame

func load_chunks(chunks: Array[Vector2]) -> void:
	mutex.lock()
	loading_chunks = true
	var new_chunks: Dictionary = {}
	mutex.unlock()
	
	for chunk: Vector2 in chunks:
		new_chunks[chunk] = chunk_loader.load_chunk(world.seed, CHUNK_SIZE, chunk, MIN_ELEVATION, MAX_ELEVATION)
	
	mutex.lock()
	for key: Vector2 in new_chunks.keys():
		world.chunks[key] = new_chunks[key]
	loading_chunks = false
	mutex.unlock()

func display_chunk(chunk_pos: Vector2, single_frame: bool = false) -> void:
	displaying_chunk = true
	if not world.chunks.has(chunk_pos):
		return
	
	if displayed_chunks.has(chunk_pos):
		return
	displayed_chunks.append(chunk_pos)
	
	for z: int in range(MAX_ELEVATION, MIN_ELEVATION - 1, -1):
		if z % 10 == 1 and not single_frame:
			await get_tree().process_frame
		for y: int in range(CHUNK_SIZE):
			for x: int in range(CHUNK_SIZE):
				var world_x: int = int(chunk_pos.x * CHUNK_SIZE + x)
				var world_y: int = int(chunk_pos.y * CHUNK_SIZE + y)
				if world.chunks[chunk_pos].tiles[z][y][x]:
					var tile_overlapped = get_tile_overlaped(Vector3i(world_x, world_y, z))
					if not world.chunks[chunk_pos].tiles[z][y][x].is_empty() and world.chunks[chunk_pos].tiles[z][y][x]["id"] != ItemDatabase.Tile.AIR and not tile_overlapped:
						layers[z].ground.set_tile(Vector2i(world_x, world_y), world.chunks[chunk_pos].tiles[z][y][x]["id"])
				if world.chunks[chunk_pos].objects[z][y][x] is Dictionary:
					place_object(Vector3i(world_x, world_y, z), world.chunks[chunk_pos].objects[z][y][x]["id"], world.chunks[chunk_pos].objects[z][y][x]["data"], true)
	displaying_chunk = false

func unload_chunks(count: int) -> void:
	var camera_chunk: Vector2i = Vector2i(
		int(player.position.x / CHUNK_SIZE / (TILE_SIZE * scale.x)),
		int(player.position.y / CHUNK_SIZE / (TILE_SIZE * scale.y))
	)
	
	var chunks: Array = world.chunks.keys()
	var unloaded_chunks: int = 0
	var i = 0
	while unloaded_chunks < count and chunks.has(i):
		var unload: bool = false
		if chunks[i].x + unload_distance < camera_chunk.x or chunks[i].x - unload_distance > camera_chunk.x or chunks[i].y + unload_distance < camera_chunk.y or chunks[i].y - unload_distance > camera_chunk.y:
			unload_chunk(chunks[i])
			unloaded_chunks += 1
		i += 1

func unload_chunk(chunk_pos: Vector2) -> void:
	for z: int in range(MIN_ELEVATION, MAX_ELEVATION + 1):
		for x: int in range(CHUNK_SIZE):
			for y: int in range(CHUNK_SIZE):
				var world_pos: Vector2 = Vector2(chunk_pos.x * CHUNK_SIZE + x, chunk_pos.y * CHUNK_SIZE + y)
				layers[z].ground.set_tile(world_pos)
				if world.chunks.has(chunk_pos):
					var obj = get_object(Vector3i(x, y, z))
					if obj and obj.has("node") and obj["node"]:
						remove_object(Vector3i(x, y, z))
	if displayed_chunks.has(chunk_pos):
		displayed_chunks.erase(chunk_pos)

func get_chunks_to_load(camera_position: Vector2) -> Array[Vector2]:
	var chunks: Array[Vector2] = []
	for chunk in get_visible_chunks(camera_position):
		if not world.chunks.has(chunk):
			chunks.append(chunk)
	
	return chunks

func get_chunks_to_display(camera_position: Vector2) -> Array[Vector2]:
	var chunks: Array[Vector2] = []
	for chunk in get_visible_chunks(camera_position):
		if not displayed_chunks.has(chunk) and world.chunks.has(chunk):
			chunks.append(chunk)
	
	return chunks

func get_visible_chunks(camera_position: Vector2) -> Array[Vector2]:
	var camera_chunk: Vector2i = Vector2i(
		int(camera_position.x / CHUNK_SIZE / (TILE_SIZE * scale.x)),
		int(camera_position.y / CHUNK_SIZE / (TILE_SIZE * scale.y))
	)
	
	var chunks: Array[Vector2] = []
	for y: int in range(camera_chunk.y - ceil(visible_chunks_y / 2.0), camera_chunk.y + ceil(visible_chunks_y / 2.0)):
		for x: int in range(camera_chunk.x - ceil(visible_chunks_x / 2.0), camera_chunk.x + ceil(visible_chunks_x / 2.0)):
			chunks.append(Vector2(x, y))
	
	return chunks

func get_tile(coords: Vector3i) -> Dictionary:
	var chunk: Vector2 = Vector2(
		floor(float(coords.x) / float(CHUNK_SIZE)),
		floor(float(coords.y) / float(CHUNK_SIZE))
	)
	
	var tile: Vector2i = Vector2i(coords.x % CHUNK_SIZE, coords.y % CHUNK_SIZE)
	if tile.x < 0: tile.x += CHUNK_SIZE
	if tile.y < 0: tile.y += CHUNK_SIZE
	
	if not world.chunks.has(chunk):
		return {"id": ItemDatabase.Tile.AIR}
	if not world.chunks[chunk].tiles[coords.z][tile.y][tile.x]:
		return {"id": ItemDatabase.Tile.AIR}
	return world.chunks[chunk].tiles[coords.z][tile.y][tile.x]

func set_tile(coords: Vector3i, tile_id: int, internal: bool = false) -> void:
	var chunk: Vector2 = Vector2(
		floor(float(coords.x) / float(CHUNK_SIZE)),
		floor(float(coords.y) / float(CHUNK_SIZE))
	)
	
	if not world.chunks.has(chunk):
		return
	
	var tile: Vector2i = Vector2i(coords.x % CHUNK_SIZE, coords.y % CHUNK_SIZE)
	if tile.x < 0: tile.x += CHUNK_SIZE
	if tile.y < 0: tile.y += CHUNK_SIZE
	
	world.chunks[chunk].tiles[coords.z][tile.y][tile.x]["id"] = tile_id
	if tile_id == ItemDatabase.Tile.AIR and get_object(coords):
		remove_object(coords)
	
	layers[coords.z].ground.set_tile(Vector2i(coords.x, coords.y), tile_id)
	
	if not internal:
		for z in range(-1, 2):
			if coords.z + z < MIN_ELEVATION or coords.z + z > MAX_ELEVATION:
				continue
			for x in range(-1, 2):
				for y in range(-1, 2):
					if x == 0 and y == 0 and z == 0:
						continue
					var c: Vector3i = coords + Vector3i(x, y, z)
					set_tile(c, get_tile(c)["id"], true)
			layers[coords.z + z].ground.update_shader(player.position)

func get_object(coords: Vector3i) -> Dictionary:
	var chunk: Vector2 = Vector2(
		floor(float(coords.x) / float(CHUNK_SIZE)),
		floor(float(coords.y) / float(CHUNK_SIZE))
	)
	
	var tile: Vector2i = Vector2i(coords.x % CHUNK_SIZE, coords.y % CHUNK_SIZE)
	if tile.x < 0: tile.x += CHUNK_SIZE
	if tile.y < 0: tile.y += CHUNK_SIZE
	
	if not world.chunks.has(chunk):
		return {"id": ItemDatabase.Obj.NONE}
	elif not world.chunks[chunk].objects[coords.z][tile.y][tile.x]:
		return {"id": ItemDatabase.Obj.NONE}
	elif world.chunks[chunk].objects[coords.z][tile.y][tile.x] is Vector3i:
		return get_object(coords + world.chunks[chunk].objects[coords.z][tile.y][tile.x])
	return world.chunks[chunk].objects[coords.z][tile.y][tile.x]

func can_place_object(coords: Vector3i, obj_data: WorldObjectData) -> bool:
	for x in range(obj_data.grid_size.x):
		for y in range(obj_data.grid_size.y):
			if get_object(coords + Vector3i(x, y, 0))["id"] != ItemDatabase.Obj.NONE or get_tile(coords + Vector3i(x, y, 0))["id"] == ItemDatabase.Tile.AIR or get_tile(coords + Vector3i(x, y, 1))["id"] != ItemDatabase.Tile.AIR:
				return false
	return true

func place_object(coords: Vector3i, id: ItemDatabase.Obj, data: WorldObjectData, force_place: bool = false) -> int:
	if not force_place and not can_place_object(coords, data):
		print("Can not place an object on top of another object!")
		return 1
	
	for x in range(data.grid_size.x):
		for y in range(data.grid_size.y):
			var world_tile: Vector3i = coords + Vector3i(x, y, 0)
			var chunk_pos: Vector2 = Vector2(
				floor(float(world_tile.x) / float(CHUNK_SIZE)),
				floor(float(world_tile.y) / float(CHUNK_SIZE))
			)
			
			var tile_in_chunk: Vector3i = Vector3i(world_tile.x % CHUNK_SIZE, world_tile.y % CHUNK_SIZE, world_tile.z)
			if tile_in_chunk.x < 0: tile_in_chunk.x += CHUNK_SIZE
			if tile_in_chunk.y < 0: tile_in_chunk.y += CHUNK_SIZE
			
			if x == 0 and y == 0:
				world.chunks[chunk_pos].objects[tile_in_chunk.z][tile_in_chunk.y][tile_in_chunk.x] = {
					"id": id,
					"data": data,
					"node": null
				}
				var object: WorldObject = object_template.instantiate()
				if id == ItemDatabase.Obj.FURNACE:
					object.name = "Furnace"
				object.position = Vector2(world_tile.x + data.grid_size.x / 2.0, world_tile.y + 0.5 + data.grid_size.y / 2.0) * TILE_SIZE
				object.data = data
				object.world = world_manager
				object.add_to_group("terrain-objects")
				object.coords = Vector3i(world_tile.x, world_tile.y, world_tile.z)
				layers[world_tile.z].objects.add_child(object)
				object.spawn(Player.SPRITE_OFFSET + world_tile.z * LAYER_SHIFT)
				object.set_transparency(1)
				world.chunks[chunk_pos].objects[tile_in_chunk.z][tile_in_chunk.y][tile_in_chunk.x]["node"] = get_path_to(object)
			else:
				world.chunks[chunk_pos].objects[tile_in_chunk.z][tile_in_chunk.y][tile_in_chunk.x] = Vector3i(-x, -y, 0)
	
	for x in range(data.grid_size.x + 2):
		for y in range(data.grid_size.y + 2):
			if x > 0 and x < data.grid_size.x + 1 and y > 0 and y < data.grid_size.y + 1:
				continue
			var obj: Dictionary = get_object(coords + Vector3i(-1 + x, -1 + y, 0))
			if obj.has("node") and obj["node"]:
				var node: Node = get_node_or_null(obj["node"])
				if node is WorldObject:
					node.update_state()
	
	return 0

func remove_object(coords: Vector3i) -> void:
	var main_chunk_pos: Vector2 = Vector2(
		floor(float(coords.x) / float(CHUNK_SIZE)),
		floor(float(coords.y) / float(CHUNK_SIZE))
	)
	
	if not world.chunks.has(main_chunk_pos):
		return
	
	var tile: Vector2i = Vector2i(coords.x % CHUNK_SIZE, coords.y % CHUNK_SIZE)
	if tile.x < 0: tile.x += CHUNK_SIZE
	if tile.y < 0: tile.y += CHUNK_SIZE
	
	var obj: Dictionary = get_object(coords)
	if obj["id"] == ItemDatabase.Obj.NONE:
		return
	if obj.has("node") and obj["node"]:
		var node = get_node_or_null(obj["node"])
		if node is WorldObject:
			node.delete()
	var offset: Vector3i = world.chunks[main_chunk_pos].objects[coords.z][tile.y][tile.x] if world.chunks[main_chunk_pos].objects[coords.z][tile.y][tile.x] is Vector3i else Vector3i.ZERO
	for x in range(max(obj["data"].grid_size.x, 1)):
		for y in range(max(obj["data"].grid_size.y, 1)):
			var world_tile: Vector3i = coords + Vector3i(x, y, 0) + offset
			var chunk_pos: Vector2 = Vector2(
				floor(float(world_tile.x) / float(CHUNK_SIZE)),
				floor(float(world_tile.y) / float(CHUNK_SIZE))
			)
			
			var tile_in_chunk: Vector3i = Vector3i(world_tile.x % CHUNK_SIZE, world_tile.y % CHUNK_SIZE, world_tile.z)
			if tile_in_chunk.x < 0: tile_in_chunk.x += CHUNK_SIZE
			if tile_in_chunk.y < 0: tile_in_chunk.y += CHUNK_SIZE
			
			world.chunks[chunk_pos].objects[tile_in_chunk.z][tile_in_chunk.y][tile_in_chunk.x] = null

func get_tile_overlaped(tile: Vector3i) -> bool:
	var y_offset: float = 0
	var i: int = 0
	for z: int in range(tile.z + 1, MAX_ELEVATION + 1):
		y_offset -= float(LAYER_SHIFT) / float(TILE_SIZE)
		var y_top: int = floor(tile.y + y_offset)
		var y_bottom: int = ceil(tile.y + y_offset)
		var tile_top: Dictionary = get_tile(Vector3i(tile.x, y_top, z))
		var tile_bottom: Dictionary = get_tile(Vector3i(tile.x, y_bottom, z))
		if not tile_top.is_empty() and tile_top["id"] != ItemDatabase.Tile.AIR and tile_top["id"] != ItemDatabase.Tile.WATER:
			if not tile_bottom.is_empty() and tile_bottom["id"] != ItemDatabase.Tile.AIR and tile_bottom["id"] != ItemDatabase.Tile.WATER:
				i += 1
		if i >= 2:
			return true
	return false

func save_world(path) -> void:
	world.player_position = player.position
	world.player_z = player.z
	world.inventory = player.inventory.data.duplicate()
	
	ResourceSaver.save(world, path)

func load_world(path: String) -> void:
	world = ResourceLoader.load(path)
	if not world:
		push_error("Couldn't load world \"" + path + "\"!")
		await world_manager.quit_world()
	print("Seed: ", world.seed)
	
	player.position = world.player_position
	player.z = world.player_z
	if world.inventory:
		player.inventory.data = world.inventory
		player.inventory.init()

func _exit_tree() -> void:
	if thread.is_started():
		thread.wait_to_finish()
