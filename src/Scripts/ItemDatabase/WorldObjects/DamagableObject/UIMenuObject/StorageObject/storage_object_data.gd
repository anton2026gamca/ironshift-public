extends UIMenuObjectData
class_name StorageObjectData


@export var slots_count: int = 0
@export_group("Runtime Properties")
@export var slots: Array[ItemStack] = []


func get_ui_menu() -> InventoryExtension:
	slots.resize(slots_count)
	for i in range(slots_count):
		if not slots[i]:
			slots[i] = ItemStack.new()
	
	var menu: InventoryExtension = super.get_ui_menu()
	if menu:
		menu.data = self
	return menu
