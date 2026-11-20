@tool
class_name LanternSpirit
extends PlaceholderUnit
## Lantern soul with a floating paper body and independent silk / wisp motion.
const WISP_BASE_HEIGHTS := [1.10, .76]

var _time := 0.0
var _flare := 0.0
var _body: Node3D
var _tassel: Node3D
var _wisps: Array[Node3D] = []
var _streamers: Array[Node3D] = []
var _inner_light: OmniLight3D

func display_name() -> String:
	return "%s Lantern %02d" % [team_name(), unit_number]

func _ready() -> void:
	super._ready()
	_time = unit_number * 1.7 + float(team) * 2.4
	var visual := $LanternVisual as Node3D
	_body = visual.get_node("FloatingBody") as Node3D
	_tassel = _body.get_node("Tassel") as Node3D
	_inner_light = _body.get_node("InnerLight") as OmniLight3D
	for i in WISP_BASE_HEIGHTS.size():
		_wisps.append(visual.get_node("Wisp%d" % i) as Node3D)
		_streamers.append(_body.get_node("Streamer%d" % i) as Node3D)

func _process(delta: float) -> void:
	_time += delta
	_flare = move_toward(_flare, 0.0, delta * 3.0)
	_body.position.y = sin(_time * 1.8) * .065
	_body.rotation.z = sin(_time * 1.2) * .045
	_body.rotation.y = sin(_time * .65) * .09
	_tassel.rotation.z = sin(_time * 2.2) * .09
	for i in _wisps.size():
		var wisp := _wisps[i]
		wisp.position.y = WISP_BASE_HEIGHTS[i] + sin(_time * 2.8 + i * PI) * .10
		wisp.rotation.y = _time * .5
		_streamers[i].rotation.z = sin(_time * 1.9 + i) * .08
	_inner_light.light_energy = .65 + sin(_time * 7.0) * .055 + _flare

func play_spirit_pulse(target_position: Vector3) -> void:
	_flare = 1.5
	# Effects live on the encounter so a lethal hit cannot delete their tweens.
	var bolt := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = .18
	sphere.height = .48
	bolt.mesh = sphere
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = SpiritPalette.LANTERN_FLAME
	bolt.material_override = glow
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(bolt)
	var start := global_position + Vector3(0,1.35,0)
	var end := target_position + Vector3(0,1.1,0)
	bolt.global_position = start
	var flight := bolt.create_tween()
	flight.tween_method(func(t: float) -> void:
		bolt.global_position = start.lerp(end,t) + Vector3.UP * sin(t*PI)*.45
		bolt.rotation.z = t*TAU
	,0.0,1.0,.22)
	flight.tween_callback(bolt.queue_free)
	var pulse := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = .38
	ring.outer_radius = .47
	pulse.mesh = ring
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = SpiritPalette.LANTERN_IMPACT
	pulse.material_override = material
	pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(pulse)
	pulse.global_position = target_position + Vector3(0,.2,0)
	pulse.hide()
	var impact := pulse.create_tween()
	impact.tween_interval(.22)
	impact.tween_callback(pulse.show)
	impact.tween_property(pulse,"scale",Vector3(2.8,1,2.8),.4)
	impact.parallel().tween_property(material,"albedo_color:a",0.0,.4)
	impact.tween_callback(pulse.queue_free)
