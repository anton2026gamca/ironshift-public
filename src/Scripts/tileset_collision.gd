extends Node2D

@export var tileset: TileSet  # Assign your TileSet
@export var collision_layer: int = 0  # Collision layer index
@export var collision_color: Color = Color.BLACK  # Color to generate collision on
@export var color_tolerance: float = 0.1  # Tolerance for color matching
@export var collision_offset: Vector2 = Vector2(0, 0)  # Offset for collision shape

func _ready():
	if not tileset:
		push_warning("TileSet not assigned!")
		return
	
	for i in range(tileset.get_source_count()):
		var source_id = tileset.get_source_id(i)
		var source = tileset.get_source(source_id)
		if not source is TileSetAtlasSource:
			continue
		
		var grid_size = source.get_atlas_grid_size()
		for y in range(grid_size.y):
			for x in range(grid_size.x):
				var atlas_coords = Vector2i(x, y)
				if source.get_tile_at_coords(atlas_coords) == Vector2i(-1, -1):
					continue
				
				var tile_data = source.get_tile_data(atlas_coords, 0)
				if tile_data:
					generate_collision_for_tile(tile_data, source, atlas_coords)

func generate_collision_for_tile(tile_data: TileData, source: TileSetAtlasSource, atlas_coords: Vector2i):
	var image = source.texture.get_image()
	
	var tile_size = Vector2i(source.texture.get_size()) / source.get_atlas_grid_size()
	var tile_pos = atlas_coords * tile_size
	
	var bounding_box = get_bounding_box(image, tile_pos, tile_size)
	
	if bounding_box:
		for i in range(bounding_box.size()):
			bounding_box[i] += collision_offset
		
		var count = tile_data.get_collision_polygons_count(collision_layer)
		for i in range(count - 1, -1, -1):
			tile_data.remove_collision_polygon(collision_layer, i)
		
		tile_data.set_collision_polygons_count(collision_layer, 1)
		tile_data.set_collision_polygon_points(collision_layer, 0, bounding_box)

func get_bounding_box(image: Image, tile_pos: Vector2i, tile_size: Vector2) -> PackedVector2Array:
	var min_x = tile_size.x
	var min_y = tile_size.y
	var max_x = 0
	var max_y = 0
	var found = false
	
	for y in range(tile_size.y):
		for x in range(tile_size.x):
			var color = image.get_pixel(tile_pos.x + x, tile_pos.y + y)
			if is_color_match(color, collision_color, color_tolerance):
				found = true
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
	
	if not found:
		return PackedVector2Array()  # No matching pixels, return empty array
	
	# Create a rectangle collision shape
	return PackedVector2Array([
		Vector2(min_x - tile_size.x / 2, min_y - tile_size.y / 2),
		Vector2(max_x - tile_size.x / 2 + 1, min_y - tile_size.y / 2),
		Vector2(max_x - tile_size.x / 2 + 1, max_y - tile_size.y / 2 + 1),
		Vector2(min_x - tile_size.x / 2, max_y - tile_size.y / 2 + 1)
	])

func is_color_match(c1: Color, c2: Color, tolerance: float) -> bool:
	return abs(c1.r - c2.r) <= tolerance and \
		   abs(c1.g - c2.g) <= tolerance and \
		   abs(c1.b - c2.b) <= tolerance
