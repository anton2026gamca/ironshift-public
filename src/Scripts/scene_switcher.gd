extends Node


var _params: Dictionary = {}

func change_scene(scene: PackedScene, params: Dictionary = {}) -> void:
	await get_tree().process_frame
	_params = params
	get_tree().change_scene_to_packed(scene)

func get_param(key):
	if _params.has(key):
		return _params[key]
	return null
