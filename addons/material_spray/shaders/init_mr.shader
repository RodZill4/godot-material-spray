shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D metallic : hint_white;
uniform vec4      metallic_mask = vec4(1.0, 0.0, 0.0, 0.0);
uniform sampler2D roughness : hint_white;
uniform vec4      roughness_mask = vec4(0.0, 1.0, 0.0, 0.0);

void fragment() {
	COLOR = vec4(dot(texture(metallic, UV), metallic_mask), dot(texture(roughness, UV), roughness_mask), 0.0, 1.0);
}
