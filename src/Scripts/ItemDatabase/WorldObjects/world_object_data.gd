extends Resource
class_name WorldObjectData


@export var name: String = ""
@export var grid_size: Vector2i = Vector2i(1, 1)
@export var can_rotate: bool = false

@export_group("Runtime Properties")
@export var rotation: int = 0


func get_scene() -> PackedScene:
	return null
