@tool
extends TabBar
class_name InventoryTabBar


@onready var panels: Array[Panel] = [$"../Tab 1", $"../Tab 2", $"../Tab 3", $"../Tab 4"]
var opened_tab: int = 0


func _ready() -> void:
	for panel in panels:
		panel.visible = false
	panels[current_tab].visible = true

func _process(delta: float) -> void:
	if opened_tab != current_tab:
		for panel in panels:
			panel.visible = false
		panels[current_tab].visible = true
		opened_tab = current_tab
