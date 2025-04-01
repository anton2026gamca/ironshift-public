extends HBoxContainer
class_name UiScaleSlider


@onready var slider: HSlider = $Slider
var slider_dragging: bool = false
@onready var spin_box: SpinBox = $SpinBox

@export var min_value: int
@export var max_value: int

signal changed(value: int)


func _ready() -> void:
	slider.min_value = min_value
	slider.max_value = max_value
	spin_box.min_value = min_value
	spin_box.max_value = max_value

func _process(delta: float) -> void:
	if slider_dragging:
		spin_box.value = slider.value


func set_value(value: int) -> void:
	value = clamp(value, min_value, max_value)
	slider.value = value
	spin_box.value = value
	changed.emit(value)

func _on_spin_box_value_changed(value: float) -> void:
	slider.value = value
	changed.emit(spin_box.value)

func _on_slider_drag_started() -> void:
	slider_dragging = true

func _on_slider_drag_ended(value_changed: bool) -> void:
	slider_dragging = false
	changed.emit(slider.value)
