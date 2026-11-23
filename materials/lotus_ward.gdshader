shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 ward_color : source_color = vec4(0.45, 0.95, 0.92, 1.0);
uniform float intensity = 1.15;
uniform float fade = 1.0;

void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
	ALBEDO = ward_color.rgb * (0.20 + rim * 1.35) * intensity;
	ALPHA = clamp((0.045 + rim * 0.55) * fade, 0.0, 0.85);
}
