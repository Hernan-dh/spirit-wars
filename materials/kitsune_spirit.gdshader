shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Vertex colors keep each plume's ivory root and pink / blue / violet flame tip.
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.4;
	EMISSION = COLOR.rgb * (0.20 + 0.06 * sin(TIME * 2.0 + VERTEX.y * 3.0));
}
