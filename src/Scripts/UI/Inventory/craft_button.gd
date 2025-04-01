@tool
extends Button
class_name CraftButton


@export var update_button: bool:
	set(value):
		if count_text and texture_rect and inventory.data:
			if recipe:
				update()
			else:
				texture_rect.texture = null
				count_text.text = ""
	get:
		return false

@export var recipe: CraftingRecipe
@onready var inventory: Inventory = $"../../../../../../../.."

@onready var texture_rect: TextureRect = $Item/TextureRect
@onready var count_text: Label = $Item/CountText


func _ready() -> void:
	update()
	
	if not Engine.is_editor_hint():
		inventory.opened.connect(update)
		inventory.queued_crafing.connect(update)

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		pass


func update():
	texture_rect.texture = recipe.output.item.texture
	var can_craft: int = 1000000
	for input in recipe.input:
		var count: int = 0
		for slot in inventory.data.slots + inventory.data.hotbar:
			if not slot.item or slot.item.name != input.item.name:
				continue
			count += slot.count
		can_craft = min(count / input.count, can_craft)
	if can_craft == 1000000:
		can_craft = 0
	count_text.text = str(can_craft)
	disabled = can_craft <= 0

func _on_pressed() -> void:
	update()
	if not disabled:
		inventory.craft_item(recipe)
	update()
