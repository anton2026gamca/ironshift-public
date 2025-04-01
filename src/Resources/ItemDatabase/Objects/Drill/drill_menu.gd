extends InventoryExtension
class_name DrillMenu


@onready var mineable_resources_parent: VBoxContainer = $MineableResources
@onready var row_template: Control = $MineableResources/RowTemplate

@onready var fuel_slot: InventorySlot = $Mining/Fuel
@onready var mining_progress: HealthBar = $Mining/Progress
@onready var mining_resource: TextureRect = $Mining/Resource


func _ready() -> void:
	if not data:
		return
	
	fuel_slot.data = data.fuel_stack
	for item: InventoryItemData in ItemDatabase.data.inventory_items:
		if item is FuelItemData:
			fuel_slot.data.filter.append(item)
	slots.append(fuel_slot)
	
	update_resources()
	data.mineable_resources_changed.connect(update_resources)

func _process(delta: float) -> void:
	if not data:
		return
	
	mining_progress.health = data.mining_progress
	mining_progress.max_health = 1
	if data.mining_resource:
		mining_resource.texture = data.mining_resource.texture
	else:
		mining_resource.texture = null


func update_resources() -> void:
	for child: Node in mineable_resources_parent.get_children():
		if child != row_template:
			mineable_resources_parent.remove_child(child)
			child.queue_free()
	for resource: ItemStack in data.mineable_resources:
		var row: Control = row_template.duplicate()
		row.visible = true
		row.get_node("Resource").texture = resource.item.texture
		row.get_node("Count").text = str(resource.count)
		mineable_resources_parent.add_child(row)
