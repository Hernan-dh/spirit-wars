shader_type spatial;
render_mode diffuse_burley;

// Shared world-space surface: paths and moss continue across every ground mesh.
varying vec3 world_position;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = world_position.xz;
	float broad = noise(p * .31) * .65 + noise(p * .91) * .35;
	float grain = noise(p * 22.0);
	float wear = noise(p * 4.5);
	float path = min(abs(p.x - sin(p.y * .25) * 1.3) - 2.5,
		abs(p.y + .4 - sin(p.x * .28) * 1.1) - 1.8);
	path = min(path, length(p - vec2(0.0, 1.4)) - 3.8);
	float meadow = smoothstep(-.3, 1.7, path + (broad - .5) * 2.5);
	// Irregular flagstones, independent of the tactical grid.
	vec2 q = p * 1.17 + vec2(noise(p * 2.0), noise(p * 2.0 + 8.0)) * .15;
	vec2 cell = floor(q);
	vec2 f = fract(q);
	float first = 8.0;
	float second = 8.0;
	float stone_id = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 offset = vec2(float(x), float(y));
			vec2 seed = vec2(hash(cell + offset), hash(cell + offset + 19.4));
			float d = length(offset + .22 + seed * .56 - f);
			if (d < first) { second = first; first = d; stone_id = seed.x; }
			else { second = min(second, d); }
		}
	}
	float joint = 1.0 - smoothstep(.012, .055, second - first);
	vec3 stone = mix(vec3(.23, .29, .32), vec3(.43, .47, .48), stone_id);
	stone *= .83 + wear * .23 + grain * .14;
	vec3 soil = mix(vec3(.16, .20, .15), vec3(.29, .31, .22), broad);
	vec3 moss = mix(vec3(.12, .22, .12), vec3(.32, .40, .19), wear * .55 + grain * .45);
	float growth = smoothstep(.48, .67, broad + meadow * .22 + joint * .13);
	vec3 ground = mix(stone, soil, meadow * .8);
	ground = mix(ground, vec3(.12, .16, .14), joint * (1.0 - meadow) * .72);
	ALBEDO = mix(ground, moss, growth * .84);
	ROUGHNESS = .94;
}
