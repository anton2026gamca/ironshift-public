shader_type canvas_item;

uniform vec4 outline_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform int outline_width: hint_range(0, 5) = 0;
uniform float transparency: hint_range(0.0, 1.0, 0.01) = 1.0;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);

	if (base_color.a > 0.0 || outline_width < 1) {
		base_color.a *= transparency;
		COLOR = base_color;
	} else {
		base_color.a *= transparency;

		vec2 texel_size = TEXTURE_PIXEL_SIZE * float(outline_width);

		float outline = 0.0;
		outline += texture(TEXTURE, UV + vec2(-texel_size.x, 0)).a; // Left
		outline += texture(TEXTURE, UV + vec2(texel_size.x, 0)).a;  // Right
		outline += texture(TEXTURE, UV + vec2(0, -texel_size.y)).a; // Up
		outline += texture(TEXTURE, UV + vec2(0, texel_size.y)).a;  // Down

		if (outline > 0.0) {
			COLOR = outline_color;
		} else {
			COLOR = base_color;
		}
	}
}