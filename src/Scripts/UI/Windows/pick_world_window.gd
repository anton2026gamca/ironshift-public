extends UIWindow
class_name PickWorldWindow


@export var create_world_window: CreateWorldWindow
@onready var template_world_display: Control = $WindowContents/VBoxContainer/ScrollContainer/WorldsList/WorldDisplay
@onready var load_world_buttons_parent: VBoxContainer = $WindowContents/VBoxContainer/ScrollContainer/WorldsList

const LOADING_SCREEN = preload("res://Scenes/loading_screen.tscn")


func _ready() -> void:
	super._ready()
	refresh_list()

func _process(delta: float) -> void:
	super._process(delta)


func refresh_list() -> void:
	for child in load_world_buttons_parent.get_children():
		if child == template_world_display:
			continue
		load_world_buttons_parent.remove_child(child)
		child.queue_free()
	
	var usr: DirAccess = DirAccess.open("user://")
	if usr and usr.dir_exists("user://saves/"):
		var saves: DirAccess = DirAccess.open("user://saves")
		saves.list_dir_begin()
		
		var file: String = saves.get_next()
		while file != "":
			if file.ends_with(".tres"):
				var world_name = file.substr(0, len(file) - 5)
				var world_display: Control = template_world_display.duplicate()
				world_display.visible = true
				var load_button: Button = world_display.get_node("LoadButton")
				load_button.text = world_name
				load_button.pressed.connect(_on_load_world_button_pressed.bind("user://saves/" + file))
				var delete_button: Button = world_display.get_node("DeleteButton")
				delete_button.pressed.connect(_on_delete_world_button_pressed.bind("user://saves/" + file))
				load_world_buttons_parent.add_child(world_display)
			file = saves.get_next()
		saves.list_dir_end()

func _on_refresh_list_pressed() -> void:
	refresh_list()

func _on_create_world_pressed() -> void:
	if create_world_window:
		create_world_window.open()

func _on_load_world_button_pressed(world_path: String):
	if FileAccess.file_exists(world_path):
		await get_tree().process_frame
		SceneSwitcher.change_scene(preload("res://Scenes/main.tscn"), {"world_save_path": world_path})
	else:
		refresh_list()

func _on_delete_world_button_pressed(world_path: String):
	if FileAccess.file_exists(world_path):
		DirAccess.remove_absolute(world_path)
	refresh_list()
