shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform vec4 cloud_color : source_color = vec4(0.52, 1.0, 0.38, 1.0);
uniform vec4 core_color : source_color = vec4(0.10, 0.42, 0.08, 1.0);
uniform float intensity = 1.0;
uniform float fade = 1.0;
uniform float seed = 0.0;

float wave(vec3 p) {
	return sin(p.x * 5.0 + sin(p.y * 3.1)) * sin(p.y * 4.0 + sin(p.z * 3.7)) * sin(p.z * 4.5 + sin(p.x * 2.9));
}

void fragment() {
	vec3 p = VERTEX * 2.6 + vec3(seed * 4.0, TIME * 0.55, seed * 2.0);
	float n = wave(p) * 0.5 + 0.5;
	float n2 = sin((VERTEX.x + VERTEX.z) * 4.0 + TIME * 1.3 + seed) * 0.5 + 0.5;
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 1.6);
	float body = smoothstep(0.22, 0.80, n * 0.7 + n2 * 0.3);
	vec3 color = mix(core_color.rgb, cloud_color.rgb, body);
	ALBEDO = color * (0.75 + body * 0.55) * intensity;
	EMISSION = color * (0.15 + body * 0.45) * intensity;
	ALPHA = clamp((0.04 + body * 0.22 + rim * 0.16) * fade, 0.0, 0.60);
}
