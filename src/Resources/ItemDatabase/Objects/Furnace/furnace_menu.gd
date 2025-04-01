extends InventoryExtension
class_name FurnaceMenu


@export var input: InventorySlot
@export var output: InventorySlot
@export var fuel: InventorySlot


func _ready() -> void:
	slots = []
	if input:
		input.data = data.input_stack
		slots.append(input)
	if output:
		output.data = data.output_stack
		slots.append(output)
		var item: InventoryItemData = InventoryItemData.new()
		item.name = "FAKsjlahhljnliluaGIAIjsfk"
		output.data.filter.append(item)
	if fuel:
		fuel.data = data.fuel_stack
		slots.append(fuel)
		for item: InventoryItemData in ItemDatabase.data.inventory_items:
			if item is FuelItemData:
				fuel.data.filter.append(item)
	
	var furnace_recipes: Array[CraftingRecipe] = ItemDatabase.data.crafting_recipes.filter(func(r: CraftingRecipe) -> bool: return r.made_in == CraftingRecipe.MadeIn.FURNACE)
	for recipe: CraftingRecipe in furnace_recipes:
		if len(recipe.input) > 0 and recipe.input[0].item:
			input.data.filter.append(recipe.input[0].item)
	
	super._ready()

func _process(delta: float) -> void:
	if data:
		$SmeltingItems/Control/HealthBar.health = data.smelting_progress
		$SmeltingItems/Control/HealthBar.max_health = 1
