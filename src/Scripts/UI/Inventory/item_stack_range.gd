extends Resource
class_name ItemStackRange


@export var item: InventoryItemData
@export var min_count: int
@export var max_count: int


func get_count() -> int:
	return randi_range(min_count, max_count)
