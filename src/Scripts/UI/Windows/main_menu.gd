extends Control
class_name MainMenu


@onready var animation_player: AnimationPlayer = $LoadingScreen/Logo/AnimationPlayer
@onready var pick_world_window: UIWindow = $ScaledUI/SubViewport/MainMenuWindows/PickWorldWindow
@onready var create_world_window: UIWindow = $ScaledUI/SubViewport/MainMenuWindows/CreateWorldWindow
@onready var settings_window: UIWindow = $ScaledUI/SubViewport/MainMenuWindows/SettingsWindow
@onready var main_menu: UIWindow = $ScaledUI/SubViewport/MainMenuWindows/MainMenu


func _ready() -> void:
	var no_start_anim = SceneSwitcher.get_param("disable_start_anim")
	if no_start_anim == null or no_start_anim == false:
		$ScaledUI.visible = false
		animation_player.play("start")
	main_menu.center_position()
	main_menu.open()
	create_world_window.close()
	create_world_window.center_position()
	pick_world_window.close()
	pick_world_window.center_position()
	settings_window.close()
	settings_window.center_position()

func _process(delta: float) -> void:
	pass


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "start":
		await get_tree().create_timer(0.5).timeout
		$ScaledUI.visible = true

func _on_play_pressed() -> void:
	pick_world_window.center_position()
	pick_world_window.open()

func _on_options_pressed() -> void:
	settings_window.center_position()
	settings_window.open()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_main_menu_closed() -> void:
	await  get_tree().create_timer(0.1).timeout
	main_menu.center_position()
	main_menu.open()
