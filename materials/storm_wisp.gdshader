shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Vertex colors carry the wisp's cyan-to-violet storm gradient.
// The fine pulse travels up the coiled body so the saved mesh still reads
// as living energy without bloom or runtime remeshing.
void fragment() {
	vec3 storm = COLOR.rgb;
	float pulse = .5 + .5 * sin(TIME * 3.1 + VERTEX.y * 5.0 + VERTEX.x * 7.0);
	float vein = pow(pulse, 6.0);
	ALBEDO = storm * (.86 + vein * .30);
	ROUGHNESS = .34;
	METALLIC = .12;
	EMISSION = storm * (.24 + vein * .55);
}
