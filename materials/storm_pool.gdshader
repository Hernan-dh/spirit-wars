shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
// Shallow spirit pool at the wisp's base: bright core, travelling ring pulses.
uniform vec4 deep_color : source_color = vec4(.10, .42, .95, 1.0);
uniform vec4 glow_color : source_color = vec4(.55, .95, 1.0, 1.0);
varying vec3 pool_position;
void vertex() {
	pool_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = pool_position.xz;
	float radius = length(p);
	float ripple = .5 + .5 * sin(radius * 34.0 - TIME * 4.2);
	float spokes = .5 + .5 * sin(atan(p.y, p.x) * 7.0 + TIME * .8);
	float core = smoothstep(.46, .02, radius);
	vec3 color = mix(deep_color.rgb, glow_color.rgb, ripple * .55 + core * .45);
	ALBEDO = color;
	EMISSION = color * (1.2 + ripple * 1.1 + spokes * .3);
	ALPHA = core * (.38 + ripple * .28 + spokes * .08);
}
