shader_type canvas_item;


uniform bool enabled = true;
uniform float value = 0.5;


vec4 gray_scale(vec4 color) {
	return vec4(vec3((color.r + color.g + color.b) / 3.0), 1);
}

void fragment() {
	if (enabled) {
		if (gray_scale(COLOR).r >= value) {
			COLOR.rgb = vec3(1, 1, 1);
		} else {
			COLOR.rgb = vec3(0, 0, 0);
		}
	}
}
