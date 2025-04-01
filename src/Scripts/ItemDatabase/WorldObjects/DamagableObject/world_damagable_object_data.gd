extends WorldObjectData
class_name WorldDamagableObjectData


@export var scene: PackedScene
func get_scene() -> PackedScene:
	return scene

@export var fist_break_time: float = 0
@export var tools_break_time: Array[ToolWithValue]
@export var max_health: int

signal health_changed

@export_group("")
@export var drop_items: Array[ItemStackRange]
func get_drop_items() -> Array[ItemStackRange]:
	return drop_items

@export var scene_on_death: PackedScene
func get_scene_on_death() -> PackedScene:
	return scene_on_death

@export_group("Runtime Properties")
@export var _health: int
var health: int:
	set(value):
		if value != _health:
			_health = value
			health_changed.emit()
	get:
		return _health
@export var broked: bool = false
