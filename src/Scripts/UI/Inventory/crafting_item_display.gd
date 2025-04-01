extends Control
class_name CraftingItemDisplay


@export var recipe: CraftingRecipe

@onready var texture_rect: TextureRect = $TextureRect
@onready var progress: ColorRect = $Progress

var started: bool = false
var time_elapsed: float
var finished: bool = false


func _ready() -> void:
	progress.scale.y = 0

func _process(delta: float) -> void:
	if recipe:
		texture_rect.texture = recipe.output.item.texture
		if started:
			time_elapsed += delta
			
			if recipe.craft_time == 0:
				progress.scale.y = 1
				finish()
			else:
				progress.scale.y = clamp(time_elapsed / recipe.craft_time, 0, 1)
				if time_elapsed / recipe.craft_time >= 1:
					finish()


func start() -> void:
	started = true

func finish() -> void:
	finished = true
