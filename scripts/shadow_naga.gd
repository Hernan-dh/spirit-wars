@tool
class_name ShadowNaga
extends PlaceholderUnit
## Serpentine jungle spirit steeped in miasma. Combat uses the shared pawn rules.
const FACING_OFFSET := .34
const MIASMA_SHADER := preload("res://materials/shadow_miasma.gdshader")

const BOLT_COUNT := 3
const BOLT_FLIGHT_TIME := .32
const BOLT_STAGGER := .055
const BOLT_ARC := .38
const BOLT_SPREAD := .16
const CLOUD_DELAY := .26
const CLOUD_BLOOM_TIME := .36
const CLOUD_HOLD_TIME := .34
const CLOUD_FADE_TIME := .62
const CLOUD_RADIUS := .5
const MOTE_COUNT := 10
const IMPACT_INNER_RADIUS := .44
const IMPACT_OUTER_RADIUS := .56
const IMPACT_RINGS := 32
const IMPACT_RING_SEGMENTS := 6
const IMPACT_HEIGHT := .14
const IMPACT_SCALE := Vector3(3.0, 1, 3.0)

var _time := 0.0
var _flare := 0.0
var _move_tween: Tween
var _visual: Node3D
var _body: Node3D
var _head: Node3D
var _mane: Node3D
var _miasma: Node3D
var _light: OmniLight3D
var _head_base: Vector3
var _mane_base: Vector3
var _miasma_base: Vector3
var _blossoms: Array[Node3D] = []
var _blossom_base_y: Array[float] = []
var _mote_mesh: SphereMesh
var _cloud_mesh: SphereMesh
var _bolt_material: StandardMaterial3D
var _mote_material: StandardMaterial3D

func display_name() -> String:
	return "%s Naga %02d" % [team_name(), unit_number]

func ability_name() -> String:
	return "Miasma Cloud"

func _ready() -> void:
	super._ready()
	_time = unit_number * 1.6 + float(team) * 2.3
	_visual = $ShadowNagaVisual as Node3D
	_body = _visual.get_node("NagaBody") as Node3D
	_head = _visual.get_node("NagaHead") as Node3D
	_mane = _visual.get_node("Mane") as Node3D
	_miasma = _visual.get_node("Miasma") as Node3D
	_light = _visual.get_node("MiasmaLight") as OmniLight3D
	_light.light_color = SpiritPalette.SHADOW_NAGA_MIASMA
	_head_base = _head.position
	_mane_base = _mane.position
	_miasma_base = _miasma.position
	for child in _visual.get_node("Blossoms").get_children():
		if child is Node3D:
			_blossoms.append(child)
			_blossom_base_y.append(child.position.y)
	_visual.rotation.y = -FACING_OFFSET if team == Team.JADE else PI - FACING_OFFSET

func _process(delta: float) -> void:
	_time += delta
	_flare = move_toward(_flare, 0.0, delta * 2.1)
	_body.position.y = sin(_time * 1.4) * .012
	_body.scale = Vector3(1.0, 1.0 + sin(_time * 1.7) * .007, 1.0)
	_body.rotation.z = sin(_time * .8) * .012
	_head.position = _head_base + Vector3(0, sin(_time * 1.3) * .010, sin(_time * .7) * .006)
	_head.rotation.x = sin(_time * 1.15) * .045
	_head.rotation.y = sin(_time * .55) * .020
	_head.rotation.z = sin(_time * .85 + 1.0) * .030
	_mane.position = _mane_base + Vector3(0, sin(_time * .9 + .4) * .012, 0)
	_mane.rotation.x = sin(_time * .75 + .6) * .030
	_mane.rotation.z = sin(_time * .9) * .055
	_miasma.position.y = _miasma_base.y + sin(_time * .8) * .020
	_miasma.rotation.y = _time * .11
	_miasma.scale = Vector3.ONE * (1.0 + sin(_time * 1.1) * .015)
	for i in _blossoms.size():
		var blossom := _blossoms[i]
		blossom.position.y = _blossom_base_y[i] + sin(_time * 1.6 + i * 1.3) * .030
		blossom.rotation.y = _time * (.28 + i * .08) * (1.0 if i % 2 == 0 else -1.0)
		blossom.rotation.z = sin(_time * 1.1 + i) * .07
	_light.light_energy = .46 + sin(_time * 2.2) * .06 + _flare

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
		_visual.position = start.lerp(Vector3(0, .04, 0), t) + Vector3.UP * sin(t * PI) * .14
	, 0.0, 1.0, .32)

func play_spirit_pulse(target_position: Vector3) -> void:
	_flare = 1.0
	var direction := target_position - global_position
	if direction.length_squared() > .001:
		_visual.rotation.y = atan2(-direction.x, -direction.z)
	_ensure_effect_assets()
	var side := direction.normalized().cross(Vector3.UP)
	if side.length_squared() < .01:
		side = Vector3.RIGHT
	side = side.normalized()
	var mouth := _visual.to_global(Vector3(0, 1.50, -.34))
	var target := target_position + Vector3.UP * .46
	# Venom motes arc from the maw before the cloud blooms.
	for i in BOLT_COUNT:
		var bolt := MeshInstance3D.new()
		bolt.name = "MiasmaBolt%d" % (i + 1)
		bolt.mesh = _mote_mesh
		bolt.material_override = _bolt_material
		bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(bolt)
		var lane := (i - (BOLT_COUNT - 1) * .5)
		var start := mouth + side * lane * BOLT_SPREAD + Vector3.UP * absf(lane) * .05
		var end := target + side * lane * BOLT_SPREAD
		bolt.global_position = start
		bolt.scale = Vector3.ONE * .75
		var flight := bolt.create_tween()
		flight.tween_interval(i * BOLT_STAGGER)
		flight.tween_method(func(t: float) -> void:
			if not is_instance_valid(bolt):
				return
			bolt.global_position = start.lerp(end, t) + Vector3.UP * sin(t * PI) * BOLT_ARC + side * sin(t * PI) * lane * .18
			bolt.scale = Vector3.ONE * (.75 - t * .35)
		, 0.0, 1.0, BOLT_FLIGHT_TIME)
		flight.tween_callback(bolt.queue_free)
	# Encounter-owned bloom survives a lethal hit.
	var cloud := Node3D.new()
	cloud.name = "MiasmaCloud"
	get_parent().add_child(cloud)
	var bloom := cloud.create_tween()
	bloom.tween_interval(CLOUD_DELAY)
	bloom.tween_callback(func() -> void:
		_bloom_cloud(target_position)
		cloud.queue_free()
	)
	CombatEffects.play_impact_ring(
		get_parent(),
		target_position,
		SpiritPalette.MIASMA_IMPACT,
		IMPACT_INNER_RADIUS,
		IMPACT_OUTER_RADIUS,
		IMPACT_RINGS,
		IMPACT_RING_SEGMENTS,
		IMPACT_HEIGHT,
		CLOUD_DELAY,
		CLOUD_FADE_TIME,
		IMPACT_SCALE,
		"MiasmaImpact"
	)

func _bloom_cloud(target_position: Vector3) -> void:
	var cloud := Node3D.new()
	cloud.name = "MiasmaCloudBloom"
	get_parent().add_child(cloud)
	var material := ShaderMaterial.new()
	material.shader = MIASMA_SHADER
	material.set_shader_parameter("cloud_color", SpiritPalette.MIASMA)
	material.set_shader_parameter("core_color", SpiritPalette.MIASMA_DEEP)
	material.set_shader_parameter("intensity", 1.35)
	material.set_shader_parameter("fade", 1.0)
	material.set_shader_parameter("seed", .37)
	var lobes := [
		[Vector3(0, .25, 0), Vector3(1.62, .56, 1.48)],
		[Vector3(.42, .21, .20), Vector3(1.10, .46, 1.00)],
		[Vector3(-.40, .20, -.12), Vector3(1.02, .42, 1.08)],
		[Vector3(.05, .18, -.40), Vector3(.92, .38, .86)],
		[Vector3(-.07, .18, .38), Vector3(.98, .40, .92)],
	]
	for i in lobes.size():
		var lobe := MeshInstance3D.new()
		lobe.name = "MiasmaLobe%d" % (i + 1)
		lobe.mesh = _cloud_mesh
		lobe.material_override = material
		lobe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cloud.add_child(lobe)
		var spec: Array = lobes[i]
		var home: Vector3 = spec[0]
		var goal: Vector3 = spec[1]
		lobe.position = home + Vector3(0, -.08, 0)
		lobe.scale = Vector3(.14, .10, .14)
		lobe.rotation.y = i * 1.1
		var grow := lobe.create_tween()
		grow.tween_interval(i * .035)
		grow.tween_property(lobe, "scale", goal, CLOUD_BLOOM_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		grow.parallel().tween_property(lobe, "position", home + Vector3(0, .03, 0), CLOUD_BLOOM_TIME).set_trans(Tween.TRANS_SINE)
	var fade := cloud.create_tween()
	fade.tween_interval(CLOUD_BLOOM_TIME + CLOUD_HOLD_TIME)
	fade.tween_method(func(value: float) -> void:
		material.set_shader_parameter("fade", value)
	, 1.0, 0.0, CLOUD_FADE_TIME)
	fade.tween_callback(cloud.queue_free)
	_bloom_motes(target_position)
	var flash := OmniLight3D.new()
	flash.name = "MiasmaCloudLight"
	flash.light_color = SpiritPalette.MIASMA
	flash.light_energy = 2.0
	flash.omni_range = 3.0
	flash.shadow_enabled = false
	get_parent().add_child(flash)
	flash.global_position = target_position + Vector3.UP * .32
	var dim := flash.create_tween()
	dim.tween_property(flash, "light_energy", 0.0, .70)
	dim.tween_callback(flash.queue_free)

func _bloom_motes(target_position: Vector3) -> void:
	for i in MOTE_COUNT:
		var mote := MeshInstance3D.new()
		mote.name = "MiasmaMote%d" % (i + 1)
		mote.mesh = _mote_mesh
		mote.material_override = _mote_material
		mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(mote)
		var angle := TAU * i / MOTE_COUNT + .25
		var radius := .17 + (i % 4) * .075
		var start := target_position + Vector3(cos(angle) * radius, .12 + (i % 3) * .06, sin(angle) * radius)
		var drift := Vector3(cos(angle) * .20, .42 + (i % 4) * .07, sin(angle) * .20)
		var end := start + drift
		mote.global_position = start
		mote.scale = Vector3.ONE * (.42 + (i % 3) * .14)
		var rise := mote.create_tween()
		rise.tween_interval(i * .028)
		rise.tween_method(func(t: float) -> void:
			if not is_instance_valid(mote):
				return
			mote.global_position = start.lerp(end, t) + Vector3(sin(t * PI * 1.4 + i) * .05, 0, cos(t * PI * 1.1 + i) * .05)
			mote.scale = Vector3.ONE * (.42 + (i % 3) * .14) * (1.0 - t * .75)
		, 0.0, 1.0, CLOUD_BLOOM_TIME + CLOUD_HOLD_TIME + CLOUD_FADE_TIME)
		rise.tween_callback(mote.queue_free)

func _ensure_effect_assets() -> void:
	if _mote_mesh != null:
		return
	_mote_mesh = SphereMesh.new()
	_mote_mesh.radius = 1.0
	_mote_mesh.height = 2.0
	_mote_mesh.radial_segments = 12
	_mote_mesh.rings = 6
	_cloud_mesh = SphereMesh.new()
	_cloud_mesh.radius = CLOUD_RADIUS
	_cloud_mesh.height = CLOUD_RADIUS * 2.0
	_cloud_mesh.radial_segments = 20
	_cloud_mesh.rings = 10
	_bolt_material = CombatEffects.unshaded_material(SpiritPalette.MIASMA, "MiasmaBoltMaterial")
	_mote_material = CombatEffects.transparent_unshaded_material(Color(SpiritPalette.MIASMA, .85), "MiasmaMoteMaterial")
