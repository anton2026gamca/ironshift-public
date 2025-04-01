extends WorldObjectInstance
class_name ConveyorBelt


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var item: Sprite2D = $Item
var slot_before: InventoryItemData = null


func _ready() -> void:
	super._ready()
	
	if sprite:
		sprite.material = material
		sprite.visible = true
		texture = null

func _process(delta: float) -> void:
	if parent:
		if sprite.frame + 1 == MasterConveyor.frame and (data.slot or data.moving_slot):
			var next_belt: Dictionary = parent.world.terrain.get_object(coords + Vector3i(data.direction.x, data.direction.y, 0))
			if next_belt["id"] == ItemDatabase.Obj.CONVEYOR_BELT:
				if data.slot and not data.moving_slot:
					item.position.y = 0
					item.texture = data.slot.texture
					if not next_belt["data"].slot:
						item.position.y -= 1
						data.moving_slot = data.slot
						data.slot = null
				elif item.position.y > -16 and data.moving_slot and not next_belt["data"].slot:
					item.position.y -= 1
				elif data.moving_slot and not next_belt["data"].slot:
					next_belt["data"].slot = data.moving_slot
					data.moving_slot = null
					item.texture = null
					item.position.y = 0
				data.moving_slot_pos = item.position.y
			else:
				item.position.y = 0
				if data.slot:
					item.texture = data.slot.texture
		elif not data.slot and not data.moving_slot:
			item.texture = null
			item.position.y = 0
	else:
		sprite.animation = "forward"
		sprite.flip_h = false
	
	sprite.frame = MasterConveyor.frame


func update_rotation(new_rot: int) -> void:
	new_rot %= 360
	super.update_rotation(new_rot)
	rotation = deg_to_rad(new_rot)
	item.rotation = -rotation
	data.direction = Vector2i(Vector2(cos(deg_to_rad(new_rot - 90)), sin(deg_to_rad(new_rot - 90))).normalized())

func update_state() -> void:
	if not parent:
		sprite.animation = "forward"
		sprite.flip_h = false
		return
	
	if parent.world.terrain.get_object(coords - Vector3i(data.direction.x, data.direction.y, 0))["id"] != ItemDatabase.Obj.CONVEYOR_BELT:
		var left_vec: Vector2i = Vector2i(-data.direction.y, data.direction.x)
		var right_vec: Vector2i = Vector2i(data.direction.y, -data.direction.x)
		var left_obj: Dictionary = parent.world.terrain.get_object(coords - Vector3i(left_vec.x, left_vec.y, 0))
		var right_obj: Dictionary = parent.world.terrain.get_object(coords - Vector3i(right_vec.x, right_vec.y, 0))
		var left: bool = false
		var right: bool = false
		if left_obj["id"] == ItemDatabase.Obj.CONVEYOR_BELT and left_obj["data"].direction == left_vec:
			left = true
		if right_obj["id"] == ItemDatabase.Obj.CONVEYOR_BELT and right_obj["data"].direction == right_vec:
			right = true
		
		if left and not right:
			sprite.animation = "side"
			sprite.flip_h = false
		elif right and not left:
			sprite.animation = "side"
			sprite.flip_h = true
		else:
			sprite.animation = "forward"
	elif sprite.animation != "forward":
		sprite.animation = "forward"
