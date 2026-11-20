extends RefCounted
## Single source of truth for authored ground zones. The field metadata, the
## shared ground shader and vegetation clearing all read these values.

# Pilgrim road: x = sin(z * frequency) * amplitude, with a half-width footprint.
const PILGRIM_AMPLITUDE := 1.3
const PILGRIM_FREQUENCY := .25
const PILGRIM_HALF_WIDTH := 2.5
# Cross road: z = -offset + sin(x * frequency) * amplitude.
const CROSS_AMPLITUDE := 1.1
const CROSS_FREQUENCY := .28
const CROSS_OFFSET := .4
const CROSS_HALF_WIDTH := 1.8
# Central plaza.
const PLAZA_CENTER := Vector2(0.0, 1.4)
const PLAZA_RADIUS := 3.8
# Keep vegetation slightly clear of the paved footprint.
const VEGETATION_CLEARANCE := .3
# Number of painted flagstone labels stored in tile terrain metadata.
# These labels describe the shared shader zones; they are not palette materials.
const PAVING_VARIANTS := 6

# Meadow bands and the eastern/western edges of the authored field.
const MEADOW_X_FREQUENCY := .36
const MEADOW_Z_FREQUENCY := .42
const MEADOW_SUM_FREQUENCY := .23
const MEADOW_DEEP_THRESHOLD := -1.2
const MEADOW_THRESHOLD := -.55
const TRAIL_EARTH_THRESHOLD := 1.25
const EAST_BANK_START := 7.5
const EAST_BANK_Z_FREQUENCY := .5
const WEST_MEADOW_X := -7.0
const WEST_MEADOW_Z := 3.0

# Visual transition parameters consumed by sanctuary_ground.gdshader.
const PATH_BLEND_START := -.3
const PATH_BLEND_END := 1.7
const PATH_NOISE_STRENGTH := 2.5

static func path_distance(pos: Vector2) -> float:
	var pilgrim := absf(pos.x - sin(pos.y * PILGRIM_FREQUENCY) * PILGRIM_AMPLITUDE) - PILGRIM_HALF_WIDTH
	var crossing := absf(pos.y + CROSS_OFFSET - sin(pos.x * CROSS_FREQUENCY) * CROSS_AMPLITUDE) - CROSS_HALF_WIDTH
	var plaza := (pos - PLAZA_CENTER).length() - PLAZA_RADIUS
	return minf(pilgrim, minf(crossing, plaza))

static func is_paving(pos: Vector2) -> bool:
	return path_distance(pos) < 0.0

static func is_within_paving_margin(pos: Vector2, margin: float) -> bool:
	return path_distance(pos) < margin

static func meadow_value(pos: Vector2) -> float:
	return sin(pos.x * MEADOW_X_FREQUENCY) + cos(pos.y * MEADOW_Z_FREQUENCY) + sin((pos.x + pos.y) * MEADOW_SUM_FREQUENCY)

static func material_for(pos: Vector2, rng: RandomNumberGenerator) -> String:
	if is_paving(pos):
		return "Paving%d" % rng.randi_range(0, PAVING_VARIANTS - 1)
	if pos.x > EAST_BANK_START + sin(pos.y * EAST_BANK_Z_FREQUENCY):
		return "BankPaving"
	var meadow := meadow_value(pos)
	if meadow < MEADOW_THRESHOLD or (pos.x < WEST_MEADOW_X and pos.y > WEST_MEADOW_Z):
		return "MeadowLight" if meadow < MEADOW_DEEP_THRESHOLD else "Meadow"
	if meadow > TRAIL_EARTH_THRESHOLD:
		return "TrailEarth"
	return "MossPaving"

static func apply_shader_parameters(material: ShaderMaterial) -> void:
	material.set_shader_parameter("pilgrim_amplitude", PILGRIM_AMPLITUDE)
	material.set_shader_parameter("pilgrim_frequency", PILGRIM_FREQUENCY)
	material.set_shader_parameter("pilgrim_half_width", PILGRIM_HALF_WIDTH)
	material.set_shader_parameter("cross_amplitude", CROSS_AMPLITUDE)
	material.set_shader_parameter("cross_frequency", CROSS_FREQUENCY)
	material.set_shader_parameter("cross_offset", CROSS_OFFSET)
	material.set_shader_parameter("cross_half_width", CROSS_HALF_WIDTH)
	material.set_shader_parameter("plaza_center", PLAZA_CENTER)
	material.set_shader_parameter("plaza_radius", PLAZA_RADIUS)
	material.set_shader_parameter("path_blend_start", PATH_BLEND_START)
	material.set_shader_parameter("path_blend_end", PATH_BLEND_END)
	material.set_shader_parameter("path_noise_strength", PATH_NOISE_STRENGTH)
