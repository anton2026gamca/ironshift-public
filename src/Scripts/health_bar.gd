@tool
extends Control
class_name HealthBar


@export var update_button: bool:
	set(value):
		update()

@export var max_health: float = 0
var _health: float
@export var health: float = 0:
	set(value):
		_health = value
		update()
	get:
		return _health
@export var fill_color: Color = Color(0, 0, 153.0 / 255.0, 1)

@onready var progress: ColorRect = $Progress


func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass


func update() -> void:
	if max_health != 0:
		progress.scale.x = health / max_health
	else:
		progress.scale.x = 1
	progress.self_modulate = fill_color
