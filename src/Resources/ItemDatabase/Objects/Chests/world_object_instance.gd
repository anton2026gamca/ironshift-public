extends Sprite2D
class_name WorldObjectInstance


var data: WorldObjectData
var parent: WorldObject
var coords: Vector3i


func _ready() -> void:
	var p: Node = get_parent()
	if p is WorldObject:
		parent = p
		data = parent.data
		coords = parent.coords
		update_rotation(data.rotation)
		update_state()
	else:
		sprite_only()

func _process(delta: float) -> void:
	pass


func update_rotation(new_rot: int) -> void:
	new_rot %= 360
	data.rotation = new_rot

func sprite_only() -> void:
	for child: Node in get_children():
		if child is Area2D or child is StaticBody2D or child is CollisionShape2D or child is CollisionPolygon2D:
			remove_child(child)
			child.queue_free()

func update_state() -> void:
	pass
