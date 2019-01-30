shader_type spatial;
render_mode unshaded;

vec3 fix_unshaded(vec3 xy) {
	return pow(xy, vec3(2.22));
}

void fragment() {
	float depth = FRAGCOORD.z/FRAGCOORD.w;
	ALBEDO = fix_unshaded(vec3(UV.xy, 0.0));
	//ALBEDO = fix_unshaded(vec3(cos(depth), sin(depth*7.0), sin(depth/7.0)));
}
