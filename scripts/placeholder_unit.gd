@tool
class_name PlaceholderUnit
extends StaticBody3D
## Shared tactical pawn. Team identity stays visible while selected.
const SpiritPalette = preload("res://scripts/spirit_palette.gd")

enum Team { JADE, EMBER }
const MAX_HEALTH := 3
const TEAM_NAMES := ["Jade", "Ember"]
const TEAM_COLORS := SpiritPalette.TEAM_COLORS

var _team_material: StandardMaterial3D
var _team_material_team := -1

static func name_for(value: int) -> String:
	if value < 0 or value >= TEAM_NAMES.size():
		return "Unknown"
	return String(TEAM_NAMES[value])

static func color_for(value: int) -> Color:
	if value < 0 or value >= TEAM_COLORS.size():
		return Color.WHITE
	return TEAM_COLORS[value]

static func other_team(value: Team) -> Team:
	return Team.EMBER if value == Team.JADE else Team.JADE

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
var health := MAX_HEALTH

func _ready() -> void:
	_update_identity()
	set_selected(false)

func team_name() -> String:
	return name_for(team)

func team_color() -> Color:
	return color_for(team)

func display_name() -> String:
	return "%s %02d" % [team_name(), unit_number]

func ability_name() -> String:
	return "Spirit Pulse"

func play_move(_origin: Vector3) -> void:
	pass

func _update_identity() -> void:
	var material := _material_for_team(team)
	$Body.material_override = material
	$TeamBase.material_override = material
	$Badge.text = display_name().to_upper()
	$Badge.modulate = team_color()
	$Health.text = "%d / %d HP" % [health, MAX_HEALTH]

func _material_for_team(value: Team) -> StandardMaterial3D:
	if _team_material == null or _team_material_team != value:
		_team_material = StandardMaterial3D.new()
		_team_material.resource_name = "%sTeamMaterial" % name_for(value)
		_team_material.albedo_color = color_for(value)
		_team_material.roughness = 0.55
		_team_material.emission_enabled = true
		_team_material.emission = color_for(value)
		_team_material.emission_energy_multiplier = 0.25
		_team_material_team = value
	return _team_material

func take_damage(amount: int) -> void:
	health = maxi(0, health - maxi(0, amount))
	$Health.text = "%d / %d HP" % [health, MAX_HEALTH]
	if health == 0:
		collision_layer = 0
		hide()

func set_selected(value: bool) -> void:
	selected = value
	$SelectionRing.visible = value
	$SelectionMarker.visible = value

func reset_actions() -> void:
	has_moved = false
	ability_used = false

func play_spirit_pulse(target_position: Vector3) -> void:
	var bolt := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	bolt.mesh = sphere
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = team_color()
	bolt.material_override = glow
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(bolt)
	bolt.global_position = global_position + Vector3.UP
	var flight := bolt.create_tween()
	flight.tween_property(bolt, "global_position", target_position + Vector3.UP, 0.22)
	flight.tween_callback(bolt.queue_free)
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
	pulse.global_position = target_position + Vector3(0, 0.2, 0)
	var tween := pulse.create_tween().set_parallel(true)
	tween.tween_property(pulse, "scale", Vector3(3.0, 1.0, 3.0), 0.65)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.65)
	tween.chain().tween_callback(pulse.queue_free)
