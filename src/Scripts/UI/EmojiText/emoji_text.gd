@tool
extends HFlowContainer
class_name EmojiText


@export var update_text: bool = false:
	set(value):
		update()
@export_multiline var text: String = "":
	set(value):
		text = value
		update()
	get:
		return text

@export var rules: Array[CharToTexture] = []
@export var no_match: Texture2D

var emojis: Array[Node] = []


func _ready() -> void:
	update()

func _process(delta: float) -> void:
	pass


func update() -> void:
	for emoji in emojis:
		remove_child(emoji)
		emoji.queue_free()
	emojis.clear()
	
	for char in text:
		var filtered: Array = rules.filter(matches.bind(char))
		var rule = filtered[0] if len(filtered) > 0 else null
		
		var texture_rect: TextureRect = TextureRect.new()
		texture_rect.texture = rule.texture if rule is CharToTexture else no_match
		add_child(texture_rect)
		emojis.append(texture_rect)

func matches(rule: CharToTexture, text_char: String) -> bool:
	if len(text_char) > 0:
		text_char = text_char[0]
		for char in rule.char:
			if text_char == char:
				return true
	return false
