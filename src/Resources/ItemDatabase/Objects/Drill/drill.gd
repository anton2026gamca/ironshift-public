extends WorldObjectInstance
class_name Drill


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var mining_tiles: Array[MineableResourceTileData]

var is_down: bool = false
var mine_time_elapsed: float = 0
var anim_time_elapsed: float = 0
var fuel_remaining_time: float = 0

const ANIMATION_INTERVAL: float = 15


func _ready() -> void:
	super._ready()
	
	if parent:
		texture = null
		sprite.visible = true
		sprite.offset = offset
		sprite.material = material
		sprite.play("Spawn")
		update_resources(parent.coords, parent.world.terrain)
		data.mineable_resources_changed.emit()

func _process(delta: float) -> void:
	if parent:
		$OutputArrow.visible = material.get_shader_parameter("outline_width") != 0
		
		if len(mining_tiles) <= 0:
			if is_down:
				sprite.play("GoUp")
		else:
			if fuel_remaining_time <= 0:
				if data.fuel_stack and data.fuel_stack.count > 0 and data.fuel_stack.item is FuelItemData:
					fuel_remaining_time += data.fuel_stack.item.duration
					data.fuel_stack.count -= 1
					if data.fuel_stack.count <= 0:
						data.fuel_stack.item = null
			
			if fuel_remaining_time > 0:
				anim_time_elapsed += delta
				if (not is_down and anim_time_elapsed >= 2 or is_down and anim_time_elapsed >= ANIMATION_INTERVAL) and mine_time_elapsed < mining_tiles[0].drill_mine_time:
					anim_time_elapsed = 0
					sprite.play("GoUp" if is_down else "GoDown")
					is_down = not is_down
				
				data.mining_progress = mine_time_elapsed / mining_tiles[0].drill_mine_time
				if mine_time_elapsed >= mining_tiles[0].drill_mine_time:
					var valid_output: bool = false
					var output_coords: Vector3i = parent.coords + Vector3i(data.output_direction.x, data.output_direction.y, 0)
					if parent.world.terrain.get_tile(output_coords + Vector3i(0, 0, 1))["id"] == ItemDatabase.Tile.AIR:
						var obj: Dictionary = parent.world.terrain.get_object(output_coords)
						if obj["id"] == ItemDatabase.Obj.NONE:
							valid_output = true
							var data: PickupableObjectData = ItemDatabase.get_object(ItemDatabase.Obj.PICKUPABLE).duplicate()
							data.pickup_stack.item = mining_tiles[0].resource.item.duplicate()
							data.pickup_stack.count = 1
							parent.world.terrain.place_object(output_coords, ItemDatabase.Obj.PICKUPABLE, data, true)
						elif obj["data"] is StorageObjectData:
							for slot: ItemStack in obj["data"].slots:
								if (slot.item and slot.item.name == mining_tiles[0].resource.item.name and slot.count < slot.item.stack_size) or (not slot.item or slot.count <= 0) and slot.is_in_filter(mining_tiles[0].resource.item):
									valid_output = true
									slot.count = max(slot.count, 0) + 1
									if not slot.item:
										slot.item = mining_tiles[0].resource.item.duplicate()
									break
						elif obj["data"] is ConveyorBeltData:
							if not obj["data"].slot:
								obj["data"].slot = mining_tiles[0].resource.item.duplicate()
								valid_output = true
					if valid_output:
						mine_time_elapsed -= mining_tiles[0].drill_mine_time
						var mined: ItemStack = ItemStack.new()
						mined.item = mining_tiles[0].resource.item.duplicate()
						mined.count = 1
						mining_tiles[0].remaining -= 1
						if mining_tiles[0].remaining <= 0:
							mining_tiles.remove_at(0)
						for i in range(len(data.mineable_resources)):
							if data.mineable_resources[i].item and data.mineable_resources[i].item.name == mining_tiles[0].resource.item.name:
								data.mineable_resources[i].count -= 1
								if data.mineable_resources[i].count <= 0:
									data.mineable_resources.remove_at(i)
								data.mineable_resources_changed.emit()
								break
					elif is_down:
						sprite.play("GoUp")
						is_down = false
						anim_time_elapsed = 0
				else:
					fuel_remaining_time -= delta
					mine_time_elapsed += delta


func update_resources(coords: Vector3i, terrain: Terrain) -> void:
	mining_tiles.clear()
	data.mineable_resources.clear()
	
	for z in range(coords.z, terrain.MIN_ELEVATION - 1, -1):
		var tile = terrain.get_tile(Vector3i(coords.x, coords.y, z))
		if tile.has("data") and tile["data"] is MineableResourceTileData:
			mining_tiles.append(tile["data"])
			var target_item: InventoryItemData = tile["data"].resource.item
			var filtered: Array[ItemStack] = data.mineable_resources.filter(func(a: ItemStack) -> bool: return a.item.name == target_item.name)
			if len(filtered) > 0:
				filtered[0].count += tile["data"].remaining
			elif tile["data"].remaining > 0:
				var stack: ItemStack = ItemStack.new()
				stack.item = target_item
				stack.count = tile["data"].remaining
				data.mineable_resources.append(stack)

func update_rotation(new_rot: int) -> void:
	super.update_rotation(new_rot)
	$OutputArrow.rotation = deg_to_rad(new_rot)
	data.output_direction = Vector2i(Vector2(cos(deg_to_rad(new_rot + 90)), sin(deg_to_rad(new_rot + 90))).normalized())
