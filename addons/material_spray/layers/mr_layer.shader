shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D mr;

void fragment() {
	vec4 tex = texture(mr, UV);
	vec4 back = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec2 alpha = min(vec2(1.0), tex.ba+back.ba);
	COLOR=vec4(mix(back.rg, tex.rg, tex.ba/alpha), alpha);
}