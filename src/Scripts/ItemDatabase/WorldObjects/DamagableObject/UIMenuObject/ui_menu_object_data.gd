extends WorldDamagableObjectData
class_name UIMenuObjectData


@export var on_click_menu: PackedScene
@export var open_in_inventory: bool = true


func get_ui_menu() -> InventoryExtension:
	return on_click_menu.instantiate() if on_click_menu else null
