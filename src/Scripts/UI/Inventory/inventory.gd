extends Control
class_name Inventory


@export var data: InventoryData

@onready var window: UIWindow = $InventoryWindow
@onready var inventory_slots: GridContainer = $InventoryWindow/WindowContents/Left/Slots
var slot_template: PackedScene = preload("res://Scenes/UI/Inventory/inventory_slot.tscn")
@onready var crafting_menu: Control = $InventoryWindow/WindowContents/Right/CraftingMenu

@onready var hotbar: Panel = $Hotbar
@onready var hotbar_slots: HBoxContainer = $Hotbar/Slots

@onready var mining_progress: HealthBar = $Hotbar/MiningProgress

var is_open: bool = false

var hovered_slot: InventorySlot
@onready var dragging_slot: InventorySlot = $DraggingSlot
var drag_state: int = 0
var divide_to_stacks: Array[ItemStack] = []
var divide_original_counts: Array[int] = [] # Original counts of ItemStacks
var divide_original_count: int = 0 # Original count of dragging_slot
var last_right_clicked_item_slot: InventorySlot

var initial_mouse_pos: Vector2 = Vector2.ZERO
var initial_slot_pos: Vector2 = Vector2.ZERO

var mouse_left_before := false
var mouse_right_before := false

var hotbar_selected_slot_id: int = 0
@onready var hotbar_selected_slot: NinePatchRect = $Hotbar/SelectedSlot

@onready var extension_parent: Control = $InventoryWindow/WindowContents/Right/Extension
var extension: InventoryExtension

signal opened
signal closed

@onready var crafting_items_parent: HFlowContainer = $CraftingItems
const CRAFTING_ITEM_DISPLAY = preload("res://Scenes/UI/Inventory/crafting_item_display.tscn")

signal queued_crafing


func _ready() -> void:
	if window.is_open != visible:
		if visible:
			open()
		else:
			close()
	visible = true
	
	init()

func _process(delta: float) -> void:
	is_open = window.is_open
	if Input.is_action_just_pressed("toggle_inventory"):
		if window.is_open:
			close()
		else:
			open()
	
	update_slots()
	if dragging_slot.data:
		var slot_item: Control = dragging_slot.get_node_or_null("Item")
		if slot_item:
			slot_item.position = initial_slot_pos + (get_global_mouse_position() - initial_mouse_pos)
	
	if drag_state > 0:
		dragging_slot.visible = true
		data.holding_slot = dragging_slot.data
	else:
		dragging_slot.visible = false
		data.holding_slot = data.hotbar[hotbar_selected_slot_id]
	
	update_crafting_items()
	
	mouse_left_before = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	mouse_right_before = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)


func init() -> void:
	if not data:
		return
	
	for child in inventory_slots.get_children():
		inventory_slots.remove_child(child)
		child.queue_free()
	
	inventory_slots.columns = data.size.x
	data.slots.resize(data.size.x * data.size.y)
	for y in range(data.size.y):
		for x in range(data.size.x):
			var i = y * data.size.x + x
			if not data.slots[i]:
				data.slots[i] = ItemStack.new()
			elif data.slots[i].item:
				data.slots[i].item = data.slots[i].item.duplicate()
			
			var slot: InventorySlot = slot_template.instantiate()
			slot.name = get_slot_name(x, y)
			slot.data = data.slots[i]
			inventory_slots.add_child(slot)
			slot.mouse_entered.connect(slot_mouse_entered.bind(slot))
			slot.mouse_exited.connect(slot_mouse_exited.bind(slot))
	
	data.hotbar.resize(9)
	
	for i in range(9):
		if not data.hotbar[i]:
			data.hotbar[i] = ItemStack.new()
		elif data.hotbar[i].item:
			data.hotbar[i].item = data.hotbar[i].item.duplicate()
		
		var slot: InventorySlot = hotbar_slots.get_node_or_null("HotbarSlot" + str(i + 1))
		if not slot:
			push_warning("Couldn't find HotbarSlot", i + 1, " node!")
			continue
		slot.data = data.hotbar[i]
		if slot.mouse_entered.is_connected(slot_mouse_entered):
			slot.mouse_entered.disconnect(slot_mouse_entered)
		if slot.mouse_exited.is_connected(slot_mouse_exited):
			slot.mouse_exited.disconnect(slot_mouse_exited)
		slot.mouse_entered.connect(slot_mouse_entered.bind(slot))
		slot.mouse_exited.connect(slot_mouse_exited.bind(slot))
	
	update_slots()
	
	change_hotbar_selected_slot(0)
	data.holding_slot = data.hotbar[hotbar_selected_slot_id]

func update_slots():
	if not data:
		return
	
	var slots: Array[InventorySlot] = []
	
	for y in range(data.size.y):
		for x in range(data.size.x):
			var i = y * data.size.x + x
			slots.append(inventory_slots.get_node_or_null(get_slot_name(x, y)))
	
	for i in range(9):
		slots.append(hotbar_slots.get_node_or_null("HotbarSlot" + str(i + 1)))
	
	if dragging_slot.data:
		slots.append(dragging_slot)
	
	if extension:
		for slot: InventorySlot in extension.slots:
			slots.append(slot)
	
	for slot in slots:
		slot.data = slot.data
		slot.update()
	
	if Input.is_action_pressed("inventory_fast_insert") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and hovered_slot and hovered_slot.data and hovered_slot.data.item:
		var move_to: Array[InventorySlot] = []
		if extension:
			if data.slots.has(hovered_slot.data):
				move_to = extension.slots
			elif data.hotbar.has(hovered_slot.data):
				move_to = extension.slots
			elif extension.slots.has(hovered_slot):
				for child: Node in inventory_slots.get_children():
					if child is InventorySlot:
						move_to.append(child)
		else:
			if data.slots.has(hovered_slot.data):
				for child: Node in hotbar_slots.get_children():
					if child is InventorySlot:
						move_to.append(child)
			elif data.hotbar.has(hovered_slot.data):
				for child: Node in inventory_slots.get_children():
					if child is InventorySlot:
						move_to.append(child)
		
		for slot: InventorySlot in move_to:
			if (not slot.data.item or slot.data.count <= 0) or slot.data.item.name == hovered_slot.data.item.name:
				if slot.data.is_in_filter(hovered_slot.data.item):
					var move_items: int = min(hovered_slot.data.item.stack_size - slot.data.count, hovered_slot.data.count)
					slot.data.item = hovered_slot.data.item
					slot.data.count += move_items
					hovered_slot.data.count -= move_items
			if hovered_slot.data.count <= 0:
				hovered_slot.data.item = null
				break
	elif hovered_slot and hovered_slot.data and hovered_slot.data.item:
		if hovered_slot.data.count > 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not mouse_left_before and not is_dragging():
			dragging_slot.data = hovered_slot.data.duplicate()
			hovered_slot.data.item = null
			hovered_slot.data.count = 0
			drag_state = 1
			divide_original_count = dragging_slot.data.count
			var slot_item: Control = dragging_slot.get_node("Item")
			initial_mouse_pos = slot_item.global_position + slot_item.size / 2
			initial_slot_pos = slot_item.position
		if hovered_slot.data.count > 1 and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not mouse_right_before and not is_dragging():
			var half: int = floor(hovered_slot.data.count / 2) + 1
			dragging_slot.data = ItemStack.new()
			dragging_slot.data.item = hovered_slot.data.item
			dragging_slot.data.count += half
			hovered_slot.data.count -= half
			drag_state = 1
			divide_original_count = dragging_slot.data.count
			var slot_item: Control = dragging_slot.get_node("Item")
			initial_mouse_pos = slot_item.global_position + slot_item.size / 2
			initial_slot_pos = slot_item.position
	
	if dragging_slot.data:
		var pressed: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if drag_state == 1 and not pressed:
			drag_state = 2
		elif drag_state == 2 and pressed:
			drag_state = 3
		elif drag_state == 3 and not pressed:
			if dragging_slot.data.count > 0:
				drag_state = 2
				divide_original_count = dragging_slot.data.count
				divide_to_stacks = []
				divide_original_counts = []
			else:
				drag_state = 4
		
		var slot_item: Control = dragging_slot.get_node_or_null("Item")
		if slot_item:
			if drag_state == 2:
				if hovered_slot and dragging_slot.data.item and (not hovered_slot.data.item or hovered_slot.data.item.name == dragging_slot.data.item.name or hovered_slot.data.count <= 0):
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and (last_right_clicked_item_slot != hovered_slot or not mouse_right_before) and dragging_slot.data.count > 0 and hovered_slot.data.count < dragging_slot.data.item.stack_size and hovered_slot.data.is_in_filter(dragging_slot.data.item):
						if not hovered_slot.data.item or hovered_slot.data.count <= 0:
							hovered_slot.data.item = dragging_slot.data.item
						hovered_slot.data.count += 1
						dragging_slot.data.count -= 1
						if dragging_slot.data.count <= 0:
							dragging_slot.data.item = null
							drag_state = 4
						last_right_clicked_item_slot = hovered_slot
				divide_original_count = dragging_slot.data.count
			elif drag_state == 3:
				if hovered_slot:
					if dragging_slot.data.item and (not hovered_slot.data.item or hovered_slot.data.item.name == dragging_slot.data.item.name or hovered_slot.data.count <= 0):
						if not divide_to_stacks.has(hovered_slot.data) and hovered_slot.data.is_in_filter(dragging_slot.data.item):
							var stacks_count = len(divide_to_stacks)
							for i in range(stacks_count):
								divide_to_stacks[i].count = divide_original_counts[i]
							dragging_slot.data.count = divide_original_count
							divide_to_stacks.append(hovered_slot.data)
							divide_original_counts.append(hovered_slot.data.count)
							stacks_count += 1
							
							var amt: int = floor(divide_original_count / stacks_count)
							if amt <= 0:
								amt = 1
							for stack in divide_to_stacks:
								if not stack.item or stack.count <= 0:
									stack.item = dragging_slot.data.item
								stack.count += amt
								dragging_slot.data.count -= amt
								if stack.count > stack.item.stack_size:
									var remove: int = stack.count - stack.item.stack_size
									stack.count -= remove
									dragging_slot.data.count += remove
									
									if remove == amt and stacks_count == 1:
										var buffer: ItemStack = hovered_slot.data.duplicate()
										hovered_slot.data.item = dragging_slot.data.item
										hovered_slot.data.count = dragging_slot.data.count
										dragging_slot.data.item = buffer.item
										dragging_slot.data.count = buffer.count
								if dragging_slot.data.count < 0:
									stack.count -= -dragging_slot.data.count
									dragging_slot.data.count = 0
					elif not mouse_left_before:
						var buffer: ItemStack = hovered_slot.data.duplicate()
						hovered_slot.data.item = dragging_slot.data.item
						hovered_slot.data.count = dragging_slot.data.count
						dragging_slot.data.item = buffer.item
						dragging_slot.data.count = buffer.count
			elif drag_state == 4:
				slot_item.position = initial_slot_pos
				if dragging_slot.data.count <= 0:
					dragging_slot.data.item = null
				dragging_slot.data = null
				drag_state = 0
				divide_original_count = 0
				divide_to_stacks = []
				divide_original_counts = []
			if drag_state != 0:
				slot_item.position = initial_slot_pos + (get_global_mouse_position() - initial_mouse_pos)

func get_slot_name(x: int, y: int) -> String:
	return "Slot (" + str(x) + ", " + str(y) + ")"

func get_slot_name_i(i: int) -> String:
	var x: int = i % data.size.x
	var y: int = i / data.size.x
	return get_slot_name(x, y)

func is_dragging() -> bool:
	return dragging_slot.data != null

func _on_window_opened() -> void:
	opened.emit()

func _on_window_closed() -> void:
	window.center_position()
	closed.emit()

func slot_mouse_entered(slot: InventorySlot):
	hovered_slot = slot

func open() -> void:
	window.open()
	crafting_menu.visible = true
	extension_parent.visible = false

func close() -> void:
	window.close()
	
	for child: Node in extension_parent.get_children():
		extension_parent.remove_child(child)
		child.queue_free()
		extension = null

func open_with_extension_packed(ext: PackedScene) -> void:
	var scene: Node = ext.instantiate()
	if not scene is InventoryExtension:
		return
	
	open_with_extension_node(scene)

func open_with_extension_node(scene: InventoryExtension) -> void:
	if not scene:
		return
	
	open()
	
	for child: Node in extension_parent.get_children():
		extension_parent.remove_child(child)
		child.queue_free()
	
	crafting_menu.visible = false
	extension_parent.visible = true
	extension_parent.add_child(scene)
	extension = scene
	for slot: InventorySlot in extension.slots:
		if not slot.mouse_entered.is_connected(slot_mouse_entered):
			slot.mouse_entered.connect(slot_mouse_entered.bind(slot))
		if not slot.mouse_exited.is_connected(slot_mouse_exited):
			slot.mouse_exited.connect(slot_mouse_exited.bind(slot))

func slot_mouse_exited(slot: InventorySlot):
	if hovered_slot == slot:
		hovered_slot = null

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_hotbar_selected_slot(hotbar_selected_slot_id - event.factor)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_hotbar_selected_slot(hotbar_selected_slot_id + event.factor)

func change_hotbar_selected_slot(slot: int):
	slot %= 9
	if slot < 0: slot += 9
	var changed: bool = hotbar_selected_slot_id != slot
	hotbar_selected_slot_id = slot
	if changed:
		hotbar_selected_slot.position.x = -3 + slot * 44

func pickup(stack: ItemStack) -> int:
	if not stack or not stack.item or stack.count <= 0:
		return 0
	var add = stack.count
	for i in range(data.size.x * data.size.y):
		if add <= 0:
			break
		if data.slots[i].item and data.slots[i].item.name == stack.item.name:
			data.slots[i].count += add
			add = 0
			if data.slots[i].count > data.slots[i].item.stack_size:
				var remove = data.slots[i].count - data.slots[i].item.stack_size
				data.slots[i].count -= remove
				add += remove
	for i in range(data.size.x * data.size.y):
		if add <= 0:
			break
		if not data.slots[i].item or data.slots[i].count <= 0:
			data.slots[i].item = stack.item
			data.slots[i].count += add
			add = 0
			if data.slots[i].count > data.slots[i].item.stack_size:
				var remove = data.slots[i].count - data.slots[i].item.stack_size
				data.slots[i].count -= remove
				add += remove
	return add

func craft_item(recipe: CraftingRecipe):
	for input in recipe.input:
		var count: int = input.count
		for slot in data.slots + data.hotbar:
			if count == 0:
				break
			if not slot.item or slot.item.name != input.item.name:
				continue
			var remove: int = min(count, slot.count)
			count -= remove
			slot.count -= remove
	var item: CraftingItemDisplay = CRAFTING_ITEM_DISPLAY.instantiate()
	item.recipe = recipe.duplicate(true)
	crafting_items_parent.add_child(item)
	queued_crafing.emit()

func update_crafting_items():
	if crafting_items_parent.get_child_count() > 0:
		var item: CraftingItemDisplay = crafting_items_parent.get_child(0)
		if not item.started:
			item.start()
		if item.finished:
			item.recipe.output = item.recipe.output.duplicate(true)
			item.recipe.output.item.init()
			pickup(item.recipe.output)
			crafting_items_parent.remove_child(item)
			item.queue_free()
