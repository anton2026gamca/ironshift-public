extends UIWindow
class_name CreateWorldWindow


@onready var seed_line_edit: LineEdit = $WindowContents/VBoxContainer/SeedInput/SeedLineEdit
@export_multiline var world_name_chars: String = "abcdefghijklmnoprstuvwxyz0123456789_-"
@onready var world_name: LineEdit = $WindowContents/VBoxContainer/WorldName/LineEdit
@onready var world_name_emoji_text: EmojiText = $WindowContents/VBoxContainer/WorldName/LineEdit/SubViewportContainer/SubViewport/EmojiText

@export var new_inventory: InventoryData


func _ready() -> void:
	super._ready()
	
	world_name.grab_focus()

func _process(delta: float) -> void:
	super._process(delta)
	
	world_name.caret_column = len(world_name.text)


func open():
	super.open()
	seed_line_edit.text = str(randi())

func _on_seed_line_edit_text_changed(new_text: String) -> void:
	var filtered_text = ""
	
	var c_pos: int = seed_line_edit.caret_column
	for i in range(len(new_text)):
		if new_text[i].is_valid_int():
			filtered_text += new_text[i]
	
	if new_text != filtered_text:
		seed_line_edit.text = filtered_text
	
	await get_tree().create_timer(0.01).timeout
	seed_line_edit.caret_column = c_pos


func _on_world_name_changed(new_text: String) -> void:
	var filtered_text = ""
	
	for i in range(len(new_text)):
		if new_text[i].to_lower() in world_name_chars.to_lower():
			filtered_text += new_text[i]
		elif new_text[i] == ' ':
			filtered_text += '_'
	
	if new_text != filtered_text:
		world_name.text = filtered_text
	
	await get_tree().create_timer(0.01).timeout
	
	world_name_emoji_text.text = world_name.text + "|"

func _on_create_world_pressed() -> void:
	var world: WorldSave = WorldSave.new()
	world.seed = int(seed_line_edit.text)
	world.inventory = new_inventory.duplicate()
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("user://saves/"):
		dir.make_dir_recursive("user://saves/")
	var path: String = "user://saves/" + world_name.text + ".tres"
	ResourceSaver.save(world, path)
	
	await get_tree().process_frame
	
	SceneSwitcher.change_scene(preload("res://Scenes/main.tscn"), {"world_save_path": path})

func _on_world_name_button_pressed() -> void:
	world_name.grab_focus()

func _on_world_name_focus_entered() -> void:
	world_name_emoji_text.text += "|"

func _on_world_name_focus_exited() -> void:
	world_name_emoji_text.text = world_name_emoji_text.text.substr(0, len(world_name_emoji_text.text) - 1)
