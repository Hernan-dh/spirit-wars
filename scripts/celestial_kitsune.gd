@tool
class_name CelestialKitsune
extends PlaceholderUnit
## Nine-tailed sacred fox. Combat uses the shared pawn's authoritative turn rules.
const VISUAL := preload("res://scenes/units/kitsune_visual.tscn")
var _time := 0.0
var _flare := 0.0
var _move_tween: Tween
var _visual: Node3D
var _body: Node3D
var _tails: Array[Node3D] = []
var _motes: Node3D
var _spirit_light: OmniLight3D

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
	_visual.rotation.y = -.45 if team == Team.JADE else PI - .45

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
	# A trio of small luminous fox illusions converges on the chosen enemy.
	# Encounter-owned effects survive a lethal hit and disappear after their tweens.
	for i in 3:
		var echo := VISUAL.instantiate() as Node3D
		echo.name = "MirageFox"
		_tint_echo(echo, Color("d19bff") if i != 1 else Color("9cd9ff"))
		get_parent().add_child(echo)
		echo.scale = Vector3.ONE * .38
		echo.rotation.y = heading
		var start := global_position + Vector3.UP * .25 + side * (i-1) * .45
		var end := target_position + Vector3.UP * .25
		echo.global_position = start
		var flight := echo.create_tween()
		flight.tween_interval(i * .065)
		flight.tween_method(func(t: float) -> void:
			if is_instance_valid(echo):
				echo.global_position = start.lerp(end,t) + Vector3.UP * sin(t * PI) * .38 + side * sin(t * PI) * (i-1) * .35
				echo.scale = Vector3.ONE * (.38 - t * .12)
				echo.get_node("FoxBody").rotation.x = sin(t * TAU * 2.0) * .09
		, 0.0, 1.0, .48)
		flight.tween_callback(echo.queue_free)
	var pulse := MeshInstance3D.new()
	pulse.name = "MirageImpact"
	var ring := TorusMesh.new()
	ring.inner_radius = .30
	ring.outer_radius = .36
	ring.rings = 32
	ring.ring_segments = 6
	pulse.mesh = ring
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color("cf9cff")
	pulse.material_override = glow
	pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(pulse)
	pulse.global_position = target_position + Vector3.UP * .16
	pulse.hide()
	var impact := pulse.create_tween()
	impact.tween_interval(.48)
	impact.tween_callback(pulse.show)
	impact.tween_property(pulse,"scale",Vector3(3,1,3),.35)
	impact.parallel().tween_property(glow,"albedo_color:a",0.0,.35)
	impact.tween_callback(pulse.queue_free)

func _tint_echo(n: Node, color: Color) -> void:
	if n is MeshInstance3D:
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow.albedo_color = Color(color, .48)
		n.material_override = glow
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elif n is Light3D:
		n.visible = false
	for child in n.get_children():
		_tint_echo(child, color)
