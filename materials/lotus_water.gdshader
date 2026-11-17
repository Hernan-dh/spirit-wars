shader_type spatial;
// Opaque water keeps the shallow pools reliable in the Compatibility renderer.
uniform vec4 deep_color : source_color = vec4(.09, .29, .34, 1.0);
uniform vec4 ripple_color : source_color = vec4(.27, .54, .53, 1.0);
varying vec2 water_position;
void vertex() {
	water_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
void fragment() {
	vec2 p = water_position;
	float wave = sin(p.x * 7.0 + p.y * 2.4 + sin(p.y * 3.3) * .8 + TIME * .55);
	float cross_wave = sin(p.y * 12.0 - p.x * 2.0 - TIME * .35);
	float ripple = pow(.5 + .5 * wave, 16.0) * (.5 + .5 * cross_wave);
	float depth = .5 + .5 * sin(p.x * .8 + sin(p.y * .5));
	ALBEDO = mix(deep_color.rgb, ripple_color.rgb, .12 + depth * .15 + ripple * .34);
	ROUGHNESS = .26;
	METALLIC = .25;
}
