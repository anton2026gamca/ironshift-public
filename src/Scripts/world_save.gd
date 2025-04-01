extends Resource
class_name WorldSave


@export var seed: int
@export var chunks: Dictionary = {}

@export var player_position: Vector2 = Vector2.ZERO
@export var player_z: int = 0
@export var inventory: InventoryData
