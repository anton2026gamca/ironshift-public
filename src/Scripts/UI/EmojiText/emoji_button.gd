@tool
extends Button
class_name EmojiButton


@onready var emoji_text: EmojiText = $SubViewportContainer/SubViewport/EmojiText
var last_text: String = ""


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if text != last_text:
		last_text = text
		emoji_text.text = text
		emoji_text.update()
		emoji_text.alignment = alignment as int
