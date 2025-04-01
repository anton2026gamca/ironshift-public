extends WorldObjectData
class_name PickupableObjectData

@export var scene: PackedScene
@export var pickup_stack: ItemStack

func get_scene() -> PackedScene:
	return scene
