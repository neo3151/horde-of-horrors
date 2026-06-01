shader_type canvas_item;

uniform bool active = false;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tint_color = texture(TEXTURE, UV);
	if (active) {
		tint_color.rgb = flash_color.rgb;
	}
	COLOR = tint_color;
}
