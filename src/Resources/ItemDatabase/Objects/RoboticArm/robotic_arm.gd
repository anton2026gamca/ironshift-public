extends WorldObjectInstance
class_name RoboticArm


var anim_name: String
var anim_from_end: bool

var state: int = 0
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	super._ready()
	
	data.slots.resize(1)
	if not data.slots[0]:
		data.slots[0] = ItemStack.new()
	else:
		data.slots[0] = data.slots[0].duplicate()
	
	$Arm/Sprite2D.material = material
	$Body.material = material

func _process(delta: float) -> void:
	if parent:
		$OutputArrow.visible = material.get_shader_parameter("outline_width") != 0
		
		if data.slots[0] and data.slots[0].item:
			$Arm/Sprite2D/Item.texture = data.slots[0].item.texture
		else:
			$Arm/Sprite2D/Item.texture = null
		
		if state == 0 and not animation_player.is_playing():
			if take_input():
				animation_player.play(anim_name, -1, data.speed * (int(not anim_from_end) * 2 - 1), anim_from_end)
				state = 1
		elif state == 1 and not animation_player.is_playing():
			if drop():
				animation_player.play(anim_name, -1, data.speed * (int(anim_from_end) * 2 - 1), not anim_from_end)
				state = 0


func take_input() -> bool:
	var input_coords: Vector3i = parent.coords - Vector3i(data.direction.x, data.direction.y, 0)
	if parent.world.terrain.get_tile(input_coords + Vector3i(0, 0, 1))["id"] == ItemDatabase.Tile.AIR:
		var obj: Dictionary = parent.world.terrain.get_object(input_coords)
		if obj["id"] == ItemDatabase.Obj.PICKUPABLE and obj.has("data") and obj["data"] is PickupableObjectData:
			data.slots[0].item = obj["data"].pickup_stack.item.duplicate()
			data.slots[0].count += obj["data"].pickup_stack.count
			parent.world.terrain.remove_object(input_coords)
			return true
		if obj.has("data") and obj["data"] is StorageObjectData:
			for slot: ItemStack in obj["data"].slots:
				if slot.item and slot.count > 0:
					data.slots[0].item = slot.item.duplicate()
					data.slots[0].count += 1
					slot.count -= 1
					if slot.count <= 0:
						slot.item = null
					return true
		elif obj.has("data") and obj["data"] is ConveyorBeltData:
			if obj["data"].slot:
				data.slots[0].item = obj["data"].slot.duplicate()
				data.slots[0].count += 1
				obj["data"].slot = null
				return true
			elif obj["data"].moving_slot and obj["data"].moving_slot_pos > -4:
				data.slots[0].item = obj["data"].moving_slot.duplicate()
				data.slots[0].count += 1
				obj["data"].moving_slot = null
				return true
	return false

func drop() -> bool:
	var output_coords: Vector3i = parent.coords + Vector3i(data.direction.x, data.direction.y, 0)
	if parent.world.terrain.get_tile(output_coords + Vector3i(0, 0, 1))["id"] == ItemDatabase.Tile.AIR:
		var obj: Dictionary = parent.world.terrain.get_object(output_coords)
		if obj["id"] == ItemDatabase.Obj.NONE:
			var obj_data: PickupableObjectData = ItemDatabase.get_object(ItemDatabase.Obj.PICKUPABLE).duplicate()
			obj_data.pickup_stack.item = data.slots[0].item.duplicate()
			obj_data.pickup_stack.count = 1
			data.slots[0].count -= 1
			if data.slots[0].count <= 0:
				data.slots[0].item = null
			parent.world.terrain.place_object(output_coords, ItemDatabase.Obj.PICKUPABLE, obj_data, true)
			return true
		elif obj.has("data") and obj["data"] is StorageObjectData:
			for slot: ItemStack in obj["data"].slots:
				if (slot and slot.item and slot.item.name == data.slots[0].item.name and slot.count < slot.item.stack_size) or (not slot.item or slot.count <= 0) and slot.is_in_filter(data.slots[0].item):
					slot.count = max(slot.count, 0) + 1
					if not slot.item:
						slot.item = data.slots[0].item.duplicate()
					data.slots[0].count -= 1
					if data.slots[0].count <= 0:
						data.slots[0].item = null
					return true
		elif obj.has("data") and obj["data"] is ConveyorBeltData:
			if not obj["data"].slot:
				obj["data"].slot = data.slots[0].item.duplicate()
				data.slots[0].count -= 1
				if data.slots[0].count <= 0:
					data.slots[0].item = null
				return true
	return false

func update_rotation(new_rot: int) -> void:
	new_rot %= 360
	if new_rot < 0:
		new_rot += 360
	super.update_rotation(new_rot)
	data.direction = Vector2i(Vector2(cos(deg_to_rad(new_rot + 90)), sin(deg_to_rad(new_rot + 90))).normalized())
	if data.direction == Vector2i.LEFT:
		anim_name = "MoveLeft"
		anim_from_end = false
	if data.direction == Vector2i.RIGHT:
		anim_name = "MoveLeft"
		anim_from_end = true
	if data.direction == Vector2i.DOWN:
		anim_name = "MoveDown"
		anim_from_end = false
	if data.direction == Vector2i.UP:
		anim_name = "MoveDown"
		anim_from_end = true
	$AnimationPlayer.play(anim_name, -1, 10000 * (int(anim_from_end) * 2 - 1), not anim_from_end)
	#$AnimationPlayer.stop(true)
	$OutputArrow.rotation = deg_to_rad(new_rot)
