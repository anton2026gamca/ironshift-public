extends NinePatchRect
class_name UIWindow


@export var draggable: bool = true

@export var selected_texture: Texture2D
@export var deselected_texture: Texture2D

var initial_mouse_pos: Vector2 = Vector2.ZERO
var initial_window_pos: Vector2 = Vector2.ZERO
var dragging: bool = false
var selected: bool = false

var is_open: bool:
	set(value):
		if value:
			open()
		else:
			close()
	get:
		return visible
signal opened
signal closed

var hovered: bool = false


func _ready() -> void:
	WindowManager.register_window(self)
	if is_open:
		WindowManager.move_to_front(self)
	else:
		WindowManager.move_to_back(self)

func _process(delta: float) -> void:
	if is_open:
		if dragging and draggable and selected:
			position = initial_window_pos + (get_global_mouse_position() - initial_mouse_pos)
			position.x = min(max(position.x, 0), get_viewport().size.x - size.x)
			position.y = min(max(position.y, 0), get_viewport().size.y - size.y)
		
		var mouse: Vector2 = get_global_mouse_position()
		hovered = mouse.x >= position.x and mouse.y >= position.y and mouse.x < position.x + size.x and mouse.y < position.y + size.y

func _exit_tree() -> void:
	WindowManager.unregister_window(self)


func open():
	visible = true
	opened.emit()
	WindowManager.move_to_front(self)

func close():
	visible = false
	closed.emit()
	WindowManager.move_to_back(self)

func select():
	if not is_open:
		return
	selected = true
	texture = selected_texture
	mouse_filter = MOUSE_FILTER_PASS
	set_mouse_filter_children(self, MOUSE_FILTER_PASS)

func deselect():
	selected = false
	texture = deselected_texture
	mouse_filter = MOUSE_FILTER_IGNORE
	set_mouse_filter_children(self, MOUSE_FILTER_IGNORE)

func set_mouse_filter_children(parent: Node, filter: MouseFilter):
	for child in parent.get_children():
		if child is Control:
			child.mouse_filter = filter
		set_mouse_filter_children(child, filter)


func center_position():
	position = (Vector2(get_viewport().size) - size) / 2

func _on_move_handle_pressed() -> void:
	if not is_open:
		return
	initial_mouse_pos = get_global_mouse_position()
	initial_window_pos = position
	dragging = true

func _on_move_handle_released() -> void:
	dragging = false

func _on_close_button_released() -> void:
	if not is_open:
		return
	if selected:
		close()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_open and hovered and (not WindowManager.selected_window or not WindowManager.selected_window.hovered):
				WindowManager.move_to_front(self)
