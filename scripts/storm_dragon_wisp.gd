@tool
class_name StormDragonWisp
extends PlaceholderUnit
## Coiled storm spirit. Combat uses the shared pawn's authoritative turn rules.
const VISUAL := preload("res://scenes/units/storm_dragon_visual.tscn")
var _time := 0.0
var _flare := 0.0
var _move_tween: Tween

func display_name() -> String:
	return "%s Storm %02d" % [team_name(), unit_number]

func ability_name() -> String:
	return "Thunder Whip"

func _ready() -> void:
	super._ready()
	_time = unit_number * 1.9 + float(team) * 2.3
	var visual := $StormDragonVisual as Node3D
	visual.rotation.y = .28 if team == Team.JADE else -.28

func _process(delta: float) -> void:
	_time += delta
	_flare = move_toward(_flare, 0.0, delta * 2.4)
	var visual := $StormDragonVisual as Node3D
	var body := visual.get_node("StormBody") as Node3D
	body.position.y = sin(_time * 1.7) * .055
	body.rotation.y = sin(_time * .8) * .05
	var head := body.get_node("Head") as Node3D
	head.rotation.y = sin(_time * .9) * .10
	head.rotation.x = .12 + sin(_time * 1.3) * .035
	for side in ["WhiskerL","WhiskerR"]:
		var whisker := head.get_node(side) as Node3D
		whisker.rotation.z = sin(_time * 1.4 + (0.0 if side == "WhiskerL" else 1.7)) * .11
		whisker.rotation.y = sin(_time * .9 + (0.0 if side == "WhiskerL" else 2.1)) * .10
	for i in body.get_node("BodyArcs").get_child_count():
		var arc := body.get_node("BodyArcs").get_child(i) as Node3D
		arc.visible = sin(_time * 7.0 + i * 2.1) > -.72
	for i in head.get_node("HeadArcs").get_child_count():
		var arc := head.get_node("HeadArcs").get_child(i) as Node3D
		arc.visible = sin(_time * 9.0 + i * 2.7) > -.55
	for i in 2:
		var ripple := visual.get_node("BaseEffects/PoolRipple%d" % i) as Node3D
		var pulse := .9 + sin(_time * 2.0 - i * 1.4) * .12
		ripple.scale = Vector3(pulse, 1, pulse)
		ripple.rotation.y = _time * (.35 + i * .15) * (1 if i == 0 else -1)
	(visual.get_node("StormBody/StormLight") as OmniLight3D).light_energy = .55 + sin(_time * 8.0) * .10 + _flare

func play_move(origin: Vector3) -> void:
	var visual := $StormDragonVisual as Node3D
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	var direction := global_position - origin
	if direction.length_squared() > .001:
		visual.rotation.y = atan2(direction.x, direction.z)
	visual.position = origin - global_position + Vector3(0, .04, 0)
	var start := visual.position
	_move_tween = create_tween()
	_move_tween.tween_method(func(t: float) -> void:
		visual.position = start.lerp(Vector3(0, .04, 0), t) + Vector3.UP * sin(t * PI) * .30
	, 0.0, 1.0, .32)

func play_spirit_pulse(target_position: Vector3) -> void:
	_flare = 1.5
	var visual := $StormDragonVisual as Node3D
	var direction := target_position - global_position
	if direction.length_squared() > .001:
		visual.rotation.y = atan2(direction.x, direction.z)
	var start := visual.to_global(Vector3(0, 2.02, .58))
	var end := target_position + Vector3.UP * 1.15
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_usec() + unit_number * 977
	_lash(start, end, rng)
	_impact(end)
	var flash := OmniLight3D.new()
	flash.light_color = Color("8fe4ff")
	flash.light_energy = 2.2
	flash.omni_range = 2.4
	flash.shadow_enabled = false
	get_parent().add_child(flash)
	flash.global_position = end
	var fade := flash.create_tween()
	fade.tween_property(flash, "light_energy", 0.0, .4)
	fade.tween_callback(flash.queue_free)

func _lash(start: Vector3, end: Vector3, rng: RandomNumberGenerator) -> void:
	var direction := (end - start).normalized()
	var side := direction.cross(Vector3.UP)
	if side.length_squared() < .01:
		side = direction.cross(Vector3.RIGHT)
	side = side.normalized()
	var lift := direction.cross(side).normalized()
	var points: Array[Vector3] = [start]
	var segments := 11
	for i in range(1, segments):
		var t := float(i) / segments
		var envelope := sin(t * PI)
		var p := start.lerp(end, t)
		var zigzag := 1.0 if i % 2 == 0 else -1.0
		p += side * zigzag * rng.randf_range(.16, .40) * envelope
		p += lift * zigzag * rng.randf_range(.02, .15) * envelope
		points.append(p)
	points.append(end)
	# A soft additive sheath surrounds a white-hot core.
	_spawn_bolt(points, .105, _arc_material(Color("8fe4ff"), Color("2f8fff"), .34, true), .22)
	_spawn_bolt(points, .044, _arc_material(Color("8fe8ff"), Color("2f9fff"), 1.0, false), .32)
	for branch in 3:
		var origin := points[2 + branch * 3]
		var fork := side * (1.0 if branch % 2 == 0 else -1.0) + lift * rng.randf_range(-.6, .6) + direction * .4
		var tip := origin + fork.normalized() * rng.randf_range(.35, .62)
		var bolt_points: Array[Vector3] = [origin, origin.lerp(tip, .5) + side * rng.randf_range(-.14, .14) + lift * rng.randf_range(-.10, .10), tip]
		_spawn_bolt(bolt_points, .026, _arc_material(Color("76dfff"), Color("1f9fff"), .95, false), .30)
	# Sparks scatter off the lash and linger for a moment.
	for i in 9:
		var spark_pos := points[2 + i]
		var spark := MeshInstance3D.new()
		var gem := SphereMesh.new()
		gem.radius = .024
		gem.height = .05
		gem.radial_segments = 4
		gem.rings = 2
		spark.mesh = gem
		var spark_mat := _arc_material(Color("e6fdff"), Color("79dcff"), 1.0, true)
		spark.material_override = spark_mat
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(spark)
		spark.global_position = spark_pos
		var drift := side * rng.randf_range(-.22, .22) + lift * rng.randf_range(-.18, .18) + direction * rng.randf_range(.05, .22)
		var spark_tween := spark.create_tween()
		spark_tween.tween_property(spark, "global_position", spark_pos + drift, .28)
		spark_tween.parallel().tween_property(spark, "scale", Vector3(.2, .2, .2), .28)
		spark_tween.parallel().tween_property(spark_mat, "albedo_color:a", 0.0, .28)
		spark_tween.tween_callback(spark.queue_free)

func _spawn_bolt(points: Array[Vector3], radius: float, mat: StandardMaterial3D, life: float) -> void:
	var bolt := MeshInstance3D.new()
	bolt.name = "ThunderWhip"
	bolt.mesh = _tube_mesh(points, radius)
	var bolt_mat := mat
	bolt.material_override = bolt_mat
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(bolt)
	var tween := bolt.create_tween()
	tween.tween_interval(.04)
	tween.tween_property(bolt_mat, "albedo_color:a", 0.0, life)
	tween.tween_callback(bolt.queue_free)

func _impact(target: Vector3) -> void:
	var pulse := MeshInstance3D.new()
	pulse.name = "ThunderImpact"
	var ring := TorusMesh.new()
	ring.inner_radius = .34
	ring.outer_radius = .43
	ring.rings = 32
	ring.ring_segments = 6
	pulse.mesh = ring
	var glow := _arc_material(Color("76e6ff"), Color("2fbaff"), .80, true)
	pulse.material_override = glow
	pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(pulse)
	pulse.global_position = target + Vector3.DOWN * .95
	pulse.hide()
	var impact := pulse.create_tween()
	impact.tween_interval(.10)
	impact.tween_callback(pulse.show)
	impact.tween_property(pulse, "scale", Vector3(3.2, 1.0, 3.2), .38)
	impact.parallel().tween_property(glow, "albedo_color:a", 0.0, .40)
	impact.tween_callback(pulse.queue_free)
	# Short radial arcs crack outward from the struck hex.
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_usec() + 313
	for i in 8:
		var a := TAU * i / 8 + rng.randf_range(-.2, .2)
		var origin := target + Vector3.DOWN * .82
		var tip := origin + Vector3(cos(a) * rng.randf_range(.38, .70), rng.randf_range(.02, .22), sin(a) * rng.randf_range(.38, .70))
		var arc_points: Array[Vector3] = [origin, origin.lerp(tip, .5) + Vector3(rng.randf_range(-.10, .10), rng.randf_range(.06, .16), rng.randf_range(-.10, .10)), tip]
		_spawn_bolt(arc_points, .018, _arc_material(Color("d8f8ff"), Color("5ec8ff"), .95, true), .34)

func _arc_material(core: Color, glow_color: Color, alpha := 1.0, additive := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(core, alpha)
	if additive:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.emission_enabled = true
	mat.emission = glow_color
	mat.emission_energy_multiplier = 4.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

# A cheap faceted tube; branches and the main lash share the same builder.
func _tube_mesh(points: Array[Vector3], radius: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SIDES := 5
	for i in range(points.size() - 1):
		var tangent := (points[i + 1] - points[i]).normalized()
		var side := Vector3.RIGHT.slide(tangent).normalized()
		if side.length_squared() < .01:
			side = Vector3.UP.slide(tangent).normalized()
		var up := tangent.cross(side).normalized()
		var taper_a := 1.0 - float(i) / maxf(1.0, float(points.size() - 1)) * .45
		var taper_b := 1.0 - float(i + 1) / maxf(1.0, float(points.size() - 1)) * .45
		for j in SIDES:
			var a := TAU * j / SIDES
			var b := TAU * (j + 1) / SIDES
			var va := side * cos(a) * radius * taper_a + up * sin(a) * radius * taper_a
			var vb := side * cos(b) * radius * taper_a + up * sin(b) * radius * taper_a
			var wa := side * cos(a) * radius * taper_b + up * sin(a) * radius * taper_b
			var wb := side * cos(b) * radius * taper_b + up * sin(b) * radius * taper_b
			for p in [points[i] + va, points[i + 1] + wa, points[i + 1] + wb, points[i] + va, points[i + 1] + wb, points[i] + vb]:
				st.add_vertex(p)
	st.generate_normals()
	return st.commit() as ArrayMesh
