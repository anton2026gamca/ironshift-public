extends WorldDamagableObjectData
class_name ConveyorBeltData


@export_group("Runtime Properties")
@export var slot: InventoryItemData
@export var moving_slot: InventoryItemData
@export var moving_slot_pos: int
@export var direction: Vector2i = Vector2i.DOWN
