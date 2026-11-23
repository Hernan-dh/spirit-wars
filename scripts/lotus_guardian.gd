@tool
class_name LotusGuardian
extends PlaceholderUnit
## Sacred lotus protector. Combat uses the shared pawn's authoritative turn rules.
const FACING_OFFSET := .34
const WARD_SHADER := preload("res://materials/lotus_ward.gdshader")
const PETAL_COUNT := 9
const PETAL_FLIGHT_TIME := .44
const PETAL_STAGGER := .032
const PETAL_ARC := .55
const PETAL_SPREAD := .12
const WARD_DELAY := .34
const WARD_HEIGHT := .58
const WARD_RADIUS := .82
const WARD_BLOOM_TIME := .20
const WARD_HOLD_TIME := .18
const WARD_FADE_TIME := .48
const IMPACT_INNER_RADIUS := .40
const IMPACT_OUTER_RADIUS := .49
const IMPACT_RINGS := 32
const IMPACT_RING_SEGMENTS := 6
const IMPACT_HEIGHT := .17
const IMPACT_SCALE := Vector3(2.9, 1, 2.9)

var _time := 0.0
var _flare := 0.0
var _move_tween: Tween
var _visual: Node3D
var _body: Node3D
var _hair: Node3D
var _ribbons: Node3D
var _lotuses: Array[Node3D] = []
var _lotus_base_y: Array[float] = []
var _light: OmniLight3D
var _petal_mesh: ArrayMesh
var _petal_material: StandardMaterial3D

func display_name() -> String:
	return "%s Lotus %02d" % [team_name(), unit_number]

func ability_name() -> String:
	return "Lotus Ward"

func _ready() -> void:
	super._ready()
	_time = unit_number * 1.4 + float(team) * 2.0
	_visual = $LotusGuardianVisual as Node3D
	_body = _visual.get_node("GuardianBody") as Node3D
	_hair = _visual.get_node("Hair") as Node3D
	_ribbons = _visual.get_node("Ribbons") as Node3D
	_light = _visual.get_node("LotusLight") as OmniLight3D
	for child in _visual.get_node("FloatingLotus").get_children():
		if child is Node3D:
			_lotuses.append(child)
			_lotus_base_y.append(child.position.y)
	_visual.rotation.y = -FACING_OFFSET if team == Team.JADE else PI - FACING_OFFSET

func _process(delta: float) -> void:
	_time += delta
	_flare = move_toward(_flare, 0.0, delta * 2.2)
	_body.position.y = sin(_time * 1.6) * .018
	_body.scale = Vector3(1.0, 1.0 + sin(_time * 1.9) * .006, 1.0)
	_body.rotation.z = sin(_time * 1.1) * .010
	_hair.rotation.z = sin(_time * .9) * .028
	_hair.rotation.x = sin(_time * .7 + 1.1) * .012
	_ribbons.rotation.z = sin(_time * 1.35) * .035
	_ribbons.rotation.x = sin(_time * .8 + .6) * .018
	for i in _lotuses.size():
		var blossom := _lotuses[i]
		blossom.position.y = _lotus_base_y[i] + sin(_time * 1.7 + i * 1.4) * .045
		blossom.rotation.y = _time * (.32 + i * .09) * (1.0 if i % 2 == 0 else -1.0)
		blossom.rotation.z = sin(_time * 1.2 + i) * .09
	_light.light_energy = .42 + sin(_time * 2.3) * .05 + _flare

func play_move(origin: Vector3) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	var direction := global_position - origin
	if direction.length_squared() > .001:
		_visual.rotation.y = atan2(-direction.x, -direction.z)
	_visual.position = origin - global_position + Vector3(0, .04, 0)
	var start := _visual.position
	_move_tween = create_tween()
	_move_tween.tween_method(func(t: float) -> void:
		_visual.position = start.lerp(Vector3(0, .04, 0), t) + Vector3.UP * sin(t * PI) * .17
	, 0.0, 1.0, .30)

func play_spirit_pulse(target_position: Vector3) -> void:
	_flare = .9
	var direction := target_position - global_position
	if direction.length_squared() > .001:
		_visual.rotation.y = atan2(-direction.x, -direction.z)
	var heading := _visual.rotation.y
	_ensure_effect_assets()
	var side := direction.normalized().cross(Vector3.UP)
	if side.length_squared() < .01:
		side = Vector3.RIGHT
	side = side.normalized()
	var origin := global_position + Vector3.UP * 1.14
	var target := target_position + Vector3.UP * .62
	# Petals spiral from the guardian's hands toward the warded hex.
	for i in PETAL_COUNT:
		var petal := MeshInstance3D.new()
		petal.name = "LotusWardPetal%d" % (i + 1)
		petal.mesh = _petal_geometry()
		petal.material_override = _petal_material
		petal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(petal)
		var lane := (i - (PETAL_COUNT - 1) * .5) / PETAL_COUNT
		var start := origin + side * lane * (PETAL_SPREAD * 2.0) + Vector3.UP * absf(lane) * .12
		var end := target + side * lane * PETAL_SPREAD
		petal.global_position = start
		petal.scale = Vector3.ONE * .8
		petal.rotation = Vector3(lane * .9, heading + lane * 1.2, lane * 1.6)
		var flight := petal.create_tween()
		flight.tween_interval(i * PETAL_STAGGER)
		flight.tween_method(func(t: float) -> void:
			if not is_instance_valid(petal):
				return
			petal.global_position = start.lerp(end, t) + Vector3.UP * sin(t * PI) * PETAL_ARC + side * sin(t * PI) * lane * .34
			petal.rotation = Vector3(lane * .9 + t * 2.2, heading + lane * 1.2 + t * TAU, lane * 1.6 + t * 1.5)
			petal.scale = Vector3.ONE * (.8 + sin(t * PI) * .24)
		, 0.0, 1.0, PETAL_FLIGHT_TIME)
		flight.tween_callback(petal.queue_free)
	# An encounter-owned bloom survives a lethal hit.
	var bloom := Node3D.new()
	bloom.name = "LotusWardBloom"
	get_parent().add_child(bloom)
	var bloom_tween := bloom.create_tween()
	bloom_tween.tween_interval(WARD_DELAY)
	bloom_tween.tween_callback(func() -> void:
		_bloom_ward(target_position)
		bloom.queue_free()
	)
	CombatEffects.play_impact_ring(
		get_parent(),
		target_position,
		SpiritPalette.LOTUS_IMPACT,
		IMPACT_INNER_RADIUS,
		IMPACT_OUTER_RADIUS,
		IMPACT_RINGS,
		IMPACT_RING_SEGMENTS,
		IMPACT_HEIGHT,
		WARD_DELAY,
		WARD_FADE_TIME,
		IMPACT_SCALE,
		"LotusWardImpact"
	)

func _bloom_ward(target_position: Vector3) -> void:
	var dome := MeshInstance3D.new()
	dome.name = "LotusWardDome"
	var sphere := SphereMesh.new()
	sphere.radius = WARD_RADIUS
	sphere.height = WARD_RADIUS * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	dome.mesh = sphere
	var material := ShaderMaterial.new()
	material.shader = WARD_SHADER
	material.set_shader_parameter("ward_color", SpiritPalette.LOTUS_WARD)
	material.set_shader_parameter("intensity", 1.8)
	material.set_shader_parameter("fade", 1.0)
	dome.material_override = material
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(dome)
	dome.global_position = target_position + Vector3.UP * WARD_HEIGHT
	dome.scale = Vector3(.16, .10, .16)
	var tween := dome.create_tween()
	tween.tween_property(dome, "scale", Vector3(1.0, .78, 1.0), WARD_BLOOM_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(func(value: float) -> void:
		material.set_shader_parameter("intensity", value)
	, 2.4, 1.15, WARD_BLOOM_TIME)
	tween.tween_interval(WARD_HOLD_TIME)
	tween.tween_property(dome, "scale", Vector3(1.12, .86, 1.12), WARD_FADE_TIME)
	tween.parallel().tween_method(func(value: float) -> void:
		material.set_shader_parameter("fade", value)
	, 1.0, 0.0, WARD_FADE_TIME)
	tween.tween_callback(dome.queue_free)
	_bloom_petals(target_position)
	var flash := OmniLight3D.new()
	flash.name = "LotusWardLight"
	flash.light_color = SpiritPalette.LOTUS_WARD
	flash.light_energy = 1.8
	flash.omni_range = 2.6
	flash.shadow_enabled = false
	get_parent().add_child(flash)
	flash.global_position = target_position + Vector3.UP * WARD_HEIGHT
	var fade := flash.create_tween()
	fade.tween_property(flash, "light_energy", 0.0, .55)
	fade.tween_callback(flash.queue_free)

func _bloom_petals(target_position: Vector3) -> void:
	for i in 8:
		var angle := TAU * i / 8.0
		var direction := Vector3(cos(angle), 0, sin(angle))
		var petal := MeshInstance3D.new()
		petal.name = "LotusWardBloomPetal"
		petal.mesh = _petal_geometry()
		petal.material_override = _petal_material
		petal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(petal)
		petal.global_position = target_position + Vector3.UP * .12
		petal.rotation = Vector3(-.22, atan2(direction.x, direction.z), 0)
		petal.scale = Vector3.ONE * .2
		var end := target_position + Vector3.UP * .30 + direction * .58
		var spread := petal.create_tween()
		spread.tween_property(petal, "global_position", end, .24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		spread.parallel().tween_property(petal, "scale", Vector3.ONE * .95, .24)
		spread.tween_interval(.12)
		spread.tween_property(petal, "scale", Vector3.ONE * .02, .28)
		spread.tween_callback(petal.queue_free)

func _ensure_effect_assets() -> void:
	if _petal_material != null:
		return
	_petal_material = StandardMaterial3D.new()
	_petal_material.resource_name = "LotusWardPetalMaterial"
	_petal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_petal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_petal_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_petal_material.albedo_color = Color(SpiritPalette.LOTUS_PETAL, .92)
	_petal_material.emission_enabled = true
	_petal_material.emission = SpiritPalette.LOTUS_PETAL
	_petal_material.emission_energy_multiplier = 1.4

func _petal_geometry() -> ArrayMesh:
	if _petal_mesh != null:
		return _petal_mesh
	const ROWS := 6
	const COLS := 5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for row in ROWS:
		var t := float(row) / (ROWS - 1)
		var half := .075 * pow(sin(t * PI), .60) * (1.0 - .20 * t) + .001
		var ring := PackedVector3Array()
		for column in COLS:
			var u := float(column) / (COLS - 1) * 2.0 - 1.0
			var cup := (1.0 - absf(u)) * sin(t * PI) * .010
			ring.append(Vector3(u * half, cup + t * .025, t * .24))
		rings.append(ring)
	for row in range(ROWS - 1):
		for column in range(COLS - 1):
			var a := rings[row][column]
			var b := rings[row][column + 1]
			var c := rings[row + 1][column]
			var d := rings[row + 1][column + 1]
			for point in [a, c, b, b, c, d]:
				st.add_vertex(point)
	st.generate_normals()
	_petal_mesh = st.commit() as ArrayMesh
	return _petal_mesh
