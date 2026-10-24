shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float scanline_strength : hint_range(0.0, 0.4) = 0.18;
uniform float dither_strength : hint_range(0.0, 0.1) = 0.035;

void fragment() {
	vec4 scene_color = texture(screen_texture, SCREEN_UV);
	float scanline = mod(floor(FRAGCOORD.y), 3.0);
	float scan_multiplier = scanline == 0.0 ? 1.0 - scanline_strength : 1.0;
	float checker = mod(floor(FRAGCOORD.x) + floor(FRAGCOORD.y), 2.0);
	float dither_multiplier = checker == 0.0 ? 1.0 - dither_strength : 1.0;
	vec3 retro_color = scene_color.rgb * scan_multiplier * dither_multiplier;
	COLOR = vec4(retro_color, 1.0);
}
