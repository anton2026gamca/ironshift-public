extends Resource
class_name InventoryData


@export var size: Vector2i
@export var slots: Array[ItemStack]
@export var hotbar: Array[ItemStack]

@export_group("Runtime Properties")
@export var holding_slot: ItemStack
