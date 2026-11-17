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
