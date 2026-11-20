@tool
class_name PlaceholderUnit
extends StaticBody3D
## Shared tactical pawn. Team identity stays visible while selected.
const SpiritPalette = preload("res://scripts/spirit_palette.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")

const PULSE_START_HEIGHT := 1.0
const PULSE_END_HEIGHT := 1.0

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
	var start := global_position + Vector3.UP * PULSE_START_HEIGHT
	var end := target_position + Vector3.UP * PULSE_END_HEIGHT
	CombatEffects.play_projectile(get_parent(), start, end, team_color())
	CombatEffects.play_impact_ring(get_parent(), target_position, team_color())
