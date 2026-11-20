extends RefCounted
## Shared runtime projectile and impact-ring effects.
## Callers override the named tuning defaults with an options dictionary.

const PROJECTILE_RADIUS := 0.16
const PROJECTILE_HEIGHT := 0.32
const PROJECTILE_FLIGHT_TIME := 0.22
const PROJECTILE_ARC_HEIGHT := 0.0
const PROJECTILE_SPIN := 0.0

const IMPACT_INNER_RADIUS := 0.48
const IMPACT_OUTER_RADIUS := 0.62
const IMPACT_RINGS := 24
const IMPACT_RING_SEGMENTS := 6
const IMPACT_HEIGHT := 0.2
const IMPACT_DELAY := 0.0
const IMPACT_DURATION := 0.65
const IMPACT_SCALE := Vector3(3.0, 1.0, 3.0)

static func unshaded_material(color: Color, title := "") -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = title
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material

static func transparent_unshaded_material(color: Color, title := "") -> StandardMaterial3D:
	var material := unshaded_material(color, title)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

static func ring_mesh(inner_radius: float, outer_radius: float, rings: int, ring_segments: int) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = rings
	mesh.ring_segments = ring_segments
	return mesh

static func play_projectile(
	parent: Node,
	from: Vector3,
	to: Vector3,
	color: Color,
	radius := PROJECTILE_RADIUS,
	height := PROJECTILE_HEIGHT,
	flight_time := PROJECTILE_FLIGHT_TIME,
	arc := PROJECTILE_ARC_HEIGHT,
	spin := PROJECTILE_SPIN,
	effect_name := "SpiritBolt"
) -> void:
	var bolt := MeshInstance3D.new()
	bolt.name = effect_name
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = height
	bolt.mesh = sphere
	bolt.material_override = unshaded_material(color)
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(bolt)
	bolt.global_position = from
	var flight := bolt.create_tween()
	flight.tween_method(func(t: float) -> void:
		if not is_instance_valid(bolt):
			return
		bolt.global_position = from.lerp(to, t) + Vector3.UP * sin(t * PI) * arc
		if spin != 0.0:
			bolt.rotation.z = t * spin
	, 0.0, 1.0, flight_time)
	flight.tween_callback(bolt.queue_free)

static func play_impact_ring(
	parent: Node,
	position: Vector3,
	color: Color,
	inner_radius := IMPACT_INNER_RADIUS,
	outer_radius := IMPACT_OUTER_RADIUS,
	rings := IMPACT_RINGS,
	ring_segments := IMPACT_RING_SEGMENTS,
	height := IMPACT_HEIGHT,
	delay := IMPACT_DELAY,
	duration := IMPACT_DURATION,
	target_scale := IMPACT_SCALE,
	effect_name := "SpiritImpact"
) -> void:
	var pulse := MeshInstance3D.new()
	pulse.name = effect_name
	pulse.mesh = ring_mesh(inner_radius, outer_radius, rings, ring_segments)
	var material := transparent_unshaded_material(color)
	pulse.material_override = material
	pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(pulse)
	pulse.global_position = position + Vector3.UP * height
	var impact := pulse.create_tween()
	if delay > 0.0:
		pulse.hide()
		impact.tween_interval(delay)
		impact.tween_callback(pulse.show)
	impact.tween_property(pulse, "scale", target_scale, duration)
	impact.parallel().tween_property(material, "albedo_color:a", 0.0, duration)
	impact.tween_callback(pulse.queue_free)
