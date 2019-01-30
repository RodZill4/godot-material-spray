shader_type spatial;
render_mode unshaded, cull_front;

void vertex() {
	VERTEX=vec3(UV.x, UV.y, 0.0);
	COLOR=vec4(1.0);
}

void fragment() {
	ALBEDO = vec3(1.0);
}
