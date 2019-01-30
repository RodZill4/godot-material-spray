shader_type canvas_item;

uniform vec2      brush_size = vec2(0.25, 0.25);
uniform sampler2D pattern : hint_white;
uniform float     pattern_scale = 10.0;
uniform float     texture_angle = 0.0;

void fragment() {
	mat2 texture_rotation = mat2(vec2(cos(texture_angle), sin(texture_angle)), vec2(-sin(texture_angle), cos(texture_angle)));
	vec2 uv = pattern_scale*texture_rotation*(vec2(brush_size.y/brush_size.x, 1.0)*(UV - vec2(0.5, 0.5)));
	COLOR = texture(pattern, fract(uv)) * vec4(1.0, 1.0, 1.0, 0.2);
}
