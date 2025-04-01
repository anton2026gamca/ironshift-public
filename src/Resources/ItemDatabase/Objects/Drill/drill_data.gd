extends StorageObjectData
class_name DrillData



@export_group("Runtime Properties")
@export var output_direction: Vector2i = Vector2i.DOWN
@export var mineable_resources: Array[ItemStack]
signal mineable_resources_changed
var fuel_stack: ItemStack:
	set(value):
		slots.resize(1)
		slots[0] = value
	get:
		slots.resize(1)
		return slots[0]

var mining_resource: InventoryItemData
var mining_progress: float


func get_ui_menu() -> InventoryExtension:
	slots_count = 1
	return super.get_ui_menu()
