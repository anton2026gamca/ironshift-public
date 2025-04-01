extends Node2D
class_name TerrainLayer


var z: int = 0

var ground: TerrainGround
var objects: Node2D


func _ready() -> void:
	ground = get_node("Ground")
	objects = get_node("Objects")


func get_z() -> int:
	return z
