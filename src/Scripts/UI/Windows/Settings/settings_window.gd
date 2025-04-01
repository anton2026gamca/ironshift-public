extends UIWindow
class_name SettingsWindow


@onready var ui_scale_slider: UiScaleSlider = $WindowContents/VBoxContainer/UIScaleSlider
@onready var game_scale_slider: UiScaleSlider = $WindowContents/VBoxContainer/GameScaleSlider


func _ready() -> void:
	super._ready()
	
	ui_scale_slider.set_value(SettingsManager.settings.ui_scale)
	game_scale_slider.set_value(SettingsManager.settings.game_scale)

func _process(delta: float) -> void:
	super._process(delta)


func _on_ui_scale_slider_changed(value: int) -> void:
	SettingsManager.set_ui_scale(value)
	SettingsManager.save()

func _on_game_scale_slider_changed(value: int) -> void:
	SettingsManager.set_game_scale(value)
	SettingsManager.save()
