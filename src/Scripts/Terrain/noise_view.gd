@tool
extends Sprite2D
class_name NoiseView


@export var update: bool:
	set(value):
		update_shader()

@export var shader_enabled: bool:
	set(value):
		shader_enabled = value
		update_shader()
	get:
		return shader_enabled

@export var noise: FastNoiseLite

@export_range(0, 1) var border_value: float = 0.5:
	set(value):
		border_value = value
		update_shader()
@export_range(10, 1000) var width: int = 128:
	set(value):
		width = value
		update_shader()
@export_range(10, 1000) var height: int = 128:
	set(value):
		height = value
		update_shader()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func update_shader() -> void:
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	for x in width:
		for y in height:
			image.set_pixel(x, y, Color((noise.get_noise_2d(x, y) + 1) / 2, (noise.get_noise_2d(x, y) + 1) / 2, (noise.get_noise_2d(x, y) + 1) / 2, 1))
	
	texture = ImageTexture.create_from_image(image)
	if material is ShaderMaterial:
		material.set_shader_parameter("value", border_value)
		material.set_shader_parameter("enabled", shader_enabled)
