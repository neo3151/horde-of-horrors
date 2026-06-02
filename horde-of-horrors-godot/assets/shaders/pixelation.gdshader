shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 uv = SCREEN_UV;
	
	// Calculate the ratio of screen pixels to game pixels
	vec2 pixelated_uv = floor(uv * screen_size / pixel_size) * pixel_size / screen_size;
	
	// Add a small offset to the center of the "pixel" to avoid sampling edges
	pixelated_uv += (pixel_size / 2.0) / screen_size;
	
	COLOR = texture(screen_texture, pixelated_uv);
}
