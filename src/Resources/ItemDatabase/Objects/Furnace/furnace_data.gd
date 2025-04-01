extends StorageObjectData
class_name FurnaceData


var input_stack: ItemStack:
	set(value):
		slots.resize(3)
		slots[0] = value
	get:
		slots.resize(3)
		return slots[0]
var output_stack: ItemStack:
	set(value):
		slots.resize(3)
		slots[1] = value
	get:
		slots.resize(3)
		return slots[1]
var fuel_stack: ItemStack:
	set(value):
		slots.resize(3)
		slots[2] = value
	get:
		slots.resize(3)
		return slots[2]
var smelting_progress: float = 0


func get_ui_menu() -> InventoryExtension:
	slots_count = 3
	return super.get_ui_menu()
