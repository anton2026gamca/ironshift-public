@tool
extends TileMapLayer
class_name NewTerrainTest


var _shader_enabled: bool = true
@export var shader_enabled: bool:
	set(value):
		_shader_enabled = value
		if material is ShaderMaterial:
			material.set_shader_parameter("enabled", value)
		update()
	get:
		return _shader_enabled

const GRASS_TILESET: Texture2D = preload("res://Sprites/tiles/grass_v2.png")
const STONE_TILESET: Texture2D = preload("res://Sprites/tiles/stone_v2.png")
var tilesets: Array[Image] = [GRASS_TILESET.get_image(), STONE_TILESET.get_image()]

@export var render_position: Vector2i = Vector2i.ZERO
@export var render_tiles_around: Vector2 = Vector2(16, 16)

const AIR_COLOR: Color = Color(0, 0, 0, 0)
const GRASS_COLOR: Color = Color(65.0 / 255.0, 166.0 / 255.0, 35.0 / 255.0)
const WATER_COLOR: Color = Color(79.0 / 255.0, 164.0 / 255.0, 184.0 / 255.0)
const STONE_COLOR: Color = Color(105.0 / 255.0, 105.0 / 255.0, 105.0 / 255.0)

var time_passed: float = 0.0
@export var update_interval: float = 10 


func _ready() -> void:
	update()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		time_passed += delta
		if time_passed >= update_interval:
			time_passed -= update_interval
			update()


func update():
	if material is ShaderMaterial and shader_enabled:
		var tex_array: Texture2DArray = Texture2DArray.new()
		tex_array.create_from_images(tilesets)
		material.set_shader_parameter("tilesets", tex_array)
		material.set_shader_parameter("tileset_size", Vector2(7, 7))
		material.set_shader_parameter("tile_size", Vector2(16, 16))
		
		var other_tiles: Array[Color] = []
		other_tiles.resize(10)
		for i in range(10):
			other_tiles[i] = Color(0, 0, 0, 0)
		other_tiles[0] = GRASS_COLOR
		other_tiles[1] = STONE_COLOR
		material.set_shader_parameter("tileset_tile", other_tiles)
		material.set_shader_parameter("TILE_AIR", AIR_COLOR)
		material.set_shader_parameter("TILE_WATER", WATER_COLOR)
		
		material.set_shader_parameter("tilemap_position", global_position)
		material.set_shader_parameter("render_tile_offset", Vector2(render_position) - render_tiles_around)
		material.set_shader_parameter("render_tile_distance", render_tiles_around)
		material.set_shader_parameter("world_scale", global_scale)
		
		var min_x: int = -render_tiles_around.x + render_position.x
		var max_x: int = render_tiles_around.x + render_position.x
		var min_y: int = -render_tiles_around.y + render_position.y
		var max_y: int = render_tiles_around.y + render_position.y
		
		var tex_size: Vector2i = Vector2i(max_x - min_x, max_y - min_y)
		var image: Image = Image.create(tex_size.x, tex_size.y, false, Image.FORMAT_RGBA8)
		image.fill(AIR_COLOR)
		
		for y in range(tex_size.x):
			for x in range(tex_size.y):
				var tile_x = x + min_x
				var tile_y = y + min_y
				
				var source_id := get_cell_source_id(Vector2i(tile_x, tile_y))
				if source_id == 0:
					image.set_pixel(x, y, WATER_COLOR)
				if source_id == 1:
					image.set_pixel(x, y, GRASS_COLOR)
				if source_id == 2:
					image.set_pixel(x, y, STONE_COLOR)
				
				if source_id > 0:
					var alt_tile: int = 0
					if get_cell_source_id(Vector2i(tile_x, tile_y + 1)) <= 0:
						alt_tile = 1
					if get_cell_source_id(Vector2i(tile_x, tile_y - 1)) <= 0:
						alt_tile += 2
					set_cell(Vector2i(tile_x, tile_y), source_id, get_cell_atlas_coords(Vector2i(tile_x, tile_y)), alt_tile)
		
		var texture := ImageTexture.create_from_image(image)
		
		material.set_shader_parameter("tiles", texture)
