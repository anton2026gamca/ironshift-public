extends Control
class_name InventoryExtension


@export var data: UIMenuObjectData

@export var slots: Array[InventorySlot]


func _ready() -> void:
	for slot: InventorySlot in slots:
		if not slot.data:
			slot.data = ItemStack.new()

func _process(delta: float) -> void:
	pass
