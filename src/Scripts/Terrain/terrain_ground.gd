extends TileMapLayer
class_name TerrainGround


var _shader_enabled: bool
@export var shader_enabled: bool:
	set(value):
		_shader_enabled = value
		if material is ShaderMaterial:
			material.set_shader_parameter("enabled", value)
		init()
	get:
		return _shader_enabled

@export var render_position: Vector2i = Vector2i.ZERO
@export var render_tiles_around: Vector2i = Vector2i(16, 16)

#const AIR_COLOR: Color = Color.TRANSPARENT
#const WATER_COLOR: Color = Color.BLUE #Color(79.0 / 255.0, 164.0 / 255.0, 184.0 / 255.0)
#const GRASS_COLOR: Color = Color.RED #Color(65.0 / 255.0, 166.0 / 255.0, 35.0 / 255.0)
#const STONE_COLOR: Color = Color.WHITE #Color(105.0 / 255.0, 105.0 / 255.0, 105.0 / 255.0)

var time_passed: float = 0.0
@export var update_interval: float = 10 

var image: Image

@export var terrain: Terrain
@export var layer: TerrainLayer


#var TILE_TO_COLOR: Dictionary = {
#	ItemDatabase.Tile.AIR: AIR_COLOR,
#	ItemDatabase.Tile.GRASS: GRASS_COLOR,
#	ItemDatabase.Tile.WATER: WATER_COLOR,
#	ItemDatabase.Tile.STONE: STONE_COLOR
#}

var initialized: bool = false


func _ready() -> void:
	terrain.start.connect(init)

func _process(delta: float) -> void:
	if not initialized:
		return
	
	time_passed += delta
	if time_passed >= update_interval:
		time_passed -= update_interval
		update_shader(terrain.player.position)


@warning_ignore("shadowed_global_identifier")
func init() -> void:
	if material is ShaderMaterial:
		var tilesets: Array[Image] = []
		var other_tiles: Array[Color] = []
		for tile in ItemDatabase.data.world_tiles:
			if tile != ItemDatabase.get_tile(ItemDatabase.Tile.AIR) and tile != ItemDatabase.get_tile(ItemDatabase.Tile.WATER):
				tilesets.append(tile.tileset_texture.get_image())
				other_tiles.append(tile.unique_color)
		other_tiles.resize(10)
		var tex_array: Texture2DArray = Texture2DArray.new()
		tex_array.create_from_images(tilesets)
		material.set_shader_parameter("tilesets", tex_array)
		material.set_shader_parameter("tileset_size", Vector2(7, 7))
		material.set_shader_parameter("tile_size", Vector2(16, 16))
		
		material.set_shader_parameter("TILE_AIR", ItemDatabase.get_tile(ItemDatabase.Tile.AIR).unique_color)
		material.set_shader_parameter("TILE_WATER", ItemDatabase.get_tile(ItemDatabase.Tile.WATER).unique_color)
		material.set_shader_parameter("tileset_tile", other_tiles)
		
		material.set_shader_parameter("tilemap_position", global_position)
		material.set_shader_parameter("render_tile_offset", -Vector2(render_tiles_around))
		material.set_shader_parameter("render_tile_distance", Vector2(render_tiles_around))
		material.set_shader_parameter("world_scale", global_scale)
		
		var min: Vector2i = -render_tiles_around
		var max: Vector2i = render_tiles_around
		
		var img_size: Vector2i = Vector2i(max.x - min.x + 1, max.x - min.y + 1)
		image = Image.create(img_size.x, img_size.y, false, Image.FORMAT_RGBA8)
		image.fill(ItemDatabase.get_tile(ItemDatabase.Tile.AIR).unique_color)
		
		for y: int in range(img_size.y):
			for x: int in range(img_size.x):
				var tile_x: int = x + min.x
				var tile_y: int = y + min.y
				
				var tile_id: int = get_tile_id(Vector2i(tile_x, tile_y))
				image.set_pixel(x, y, ItemDatabase.get_tile(tile_id).unique_color)
		
		var texture: ImageTexture = ImageTexture.create_from_image(image)
		material.set_shader_parameter("tiles", texture)
		
		initialized = true

@warning_ignore("shadowed_global_identifier")
func set_tile(coords: Vector2i, tile: ItemDatabase.Tile = ItemDatabase.Tile.AIR) -> void:
	if initialized:
		var min: Vector2i = render_position - render_tiles_around
		if coords.x - min.x < image.get_width() and coords.x - min.x >= 0 and coords.y - min.y < image.get_height() and coords.y - min.y >= 0:
			image.set_pixel(coords.x - min.x, coords.y - min.y, ItemDatabase.get_tile(tile).unique_color)
	
	var alt_tile: int = 0
	if tile != ItemDatabase.Tile.AIR and tile != ItemDatabase.Tile.WATER:
		if get_tile_id(Vector2i(coords.x, coords.y + 1)) == ItemDatabase.Tile.AIR or get_tile_id(Vector2i(coords.x, coords.y + 1)) == ItemDatabase.Tile.WATER:
			alt_tile = 1
		if get_tile_id(Vector2i(coords.x, coords.y - 1)) == ItemDatabase.Tile.AIR or get_tile_id(Vector2i(coords.x, coords.y - 1)) == ItemDatabase.Tile.WATER:
			alt_tile += 2
	
	set_cell(coords, tile, Vector2i(3, 3), alt_tile)

func update_shader(player_position: Vector2) -> void:
	if not image:
		return
	
	var size: Vector2 = get_viewport().size / terrain.TILE_SIZE / 2
	size = Vector2(max(ceil(size.x), ceil(size.y)), max(ceil(size.x), ceil(size.y))) + Vector2(6, 6)
	if size.x != render_tiles_around.x or size.y != render_tiles_around.y:
		set_render_distance(size)
	
	var new_r_p: Vector2i = Vector2i(player_position / terrain.TILE_SIZE)
	if new_r_p != render_position:
		set_render_position(new_r_p)
	
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	material.set_shader_parameter("tiles", texture)

func set_render_position(pos: Vector2i) -> void:
	render_position = pos
	material.set_shader_parameter("render_tile_offset", Vector2(render_position) - Vector2(render_tiles_around))
	
	var size: Vector2i = Vector2i(image.get_width(), image.get_height())
	var new_image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	new_image.fill(ItemDatabase.get_tile(ItemDatabase.Tile.AIR).unique_color)
	for x: int in range(0, size.x):
		for y: int in range(0, size.y):
			new_image.set_pixel(x, y, ItemDatabase.get_tile(get_tile_id(render_position - render_tiles_around + Vector2i(x, y))).unique_color)
	image = new_image

func set_render_distance(dis: Vector2i) -> void:
	render_tiles_around = Vector2i(max(dis.x, dis.y), max(dis.x, dis.y))
	material.set_shader_parameter("render_tile_distance", Vector2(render_tiles_around))
	material.set_shader_parameter("render_tile_offset", Vector2(render_position) - Vector2(render_tiles_around))
	
	var size: Vector2i = Vector2i(render_tiles_around.x * 2 + 1, render_tiles_around.y * 2 + 1)
	var new_image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	new_image.fill(ItemDatabase.get_tile(ItemDatabase.Tile.AIR).unique_color)
	for x: int in range(0, size.x):
		for y: int in range(0, size.y):
			new_image.set_pixel(x, y, ItemDatabase.get_tile(get_tile_id(render_position - render_tiles_around + Vector2i(x, y))).unique_color)
	image = new_image

func get_tile_id(coords: Vector2i) -> int:
	if not layer or not terrain:
		layer = get_parent()
		if layer:
			terrain = layer.get_parent()
		
	if not layer or not terrain:
		return get_cell_source_id(coords)
	else:
		var tile: Dictionary = terrain.get_tile(Vector3i(coords.x, coords.y, layer.get_z()))
		return tile["id"]
