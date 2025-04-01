extends Resource
class_name ItemStack


@export var item: InventoryItemData:
	set(value):
		item = value
		if item is InventoryDamagableItemData and not item.destroy.is_connected(reset):
			item.destroy.connect(reset)
	get:
		return item
@export var count: int
@export var filter: Array[InventoryItemData]


func _init() -> void:
	if item is InventoryDamagableItemData:
		item.destroy.connect(reset)

func reset() -> void:
	item = null
	count = 0

func is_in_filter(item: InventoryItemData) -> bool:
	return len(filter) <= 0 or len(filter.filter(func(a: InventoryItemData) -> bool: return a.name == item.name))
	
