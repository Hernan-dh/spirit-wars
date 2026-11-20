shader_type spatial;
render_mode unshaded, cull_disabled;
// Crackling arcs share one material; each copy flickers on its own phase.
uniform vec4 arc_color : source_color = vec4(.72, .95, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flicker_speed = 17.0;
void fragment() {
	float crackle = .55 + .45 * sin(TIME * flicker_speed + VERTEX.x * 21.0 + VERTEX.z * 13.0);
	vec3 glow = mix(arc_color.rgb, core_color.rgb, crackle * .7);
	ALBEDO = glow;
	EMISSION = glow * (2.2 + crackle * 2.6);
}
