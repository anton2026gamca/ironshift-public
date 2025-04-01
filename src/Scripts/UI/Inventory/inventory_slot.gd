extends Panel
class_name InventorySlot


@export var data: ItemStack

@onready var texture_rect: TextureRect = $Item/TextureRect
@onready var count_text: Label = $Item/CountText
@onready var health_bar: HealthBar = $Item/HealthBar


func _ready() -> void:
	update()

func _process(_delta: float) -> void:
	pass


func update() -> void:
	if texture_rect:
		if data and data.item and data.count > 0:
			texture_rect.texture = data.item.texture
		else:
			texture_rect.texture = null
	
	if count_text:
		if data and data.item and data.count > 0:
			count_text.text = str(data.count)
		else:
			count_text.text = ""
	
	if data and data.item is InventoryDamagableItemData and health_bar:
		health_bar.visible = true
		health_bar.max_health = data.item.max_health
		health_bar.health = data.item.health
		health_bar.update()
	elif health_bar:
		health_bar.visible = false
