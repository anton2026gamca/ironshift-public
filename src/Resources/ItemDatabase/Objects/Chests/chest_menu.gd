extends InventoryExtension
class_name ChestMenu


@onready var slots_parent: HFlowContainer = $HFlowContainer

const INVENTORY_SLOT: PackedScene = preload("res://Scenes/UI/Inventory/inventory_slot.tscn")


func _ready() -> void:
	var scene = data.get_scene().instantiate()
	if scene is Sprite2D:
		$SubViewportContainer/SubViewport/TextureRect.texture = scene.texture
	scene.queue_free()
	
	data.slots.resize(data.slots_count)
	for i in range(data.slots_count):
		var slot: InventorySlot = INVENTORY_SLOT.instantiate()
		if not data.slots[i]:
			data.slots[i] = ItemStack.new()
		slots_parent.add_child(slot)
		slot.data = data.slots[i]
		slot.update()
		slots.append(slot)

func _process(delta: float) -> void:
	pass
