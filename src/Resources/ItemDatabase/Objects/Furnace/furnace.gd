extends WorldObjectInstance
class_name Furnace


@export var fuel_remaining_time: float = 0


func _ready() -> void:
	super._ready()
	
	if parent:
		if not data.input_stack: data.input_stack = ItemStack.new()
		if not data.output_stack: data.output_stack = ItemStack.new()
		if not data.fuel_stack: data.fuel_stack = ItemStack.new()

func _process(delta: float) -> void:
	if parent:
		if data.input_stack.item and data.input_stack.count > 0:
			var recipe: CraftingRecipe = null
			for r: CraftingRecipe in ItemDatabase.data.crafting_recipes:
				if r.made_in != CraftingRecipe.MadeIn.FURNACE:
					continue
				if len(r.input) > 0 and r.input[0].item and data.input_stack.item.name == r.input[0].item.name and data.input_stack.count >= r.input[0].count:
					recipe = r
					break
			if recipe:
				if data.smelting_progress >= 1:
					if (not data.output_stack.item or data.output_stack.item.name == recipe.output.item.name) and data.output_stack.count + recipe.output.count <= recipe.output.item.stack_size:
						data.input_stack.count -= recipe.input[0].count
						data.output_stack.item = recipe.output.item
						data.output_stack.count += recipe.output.count
						data.smelting_progress = 0
					else:
						data.smelting_progress = 1
				elif (data.fuel_stack.item is FuelItemData and data.fuel_stack.count > 0) or fuel_remaining_time > 0:
					fuel_remaining_time -= delta
					data.smelting_progress += delta / recipe.craft_time
					if fuel_remaining_time <= 0 and data.fuel_stack.count > 0:
						data.fuel_stack.count -= 1
						fuel_remaining_time += data.fuel_stack.item.duration
						if data.fuel_stack.count <= 0:
							data.fuel_stack.item = null
			else:
				data.smelting_progress = 0
