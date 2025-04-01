extends Node


@export var data: ItemDatabaseData

enum Item {STICKS = 0, WOOD = 1, STONE = 2, AXE = 3, PICKAXE = 4, SHOVEL = 5, DIRT = 6, GRASS_TILE = 7, STONE_TILE = 8, RAW_IRON = 9, FURNACE = 10, IRON_INGOT = 11, DRILL = 12, WOODEN_CHEST = 13, CONVEYOR_BELT = 14, COAL = 15, GEAR_WHEEL = 16}
enum Tile {AIR = 0, GRASS = 1, WATER = 2, STONE = 3, IRON_ORE = 4, COAL_ORE = 5}
enum Obj {NONE = -1, OAK_TREE = 0, BIRCH_TREE = 1, SPRUCE_TREE = 2, PICKUPABLE = 3, FURNACE = 4, DRILL = 5, WOODEN_CHEST = 6, CONVEYOR_BELT = 7, ROBOTIC_ARM = 8}


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass


func get_item_by_name(name: String) -> InventoryItemData:
	var results = data.inventory_items.filter(func(item: InventoryItemData): return item.name == name)
	if results.size() > 0:
		return results[0]
	return null

func get_item(id: int) -> InventoryItemData:
	if len(data.inventory_items) > id:
		return data.inventory_items[id]
	return null

func get_object_by_name(name: String) -> WorldObjectData:
	var results = data.world_objects.filter(func(item: WorldObjectData): return item.name == name)
	if results.size() > 0:
		return results[0]
	return null

func get_object(id: int) -> WorldObjectData:
	if len(data.world_objects) > id:
		return data.world_objects[id]
	return null

func get_tile_by_name(name: String) -> WorldTileData:
	var results = data.world_tiles.filter(func(item: WorldTileData): return item.name == name)
	if results.size() > 0:
		return results[0]
	return null

func get_tile(id: int) -> WorldTileData:
	if len(data.world_tiles) > id:
		return data.world_tiles[id]
	return null
