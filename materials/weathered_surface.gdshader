shader_type spatial;
render_mode diffuse_burley;

uniform vec4 base_color : source_color = vec4(.4, .48, .51, 1.0);
uniform float moss_amount : hint_range(0.0, 1.0) = .25;
uniform float grain_scale = 8.0;
uniform float strata_amount = .0;
varying vec3 world_position;
varying vec3 world_normal;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}
float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
		mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
		mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 p = world_position;
	float patches = noise(p * 1.8);
	float grain = noise(p * grain_scale);
	float strata = pow(.5 + .5 * sin(p.y * 14.0 + patches * 8.0), 9.0);
	vec3 stone = base_color.rgb * (.68 + grain * .40 + patches * .24);
	stone *= 1.0 - strata * strata_amount * .45;
	float moss = smoothstep(.50, .73, patches) * moss_amount;
	moss *= .3 + .7 * max(world_normal.y, 0.0);
	ALBEDO = mix(stone, vec3(.20, .29, .12) * (.8 + grain * .5), moss);
	ROUGHNESS = .92;
}
