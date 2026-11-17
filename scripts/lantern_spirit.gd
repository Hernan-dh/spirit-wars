@tool
class_name LanternSpirit
extends PlaceholderUnit
## Lantern soul with a floating paper body and independent silk / wisp motion.
var _time := 0.0
var _flare := 0.0

func display_name() -> String:
	return "%s Lantern %02d" % [team_name(), unit_number]

func _ready() -> void:
	super._ready()
	_time = unit_number * 1.7 + float(team) * 2.4

func _process(delta: float) -> void:
	_time += delta
	_flare = move_toward(_flare, 0.0, delta * 3.0)
	var body := $LanternVisual/FloatingBody as Node3D
	body.position.y = sin(_time * 1.8) * .065
	body.rotation.z = sin(_time * 1.2) * .045
	body.rotation.y = sin(_time * .65) * .09
	body.get_node("Tassel").rotation.z = sin(_time * 2.2) * .09
	for i in 2:
		var wisp := $LanternVisual.get_node("Wisp%d" % i) as Node3D
		wisp.position.y = (1.10 if i == 0 else .76) + sin(_time * 2.8 + i * PI) * .10
		wisp.rotation.y = _time * .5
		body.get_node("Streamer%d" % i).rotation.z = sin(_time * 1.9 + i) * .08
	body.get_node("InnerLight").light_energy = .65 + sin(_time * 7.0) * .055 + _flare

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
	glow.albedo_color = Color("ffb33e")
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
	material.albedo_color = Color("ff982b")
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
