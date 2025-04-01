extends Node


enum Elevation { LOW, MID, HIGH }

'''
# Atlas coordinates for each biome
const BIOME_TILES = {
	Biome.OCEAN: Vector2i(0, 0),
	Biome.OAK_FOREST: Vector2i(1, 0),
	Biome.SPRUCE_FOREST: Vector2i(5, 0),
	Biome.MEADOW: Vector2i(2, 0),
	Biome.MOUNTAINS: Vector2i(3, 0),
}
'''

const BIOME_ELEVATION = {
	Terrain.Biome.OCEAN: Elevation.LOW,
	Terrain.Biome.OAK_FOREST: Elevation.MID,
	Terrain.Biome.SPRUCE_FOREST: Elevation.MID,
	Terrain.Biome.MEADOW: Elevation.MID,
	Terrain.Biome.MOUNTAINS: Elevation.HIGH
}

var num_biomes = {
	Elevation.LOW: 0,
	Elevation.MID: 0,
	Elevation.HIGH: 0
}

var elevation_noise_1: FastNoiseLite = FastNoiseLite.new()
var elevation_noise_2: FastNoiseLite = FastNoiseLite.new()
var elevation_noise_3: FastNoiseLite = FastNoiseLite.new()
var biome_noise: FastNoiseLite = FastNoiseLite.new()
var mountains_noise: FastNoiseLite = FastNoiseLite.new()
var tree_noise: FastNoiseLite = FastNoiseLite.new()
@export var ores_noise: FastNoiseLite = FastNoiseLite.new()

const MID_ELEVATION_START: float = 0.0
const HIGH_ELEVATION_START: float = 0.2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func init() -> void:
	elevation_noise_1.noise_type = FastNoiseLite.TYPE_SIMPLEX
	elevation_noise_1.frequency = 0.003
	elevation_noise_1.fractal_type = FastNoiseLite.FRACTAL_FBM
	elevation_noise_1.fractal_octaves = 6
	elevation_noise_1.fractal_lacunarity = 2
	elevation_noise_1.fractal_gain = 0.5
	elevation_noise_1.fractal_weighted_strength = 1
	
	elevation_noise_2.noise_type = FastNoiseLite.TYPE_SIMPLEX
	elevation_noise_2.frequency = 0.015
	
	elevation_noise_3.noise_type = FastNoiseLite.TYPE_SIMPLEX
	elevation_noise_3.frequency = 0.030
	
	biome_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	biome_noise.frequency = 0.031
	biome_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	biome_noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN_SQUARED
	biome_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	biome_noise.cellular_jitter = 1
	biome_noise.domain_warp_enabled = true
	biome_noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX
	biome_noise.domain_warp_amplitude = 27.5
	biome_noise.domain_warp_frequency = 0.031
	biome_noise.domain_warp_fractal_type = FastNoiseLite.DomainWarpFractalType.DOMAIN_WARP_FRACTAL_INDEPENDENT
	biome_noise.domain_warp_fractal_octaves = 3
	biome_noise.domain_warp_fractal_lacunarity = 2
	biome_noise.domain_warp_fractal_gain = 0.5
	
	mountains_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	mountains_noise.frequency = 0.010
	mountains_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	mountains_noise.fractal_octaves = 3
	
	tree_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	tree_noise.frequency = 1.000
	
	ores_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ores_noise.frequency = 0.04

	for i in Terrain.Biome.size():
		num_biomes[BIOME_ELEVATION[i as Terrain.Biome]] += 1

func load_chunk(seed: int, chunk_size: int, chunk_pos: Vector2, min_z: int, max_z: int) -> TerrainChunk:
	var chunk: TerrainChunk = TerrainChunk.new()
	chunk.size = Vector2i(chunk_size, chunk_size)
	
	for z: int in range(min_z, max_z + 1):
		chunk.tiles[z] = []
		chunk.tiles[z].resize(chunk_size)
		chunk.objects[z] = []
		chunk.objects[z].resize(chunk_size)
		for x: int in range(chunk_size):
			chunk.tiles[z][x] = []
			chunk.tiles[z][x].resize(chunk_size)
			chunk.objects[z][x] = []
			chunk.objects[z][x].resize(chunk_size)
	
	var highest_point := 0
	
	for y in range(chunk_size):
		for x in range(chunk_size):
			var world_x = int(chunk_pos.x * chunk_size + x)
			var world_y = int(chunk_pos.y * chunk_size + y)
			
			var elevation: Elevation
			var elevation_val = get_elevation(seed, world_x, world_y)
			
			if elevation_val <= MID_ELEVATION_START:
				elevation = Elevation.LOW
			elif elevation_val < HIGH_ELEVATION_START:
				elevation = Elevation.MID
			else:
				elevation = Elevation.HIGH
				
			var biome = get_biome(seed, elevation, world_x, world_y)
			var z_level = get_z_level(elevation_val, min_z, max_z)
			
			tree_noise.seed = seed + 1109
			var tree_val = tree_noise.get_noise_2d(world_x, world_y)
			var spawn_tree: bool = tree_val > 0.4
			
			ores_noise.seed = seed + 115
			var iron_ore_value: float = (ores_noise.get_noise_2d(world_x, world_y) + 1) / 2
			
			ores_noise.seed = seed + 1743
			var coal_ore_value: float = (ores_noise.get_noise_2d(world_x, world_y) + 1) / 2
			
			for z in range(min_z, max_z + 1):
				var tile_id: ItemDatabase.Tile = ItemDatabase.Tile.AIR
				
				if z <= z_level:
					if biome == Terrain.Biome.MOUNTAINS:
						tile_id = ItemDatabase.Tile.STONE
					else:
						if z <= z_level - 4:
							tile_id = ItemDatabase.Tile.STONE
						else:
							tile_id = ItemDatabase.Tile.GRASS
				elif z <= 0 and biome == Terrain.Biome.OCEAN:
					tile_id = ItemDatabase.Tile.WATER
				
				if tile_id == ItemDatabase.Tile.STONE and iron_ore_value >= 0.85 + (1 - float(z - min_z) / float(z_level - min_z)) * 0.15:
					tile_id = ItemDatabase.Tile.IRON_ORE
				elif tile_id != ItemDatabase.Tile.WATER and tile_id != ItemDatabase.Tile.AIR and tile_id != ItemDatabase.Tile.STONE and iron_ore_value >= 0.90 + (pow(0.5 - max((z_level - z) / 4.0, 0), 3)) * 0.20:
					tile_id = ItemDatabase.Tile.IRON_ORE
				elif tile_id == ItemDatabase.Tile.STONE and coal_ore_value >= 0.85 + (1 - float(z - min_z) / float(z_level - min_z)) * 0.15:
					tile_id = ItemDatabase.Tile.COAL_ORE
				elif tile_id != ItemDatabase.Tile.WATER and tile_id != ItemDatabase.Tile.AIR and tile_id != ItemDatabase.Tile.STONE and coal_ore_value >= 0.90 + (pow(0.5 - max((z_level - z) / 4.0, 0), 3)) * 0.20:
					tile_id = ItemDatabase.Tile.COAL_ORE
				
				var tile_data: WorldTileData = ItemDatabase.get_tile(tile_id).duplicate()
				tile_data.init()
				
				chunk.tiles[z][y][x] = {
					"id": tile_id,
					"data": tile_data,
					"biome": biome
				}
				
				if z == z_level and spawn_tree:
					var obj_id: ItemDatabase.Obj = ItemDatabase.Obj.NONE
					
					if biome == Terrain.Biome.OAK_FOREST:
						obj_id = ItemDatabase.Obj.OAK_TREE
					elif biome == Terrain.Biome.SPRUCE_FOREST:
						obj_id = ItemDatabase.Obj.SPRUCE_TREE
					elif biome == Terrain.Biome.MOUNTAINS:
						obj_id = ItemDatabase.Obj.PICKUPABLE
					
					if obj_id == ItemDatabase.Obj.OAK_TREE or obj_id == ItemDatabase.Obj.SPRUCE_TREE:
						var grow_state_val: float = remap(tree_val, 0.47, 0.94, 0, 1)
						var grow_state: int = min(max((1 - grow_state_val) * 3 + 3, 3), 5)
						
						var obj_data: WorldTreeData = ItemDatabase.get_object(obj_id).duplicate()
						obj_data.grow_state = grow_state
						obj_data.has_leaves = true
						obj_data.health = obj_data.max_health
						chunk.objects[z][y][x] = {
							"id": obj_id,
							"data": obj_data,
							"node": null
						}
					elif obj_id == ItemDatabase.Obj.PICKUPABLE:
						var obj_data: PickupableObjectData = ItemDatabase.get_object(obj_id).duplicate()
						obj_data.pickup_stack.item = ItemDatabase.get_item(ItemDatabase.Item.STONE)
						obj_data.pickup_stack.count = 1
						chunk.objects[z][y][x] = {
							"id": obj_id,
							"data": obj_data,
							"node": null
						}
			
			if z_level > highest_point:
				highest_point = z_level
	
	return chunk

func get_elevation(seed: int, x: int, y: int) -> float:
	elevation_noise_1.seed = seed
	elevation_noise_2.seed = seed
	elevation_noise_3.seed = seed
	mountains_noise.seed = seed + 912
	var val1 = elevation_noise_1.get_noise_2d(x, y)
	var val2 = elevation_noise_2.get_noise_2d(x, y)
	var val3 = elevation_noise_3.get_noise_2d(x, y)
	var val = (val1 * 5 + val2 * 2 + val3) / (5 + 2 + 1) / 2.5
	
	#if val > HIGH_ELEVATION_START - 0.05:
	#	val += ((val - (HIGH_ELEVATION_START - 0.05))) * max(-mountains_noise.get_noise_2d(x, y) + 0.5, 0) * 9
	
	if val < 0.1:
		return val
	else:
		return 0.1 + ((val - 0.1) * 2)

func elevation_easing(x: float) -> float:
	return 2 * x * x if x < 0.5 else 1 - pow(-2 * x + 2, 2) / 2;

func get_biome(seed: int, elevation: Elevation, x: int, y: int) -> Terrain.Biome:
	biome_noise.seed = seed
	var biome_value = biome_noise.get_noise_2d(x, y)
	var i := 0 # Biome index with needed elevation
	for b in Terrain.Biome.size():
		if BIOME_ELEVATION[b as Terrain.Biome] == elevation:
			i += 1 # Found a biome with needed elevation
			if ((biome_value + 1) / 2) < float(i) / float(num_biomes[elevation]):
				return b as Terrain.Biome
	return Terrain.Biome.OCEAN

func get_z_level(elevation: float, min_z: int, max_z: int) -> int:
	return max(min(int(remap(elevation, -1, 1, min_z, max_z)), max_z), min_z)
