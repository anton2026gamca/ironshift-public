shader_type canvas_item;


uniform bool enabled = true;

uniform sampler2DArray tilesets: filter_nearest;
uniform vec2 tileset_size = vec2(7, 7);
uniform vec2 tile_size;

const int MAX_TILES = 10;
uniform vec4 tileset_tile[MAX_TILES];
uniform vec4 TILE_AIR = vec4(0, 0, 0, 0);
uniform vec4 TILE_WATER;

uniform vec2 tilemap_position;
uniform vec2 render_tile_offset;
uniform vec2 render_tile_distance;
uniform vec2 world_scale;

uniform sampler2D tiles: filter_nearest;
varying vec2 tiles_size;

uniform bool is_selected_tile;
uniform vec2 selected_tile;

varying vec2 world_position;
varying vec2 tile_position;

vec4 get_tile(vec2 coords) {
	vec2 uv = (coords - render_tile_offset) / (tiles_size - vec2(1, 1));
	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		return texture(tiles, uv);
	} else {
		return TILE_AIR;
	}
}

vec4 get_tileset_pixel(vec2 tile_coords, int tileset_i) {
	return texture(tilesets, vec3(((world_position - tilemap_position) - ((tile_position - tile_coords) * tile_size * world_scale)) / world_scale / tile_size / tileset_size, float(tileset_i)));
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if (enabled) {
		tiles_size = render_tile_distance * 2.0 + vec2(1);
		tile_position = floor((world_position - tilemap_position) / (tile_size * world_scale));

		vec4 tile_color = get_tile(tile_position);

		int tileset_i = -1;
		for (int i = 0; i < MAX_TILES; i++) {
			if (tile_color == tileset_tile[i]) {
				tileset_i = i;
				break;
			}
		}
		if (tileset_i == -1) {
			tile_color = TILE_AIR;
		}

		if (tile_color != TILE_AIR && tile_color != TILE_WATER) {
			vec4 overlay = get_tileset_pixel(vec2(3, 3), tileset_i);
			// Edges
			// Right
			if (get_tile(tile_position + vec2(1, 0)) == TILE_AIR ||
				get_tile(tile_position + vec2(1, 0)) == TILE_WATER) {
				vec4 new = get_tileset_pixel(vec2(4, 3), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			else if (get_tile(tile_position + vec2(1, 0)) != tile_color) {
				vec4 new = get_tileset_pixel(vec2(6, 3), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			// Left
			if (get_tile(tile_position + vec2(-1, 0)) == TILE_AIR ||
				get_tile(tile_position + vec2(-1, 0)) == TILE_WATER) {
				vec4 new = get_tileset_pixel(vec2(2, 3), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			else if (get_tile(tile_position + vec2(-1, 0)) != tile_color) {
				vec4 new = get_tileset_pixel(vec2(0, 3), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			// Down
			if (get_tile(tile_position + vec2(0, 1)) == TILE_AIR) {
				vec4 new = get_tileset_pixel(vec2(3, 4), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			else if (get_tile(tile_position + vec2(0, 1)) == TILE_WATER) {
				vec4 new = get_tileset_pixel(vec2(3, 5), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			else if (get_tile(tile_position + vec2(0, 1)) != tile_color) {
				vec4 new = get_tileset_pixel(vec2(3, 6), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			// Up
			if (get_tile(tile_position + vec2(0, -1)) == TILE_AIR ||
				get_tile(tile_position + vec2(0, -1)) == TILE_WATER) {
				vec4 new = get_tileset_pixel(vec2(3, 2), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			else if (get_tile(tile_position + vec2(0, -1)) != tile_color) {
				vec4 new = get_tileset_pixel(vec2(3, 0), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}

			// Corners
			if ((get_tile(tile_position + vec2(1, 0)) == TILE_AIR) &&
				(get_tile(tile_position + vec2(0, 1)) == TILE_AIR)) {

				vec4 new = get_tileset_pixel(vec2(4, 4), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			else if ((get_tile(tile_position + vec2(1, 0)) == TILE_WATER ||
				get_tile(tile_position + vec2(1, 0)) == TILE_AIR) &&
				(get_tile(tile_position + vec2(0, 1)) == TILE_WATER ||
				get_tile(tile_position + vec2(0, 1)) == TILE_AIR)) {

				vec4 new = get_tileset_pixel(vec2(5, 5), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			if (get_tile(tile_position + vec2(-1, 0)) == TILE_AIR &&
				get_tile(tile_position + vec2(0, 1)) == TILE_AIR) {

				vec4 new = get_tileset_pixel(vec2(2, 4), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			else if ((get_tile(tile_position + vec2(-1, 0)) == TILE_WATER ||
				get_tile(tile_position + vec2(-1, 0)) == TILE_AIR) &&
				(get_tile(tile_position + vec2(0, 1)) == TILE_WATER ||
				get_tile(tile_position + vec2(0, 1)) == TILE_AIR)) {

				vec4 new = get_tileset_pixel(vec2(1, 5), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			if (get_tile(tile_position + vec2(1, 0)) == TILE_AIR &&
				get_tile(tile_position + vec2(0, -1)) == TILE_AIR) {

				vec4 new = get_tileset_pixel(vec2(4, 2), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			else if ((get_tile(tile_position + vec2(1, 0)) == TILE_WATER ||
				get_tile(tile_position + vec2(1, 0)) == TILE_AIR) &&
				(get_tile(tile_position + vec2(0, -1)) == TILE_WATER ||
				get_tile(tile_position + vec2(0, -1)) == TILE_AIR)) {

				vec4 new = get_tileset_pixel(vec2(5, 1), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			if (get_tile(tile_position + vec2(-1, 0)) == TILE_AIR &&
				get_tile(tile_position + vec2(0, -1)) == TILE_AIR) {

				vec4 new = get_tileset_pixel(vec2(2, 2), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			else if ((get_tile(tile_position + vec2(-1, 0)) == TILE_WATER ||
				get_tile(tile_position + vec2(-1, 0)) == TILE_AIR) &&
				(get_tile(tile_position + vec2(0, -1)) == TILE_WATER ||
				get_tile(tile_position + vec2(0, -1)) == TILE_AIR)) {

				vec4 new = get_tileset_pixel(vec2(1, 1), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			if ((get_tile(tile_position + vec2(-1, 0)) != TILE_AIR &&
				get_tile(tile_position + vec2(-1, 0)) != TILE_WATER) &&
				(get_tile(tile_position + vec2(0, 1)) != TILE_AIR &&
				get_tile(tile_position + vec2(0, 1)) != TILE_WATER) &&
				(get_tile(tile_position + vec2(-1, 1)) == TILE_AIR ||
				get_tile(tile_position + vec2(-1, 1)) == TILE_WATER)) {

				vec4 new = get_tileset_pixel(vec2(0, 6), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}
			if ((get_tile(tile_position + vec2(1, 0)) != TILE_AIR &&
				get_tile(tile_position + vec2(1, 0)) != TILE_WATER) &&
				(get_tile(tile_position + vec2(0, 1)) != TILE_AIR &&
				get_tile(tile_position + vec2(0, 1)) != TILE_WATER) &&
				(get_tile(tile_position + vec2(1, 1)) == TILE_AIR ||
				get_tile(tile_position + vec2(1, 1)) == TILE_WATER)) {

				vec4 new = get_tileset_pixel(vec2(6, 6), tileset_i);
				if (new != vec4(1, 0, 0, 1)) {
					overlay = new;
				}
			}

			if (overlay != vec4(1, 0, 0, 1)) {
				COLOR = overlay;
			}
		}
		else if (tile_color == TILE_WATER) {

		}
		
		if (tile_position == floor(selected_tile) && is_selected_tile) {
			COLOR = vec4(COLOR.rgb + vec3(0.2), COLOR.a);
		}
	}
}
