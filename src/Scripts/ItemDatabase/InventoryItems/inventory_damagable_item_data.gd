extends InventoryItemData
class_name InventoryDamagableItemData


@export var max_health: int
@export_group("Runtime Properties")
@export var health: int:
	set(value):
		health = value

signal destroy

func init() -> void:
	health = max_health

func damage() -> void:
	health -= 1
	if health <= 0:
		destroy.emit()
