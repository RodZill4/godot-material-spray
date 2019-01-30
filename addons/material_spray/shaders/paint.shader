shader_type canvas_item;

uniform sampler2D tex2view_tex;
uniform sampler2D tex2viewlsb_tex;
uniform sampler2D pattern : hint_white;
uniform sampler2D seams : hint_white;
uniform vec2      brush_pos         = vec2(0.5, 0.5);
uniform vec2      brush_ppos        = vec2(0.5, 0.5);
uniform vec2      brush_size        = vec2(0.25, 0.25);
uniform float     brush_strength    = 1.0;
uniform vec4      brush_color       = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4      brush_channelmask = vec4(1.0, 1.0, 1.0, 1.0);
uniform float     pattern_scale     = 10.0;

float brush(float v) {
	return clamp(v / (1.0-brush_strength), 0.0, 1.0);
}

void fragment() {
	vec2 uv = UV+(texture(seams, UV).xy-vec2(0.5))/64.0;
	vec4 tex2view = texture(tex2view_tex, uv);
	vec4 tex2viewlsb = texture(tex2viewlsb_tex, uv);
	vec2 xy = tex2view.xy+tex2viewlsb.xy/255.0;
	vec2 b = brush_pos/brush_size;
	vec2 bv = (brush_ppos-brush_pos)/brush_size;
	vec2 p = xy/brush_size;
	float x = clamp(dot(p-b, bv)/dot(bv, bv), 0.0, 1.0);
	float a = 1.0-length(p-(b+x*bv));
	a = brush(max(0.0, a))*brush_color.w*tex2view.z;
	vec4 color = brush_color*texture(pattern, fract(pattern_scale*vec2(brush_size.y/brush_size.x, 1.0)*xy));
	a *= color.a;
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	COLOR = vec4(color.xyz*a*brush_channelmask.xyz+screen_color.xyz*(vec3(1.0)-a*brush_channelmask.xyz), 1.0);
}
