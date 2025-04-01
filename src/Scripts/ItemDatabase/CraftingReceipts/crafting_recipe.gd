extends Resource
class_name CraftingRecipe

@export var input: Array[ItemStack]
@export var output: ItemStack

@export var craft_time: float = 0.0

enum MadeIn {CRAFTER, FURNACE}
@export var made_in: MadeIn = MadeIn.CRAFTER
