extends WorldDamagableTileData
class_name MineableResourceTileData


@export var resource: ItemStackRange
@export var drill_mine_time: float

@export_group("Runtime Properties")
@export var remaining: int = 0


func init() -> void:
	remaining = resource.get_count()
