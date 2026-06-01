shader_type canvas_item;

uniform vec3 bg_color : source_color = vec3(0.88, 0.88, 0.88);
uniform float tolerance : hint_range(0.0, 1.0) = 0.22;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float dist = length(col.rgb - bg_color);
	if (dist < tolerance) {
		col.a = 0.0;
	}
	COLOR = col;
}
