extends Node2D
class_name WorldObject


var data: WorldObjectData
var coords: Vector3i
var instance: Node2D
@onready var health_bar: HealthBar = $HealthBar
var world: WorldManager


func _ready() -> void:
	if data is WorldDamagableObjectData:
		data.health_changed.connect(health_changed)
	health_bar.visible = false

func _process(delta: float) -> void:
	if data is WorldDamagableObjectData and data.health <= 0 and not data.broked:
		for drop_item: ItemStackRange in data.get_drop_items():
			var stack := ItemStack.new()
			stack.count = drop_item.get_count()
			stack.item = drop_item.item
			world.inventory.pickup(stack)
		if data.get_scene_on_death():
			var new_instance = data.scene_on_death.instantiate()
			if instance:
				new_instance.position.y = instance.position.y
				new_instance.material = instance.material
				remove_child(instance)
				instance.queue_free()
			var fading_object: FadingObject = new_instance.get_node_or_null("FadingObject")
			if fading_object:
				fading_object.fade.connect(fade)
				fading_object.unfade.connect(unfade)
			add_child(new_instance)
			instance = new_instance
			data.broked = true
		else:
			get_parent().remove_child(self)
			queue_free()


func spawn(y_offset: float = 0) -> void:
	var scene: PackedScene = data.get_scene()
	if not scene:
		return
	
	instance = scene.instantiate()
	instance.position.y = y_offset
	health_bar.position.y += y_offset
	if instance.material:
		instance.material = instance.material.duplicate()
		
		var fading_object: FadingObject = instance.get_node_or_null("FadingObject")
		if fading_object:
			fading_object.fade.connect(fade)
			fading_object.unfade.connect(unfade)
	add_child(instance)
	
	if data is PickupableObjectData and instance is Sprite2D:
		instance.texture = data.pickup_stack.item.texture

func update_state() -> void:
	if instance is WorldObjectInstance:
		instance.update_state()

func delete() -> void:
	if data is StorageObjectData:
		for slot: ItemStack in data.slots:
			if not slot:
				continue
			var remaining: int = world.inventory.pickup(slot)
			slot.count = remaining
			if remaining > 0:
				return
	if data is WorldDamagableObjectData and not data.broked:
		var picked_up_drop_items: Array[ItemStack]
		var revert: bool = false
		for drop_item: ItemStackRange in data.get_drop_items():
			var stack: ItemStack = ItemStack.new()
			stack.item = drop_item.item.duplicate()
			stack.count = drop_item.get_count()
			var remaining: int = world.inventory.pickup(stack)
			if remaining > 0:
				stack.count -= remaining
				picked_up_drop_items.append(stack)
				revert = true
				break
			else:
				picked_up_drop_items.append(stack)
		if revert:
			for stack: ItemStack in picked_up_drop_items:
				for slot: ItemStack in world.inventory.data.slots:
					if slot.item.name == stack.item.name:
						slot.count -= stack.count
						stack.count = -slot.count
						if stack.count <= 0:
							break
			return
	get_parent().remove_child(self)
	queue_free()


func fade() -> void:
	set_transparency(0.25)

func unfade() -> void:
	set_transparency(1)


func set_transparency(alpha: float):
	instance.material.set_shader_parameter("transparency", alpha)

func set_outline_enabled(enabled: bool):
	if enabled:
		instance.material.set_shader_parameter("outline_width", 1)
		health_bar.visible = data is WorldDamagableObjectData and not data.broked and data.health != data.max_health
	else:
		instance.material.set_shader_parameter("outline_width", 0)
		health_bar.visible = false

func set_outline_color(color: Color):
	instance.material.set_shader_parameter("outline_color", color)

func health_changed():
	if data is WorldDamagableObjectData:
		health_bar.max_health = data.max_health
		health_bar.health = data.health
