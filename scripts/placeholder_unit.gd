@tool
class_name PlaceholderUnit
extends StaticBody3D
## Shared placeholder pawn. Team identity stays visible while selected.
enum Team { JADE, EMBER }

@export var team: Team = Team.JADE:
	set(value):
		team = value
		if is_node_ready():
			_update_identity()
@export_range(1, 99) var unit_number := 1:
	set(value):
		unit_number = value
		if is_node_ready():
			_update_identity()

var selected := false
var has_moved := false
var ability_used := false

func _ready() -> void:
	_update_identity()
	set_selected(false)

func team_name() -> String:
	return "Jade" if team == Team.JADE else "Ember"

func team_color() -> Color:
	return Color("52e0c0") if team == Team.JADE else Color("ff825e")

func display_name() -> String:
	return "%s %02d" % [team_name(), unit_number]

func _update_identity() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = team_color()
	material.roughness = 0.55
	material.emission_enabled = true
	material.emission = team_color()
	material.emission_energy_multiplier = 0.25
	$Body.material_override = material
	$TeamBase.material_override = material
	$Badge.text = display_name().to_upper()
	$Badge.modulate = team_color()

func set_selected(value: bool) -> void:
	selected = value
	$SelectionRing.visible = value
	$SelectionMarker.visible = value

func reset_actions() -> void:
	has_moved = false
	ability_used = false

func play_spirit_pulse() -> void:
	# Starter ability feedback; damage and combat rules are not implemented yet.
	var pulse := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.48
	ring.outer_radius = 0.62
	pulse.mesh = ring
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = team_color()
	pulse.material_override = material
	pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(pulse)
	pulse.global_position = global_position + Vector3(0, 0.2, 0)
	var tween := pulse.create_tween().set_parallel(true)
	tween.tween_property(pulse, "scale", Vector3(3.0, 1.0, 3.0), 0.65)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.65)
	tween.chain().tween_callback(pulse.queue_free)
