@tool
class_name CelestialKitsune
extends PlaceholderUnit
## Nine-tailed sacred fox. Combat uses the shared pawn's authoritative turn rules.
const FACING_OFFSET := .45

const ECHO_COUNT := 3
const ECHO_SCALE := .38
const ECHO_START_HEIGHT := .25
const ECHO_SPREAD := .45
const ECHO_ARC := .38
const ECHO_STAGGER := .065
const ECHO_FLIGHT_TIME := .48
const ECHO_SHRINK := .12
const ECHO_SIDE_WAVE := .35
const IMPACT_INNER_RADIUS := .30
const IMPACT_OUTER_RADIUS := .36
const IMPACT_RINGS := 32
const IMPACT_RING_SEGMENTS := 6
const IMPACT_HEIGHT := .16
const IMPACT_DELAY := .48
const IMPACT_DURATION := .35
const IMPACT_SCALE := Vector3(3, 1, 3)

var _time := 0.0
var _flare := 0.0
var _move_tween: Tween
var _visual: Node3D
var _body: Node3D
var _tails: Array[Node3D] = []
var _motes: Node3D
var _spirit_light: OmniLight3D
var _echo_mesh: ArrayMesh
var _echo_material: StandardMaterial3D

func display_name() -> String:
	return "%s Kitsune %02d" % [team_name(), unit_number]

func ability_name() -> String:
	return "Mirage Rush"

func _ready() -> void:
	super._ready()
	_time = unit_number * 1.3 + float(team) * 2.1
	_visual = $KitsuneVisual as Node3D
	_body = _visual.get_node("FoxBody") as Node3D
	_motes = _visual.get_node("Motes") as Node3D
	_spirit_light = _visual.get_node("SpiritLight") as OmniLight3D
	for child in _visual.get_node("Tails").get_children():
		if child is Node3D:
			_tails.append(child)
	_visual.rotation.y = -FACING_OFFSET if team == Team.JADE else PI - FACING_OFFSET

func _process(delta: float) -> void:
	_time += delta
	_flare = move_toward(_flare, 0.0, delta * 2.0)
	_body.scale = Vector3(1.0, 1.0 + sin(_time * 1.8) * .012, 1.0)
	for i in _tails.size():
		var tail := _tails[i]
		tail.rotation.z = sin(_time * 1.5 + i * .65) * .045
		tail.rotation.y = sin(_time * 1.2 + i * .8) * .055
	_motes.rotation.y = sin(_time * .5) * .16
	_spirit_light.light_energy = .35 + sin(_time * 2.4) * .06 + _flare

func play_move(origin: Vector3) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	var direction := global_position - origin
	_visual.rotation.y = atan2(-direction.x, -direction.z)
	_visual.position = origin - global_position + Vector3(0,.04,0)
	var start := _visual.position
	_move_tween = create_tween()
	_move_tween.tween_method(func(t: float) -> void:
		_visual.position = start.lerp(Vector3(0,.04,0), t) + Vector3.UP * sin(t * PI) * .22
	, 0.0, 1.0, .28)

func play_spirit_pulse(target_position: Vector3) -> void:
	_flare = .7
	var direction := (target_position - global_position).normalized()
	var side := direction.cross(Vector3.UP)
	var heading := atan2(-direction.x, -direction.z)
	_visual.rotation.y = heading
	# Three cheap fox silhouettes share one mesh and material per attack.
	# Encounter-owned effects survive a lethal hit and disappear after their tweens.
	_ensure_echo_assets()
	for echo_index in ECHO_COUNT:
		var echo := MeshInstance3D.new()
		echo.name = "MirageFox%d" % (echo_index + 1)
		echo.mesh = _echo_mesh
		echo.material_override = _echo_material
		echo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(echo)
		echo.scale = Vector3.ONE * ECHO_SCALE
		echo.rotation.y = heading
		var start := global_position + Vector3.UP * ECHO_START_HEIGHT + side * (echo_index - 1) * ECHO_SPREAD
		var end := target_position + Vector3.UP * ECHO_START_HEIGHT
		echo.global_position = start
		var flight := echo.create_tween()
		flight.tween_interval(echo_index * ECHO_STAGGER)
		flight.tween_method(func(t: float) -> void:
			if not is_instance_valid(echo):
				return
			echo.global_position = start.lerp(end, t) + Vector3.UP * sin(t * PI) * ECHO_ARC + side * sin(t * PI) * (echo_index - 1) * ECHO_SIDE_WAVE
			echo.scale = Vector3.ONE * (ECHO_SCALE - t * ECHO_SHRINK)
		, 0.0, 1.0, ECHO_FLIGHT_TIME)
		flight.tween_callback(echo.queue_free)
	CombatEffects.play_impact_ring(
		get_parent(),
		target_position,
		SpiritPalette.KITSUNE_IMPACT,
		{
			"inner_radius": IMPACT_INNER_RADIUS,
			"outer_radius": IMPACT_OUTER_RADIUS,
			"rings": IMPACT_RINGS,
			"ring_segments": IMPACT_RING_SEGMENTS,
			"height": IMPACT_HEIGHT,
			"delay": IMPACT_DELAY,
			"duration": IMPACT_DURATION,
			"scale": IMPACT_SCALE,
			"name": "MirageImpact",
		}
	)

func _ensure_echo_assets() -> void:
	if _echo_mesh != null:
		return
	_echo_mesh = _build_echo_mesh()
	_echo_material = CombatEffects.transparent_unshaded_material(
		Color(SpiritPalette.KITSUNE_ECHO_PRIMARY, .48),
		"MirageEchoMaterial"
	)

func _build_echo_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := SphereMesh.new()
	body.radius = .26
	body.height = .62
	body.radial_segments = 8
	body.rings = 5
	surface.append_from(body, 0, _part_transform(Vector3(0,.35,.04), Vector3(1,1,.8)))
	var head := SphereMesh.new()
	head.radius = .19
	head.height = .40
	head.radial_segments = 8
	head.rings = 4
	surface.append_from(head, 0, _part_transform(Vector3(0,.65,-.22)))
	var snout := SphereMesh.new()
	snout.radius = .10
	snout.height = .22
	snout.radial_segments = 6
	snout.rings = 3
	surface.append_from(snout, 0, _part_transform(Vector3(0,.61,-.41), Vector3(1.2,.8,1.5)))
	for side in [-1, 1]:
		surface.append_from(_echo_cone(.075, .24), 0, _part_transform(Vector3(side*.12,.84,-.18), Vector3.ONE, Vector3(0,0,side*.12)))
		for z in [-.18, .18]:
			surface.append_from(_echo_tube(.04, .28), 0, _part_transform(Vector3(side*.12,.14,z)))
	for tail_index in 3:
		surface.append_from(
			_echo_cone(.065, .62),
			0,
			_part_transform(Vector3((tail_index - 1) * .17,.36,.42), Vector3.ONE, Vector3(1.15,0,0))
		)
	surface.generate_normals()
	return surface.commit()

func _echo_cone(bottom_radius: float, height: float) -> CylinderMesh:
	var cone := CylinderMesh.new()
	cone.bottom_radius = bottom_radius
	cone.top_radius = 0.0
	cone.height = height
	cone.radial_segments = 6
	cone.rings = 1
	return cone

func _echo_tube(radius: float, height: float) -> CylinderMesh:
	var tube := CylinderMesh.new()
	tube.bottom_radius = radius
	tube.top_radius = radius
	tube.height = height
	tube.radial_segments = 5
	tube.rings = 1
	return tube

func _part_transform(origin: Vector3, scale := Vector3.ONE, rotation := Vector3.ZERO) -> Transform3D:
	var basis := Basis.from_scale(scale)
	basis = basis.rotated(Vector3.RIGHT, rotation.x).rotated(Vector3.UP, rotation.y).rotated(Vector3.FORWARD, rotation.z)
	return Transform3D(basis, origin)
