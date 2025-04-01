extends Area2D
class_name FadingObject


signal fade
signal unfade


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _process(delta: float) -> void:
	pass


func _on_area_entered(area: Area2D) -> void:
	if area.get_parent().get_parent() is Player:
		fade.emit()

func _on_area_exited(area: Area2D) -> void:
	if area.get_parent().get_parent() is Player:
		unfade.emit()
