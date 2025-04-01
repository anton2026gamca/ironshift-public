extends InventoryDamagableItemData
class_name ToolData

var durability: int:
	set(value):
		health = value
	get:
		return health
@export var attack_cooldown: float
@export_group("Runtime Properties")
@export var cooldown_timer: float

func damage():
	super.damage()
	cooldown_timer = attack_cooldown
