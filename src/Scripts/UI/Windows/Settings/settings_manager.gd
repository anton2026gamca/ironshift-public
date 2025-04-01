extends Node


const SETTINGS_PATH: String = "user://settings.tres"
var settings: Settings


func _ready() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		settings = ResourceLoader.load(SETTINGS_PATH)
	else:
		settings = Settings.new()
		ResourceSaver.save(settings, SETTINGS_PATH)

func _process(delta: float) -> void:
	pass


func set_ui_scale(scale: int) -> void:
	if settings:
		var nodes: Array = get_tree().get_nodes_in_group("ui_sub_viewport_container")
		for node in nodes:
			if node is SubViewportContainer:
				node.stretch_shrink = scale
		scale = clamp(scale, 1, 3)
		settings.ui_scale = scale
	else:
		push_error("Settings is null!")

func set_game_scale(scale: int) -> void:
	if settings:
		var nodes: Array = get_tree().get_nodes_in_group("game_sub_viewport_container")
		for node in nodes:
			if node is SubViewportContainer:
				node.stretch_shrink = scale
		scale = clamp(scale, 3, 7)
		settings.game_scale = scale
	else:
		push_error("Settings is null!")

func save() -> void:
	if settings:
		ResourceSaver.save(settings, SETTINGS_PATH)
