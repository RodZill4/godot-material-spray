shader_type canvas_item;

uniform sampler2D tex;
uniform float epsilon = 0.007812500;

void fragment() {
	vec3 color = vec3(0.0);
	color += vec3(-1.0, -1.0, 0.0) * textureLod(tex, UV+vec2(-epsilon, -epsilon), epsilon).rgb;
	color += vec3(0.0, -2.0, 0.0) * textureLod(tex, UV+vec2(0.0, -epsilon), epsilon).rgb;
	color += vec3(1.0, -1.0, 0.0) * textureLod(tex, UV+vec2(epsilon, -epsilon), epsilon).rgb;
	color += vec3(-2.0, 0.0, 0.0) * textureLod(tex, UV+vec2(-epsilon, 0.0), epsilon).rgb;
	color += vec3(2.0, 0.0, 0.0) * textureLod(tex, UV+vec2(epsilon, 0.0), epsilon).rgb;
	color += vec3(-1.0, 1.0, 0.0) * textureLod(tex, UV+vec2(-epsilon, epsilon), epsilon).rgb;
	color += vec3(0.0, 2.0, 0.0) * textureLod(tex, UV+vec2(0.0, epsilon), epsilon).rgb;
	color += vec3(1.0, 1.0, 0.0) * textureLod(tex, UV+vec2(epsilon, epsilon), epsilon).rgb;
	color *= vec3(1.0, -1.0, 0.0);
	color += vec3(0.0, 0.0, -1.0);
	color = normalize(color);
	color *= 0.5;
	color += vec3(0.5, 0.5, 0.5);
	COLOR = vec4(color, 1.0);
}