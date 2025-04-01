extends UIWindow
class_name PauseMenu


var paused: bool:
	set(value):
		is_open = value
	get:
		return is_open

signal save
signal quit

@export var world_manager: WorldManager
@onready var settings_window: SettingsWindow = world_manager.settings_window


func _ready() -> void:
	super._ready()
	close()

func _process(delta: float) -> void:
	super._process(delta)
	if Input.is_action_just_pressed("pause_and_resume"):
		paused = !paused


func _on_resume_pressed() -> void:
	close()

func _on_options_pressed() -> void:
	settings_window.center_position()
	settings_window.open()

func _on_stop_pressed() -> void:
	quit.emit()

func _on_close_button_button_up() -> void:
	_on_resume_pressed()

func _on_save_pressed() -> void:
	save.emit()
