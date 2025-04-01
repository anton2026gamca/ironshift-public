extends WorldDamagableObjectData
class_name WorldTreeData


@export_group("With leaves")
@export var grow_state_atlas_coords_l: Array[PackedScene] = []
@export_group("Without leaves")
@export var grow_state_atlas_coords_n: Array[PackedScene] = []

@export_group("")
@export var drop_items_overrides: Array[DropItemsOverride] = []
func get_drop_items() -> Array[ItemStackRange]:
	for override: DropItemsOverride in drop_items_overrides:
		if override.grow_state == grow_state and (override.has_leaves == has_leaves or override.ignore_leaves):
			return override.drop_items
	return drop_items

@export var death_scene_overrides: Array[DeathSceneOverride]
func get_scene_on_death() -> PackedScene:
	for override: DeathSceneOverride in death_scene_overrides:
		if override.grow_state == grow_state and (override.has_leaves == has_leaves or override.ignore_leaves):
			return override.scene
	return scene_on_death

func get_scene() -> PackedScene:
	if broked:
		return get_scene_on_death()
	if has_leaves and len(grow_state_atlas_coords_l) > grow_state:
		return grow_state_atlas_coords_l[grow_state]
	elif len(grow_state_atlas_coords_n) > grow_state:
		return grow_state_atlas_coords_n[grow_state]
	return null

@export_group("Runtime Properties")
@export var has_leaves: bool = true
@export var grow_state: int = 0
