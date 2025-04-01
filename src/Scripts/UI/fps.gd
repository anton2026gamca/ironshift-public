extends RichTextLabel
class_name Fps


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	text = "FPS: " + str(Engine.get_frames_per_second())
