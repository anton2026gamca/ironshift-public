extends SubViewportContainer
class_name WorldManager


@export var terrain: Terrain
@export var player: Player
@export var inventory: Inventory
@export var settings_window: SettingsWindow
@export var pause_menu: PauseMenu
@export var loading_screen: Control


func _ready() -> void:
	pause_menu.quit.connect(quit_world)
	pause_menu.save.connect(terrain.save_world.bind(terrain.world_save_path))
	
	stretch_shrink = SettingsManager.settings.game_scale

func _process(delta: float) -> void:
	pass


func quit_world() -> void:
	await get_tree().process_frame
	SceneSwitcher.change_scene(load("res://Scenes/UI/MainMenu/main_menu.tscn"), {"disable_start_anim": true})
