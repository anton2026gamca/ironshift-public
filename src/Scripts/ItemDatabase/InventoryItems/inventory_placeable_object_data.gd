extends InventoryItemData
class_name InventoryPlaceableObjectData


enum Obj {NONE = -1, OAK_TREE = 0, BIRCH_TREE = 1, SPRUCE_TREE = 2, PICKUPABLE = 3, FURNACE = 4, DRILL = 5, WOODEN_CHEST = 6, CONVEYOR_BELT = 7, ROBOTIC_ARM = 8}
@export var object_to_place_id: Obj

@export_group("Runtime Properties")
@export var object_to_place_data: WorldObjectData


func get_data() -> WorldObjectData:
	if object_to_place_data:
		return object_to_place_data.duplicate()
	else:
		var data: WorldObjectData = ItemDatabase.get_object(object_to_place_id).duplicate()
		if data is WorldDamagableObjectData:
			data.health = data.max_health
		return data
