class_name SkirmishController
extends Node3D
## Local hot-seat turns, authoritative action checks, and physics-step picking.
signal selection_changed(unit: PlaceholderUnit)
signal state_changed

const HexGrid = preload("res://scripts/hex_grid.gd")
const SpiritPalette = preload("res://scripts/spirit_palette.gd")

const MOVE_RANGE := 3
const ATTACK_RANGE := 3
const ATTACK_DAMAGE := 1

const NO_WINNER := -1
const GROUND_LAYER := 1
const UNIT_LAYER := 2
const PICK_MASK := GROUND_LAYER | UNIT_LAYER

const HIGHLIGHT_INNER_RADIUS := 0.58
const HIGHLIGHT_OUTER_RADIUS := 0.65
const HIGHLIGHT_RINGS := 24
const HIGHLIGHT_RING_SEGMENTS := 6
const HIGHLIGHT_HEIGHT_OFFSET := 0.04

@export_node_path("Node3D") var battlefield_path: NodePath = ^"../BattlefieldGrid"

var selected_unit: PlaceholderUnit
var active_team: PlaceholderUnit.Team = PlaceholderUnit.Team.JADE
var turn_number := 1
var feedback := ""
var units: Array[PlaceholderUnit] = []
var tiles: Dictionary[Vector2i, Node3D] = {}
var unit_tiles: Dictionary[PlaceholderUnit, Vector2i] = {}
var _highlights: Dictionary[Vector2i, MeshInstance3D] = {}
var _highlight_mesh: TorusMesh
var _highlight_move_material: StandardMaterial3D
var _highlight_target_material: StandardMaterial3D
var _pending_clicks: Array[Vector2] = []
var targeting_attack := false
var battle_over := false
# NO_WINNER represents no winner (including an empty encounter).
var winner := NO_WINNER
var _restarting := false

func _ready() -> void:
	_build_highlight_resources()
	var battlefield := get_node_or_null(battlefield_path)
	if battlefield == null:
		push_error("SkirmishController needs a battlefield at %s." % battlefield_path)
		return
	feedback = "Select a %s unit to begin." % active_team_name()
	for child in battlefield.get_children():
		if not child is Node3D or not HexGrid.has_cell(child):
			continue
		var tile := child as Node3D
		var cell := HexGrid.cell_of(tile)
		tiles[cell] = tile
		_highlights[cell] = _make_highlight(tile)
	if tiles.is_empty():
		push_error("SkirmishController found no hex tiles under %s." % battlefield_path)
		return
	for child in get_children():
		if child is PlaceholderUnit:
			var unit := child as PlaceholderUnit
			units.append(unit)
			var closest := Vector2i.ZERO
			var distance := INF
			for cell: Vector2i in tiles:
				var candidate := unit.global_position.distance_squared_to(tile_position(cell))
				if candidate < distance:
					distance = candidate
					closest = cell
			unit_tiles[unit] = closest
			unit.global_position = tile_position(closest)
			unit.reset_actions()
	_check_battle_result()

func _build_highlight_resources() -> void:
	_highlight_mesh = TorusMesh.new()
	_highlight_mesh.inner_radius = HIGHLIGHT_INNER_RADIUS
	_highlight_mesh.outer_radius = HIGHLIGHT_OUTER_RADIUS
	_highlight_mesh.rings = HIGHLIGHT_RINGS
	_highlight_mesh.ring_segments = HIGHLIGHT_RING_SEGMENTS
	_highlight_move_material = _highlight_material(SpiritPalette.HIGHLIGHT_MOVE, "MoveHighlight")
	_highlight_target_material = _highlight_material(SpiritPalette.HIGHLIGHT_TARGET, "TargetHighlight")

func _highlight_material(color: Color, title: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = title
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material

func _make_highlight(tile: Node3D) -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	marker.mesh = _highlight_mesh
	marker.material_override = _highlight_move_material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tile.add_child(marker)
	marker.position.y = HexGrid.surface_height(tile) + HIGHLIGHT_HEIGHT_OFFSET
	marker.visible = false
	return marker

func active_team_name() -> String:
	return PlaceholderUnit.name_for(active_team)

func can_act(unit: PlaceholderUnit) -> bool:
	return not battle_over and is_instance_valid(unit) and unit in units and unit.health > 0 and unit.team == active_team

func result_text() -> String:
	if winner == NO_WINNER:
		return "Draw — no surviving units"
	return "%s wins!" % PlaceholderUnit.name_for(winner)

func _team_has_survivors(team: PlaceholderUnit.Team) -> bool:
	for unit in units:
		if unit.health > 0 and unit.team == team:
			return true
	return false

func _check_battle_result() -> void:
	if battle_over:
		return
	var jade_alive := _team_has_survivors(PlaceholderUnit.Team.JADE)
	var ember_alive := _team_has_survivors(PlaceholderUnit.Team.EMBER)
	if jade_alive and ember_alive:
		return
	battle_over = true
	winner = PlaceholderUnit.Team.JADE if jade_alive else (PlaceholderUnit.Team.EMBER if ember_alive else NO_WINNER)
	targeting_attack = false
	_pending_clicks.clear()
	if is_instance_valid(selected_unit):
		selected_unit.set_selected(false)
	selected_unit = null
	feedback = result_text()
	selection_changed.emit(null)
	_refresh()

func restart_encounter() -> void:
	if not battle_over or _restarting:
		return
	_restarting = true
	var error := get_tree().reload_current_scene()
	if error != OK:
		_restarting = false
		feedback = "Could not restart the encounter. Please try again."
		state_changed.emit()

func can_use_ability(unit: PlaceholderUnit) -> bool:
	return can_act(unit) and not unit.ability_used

func hex_distance(a: Vector2i, b: Vector2i) -> int:
	return HexGrid.distance(a, b)

func available_targets(unit: PlaceholderUnit) -> Array[PlaceholderUnit]:
	var result: Array[PlaceholderUnit] = []
	if not can_use_ability(unit):
		return result
	for target in units:
		if target.team != unit.team and target.health > 0 and hex_distance(unit_tiles[unit], unit_tiles[target]) <= ATTACK_RANGE:
			result.append(target)
	return result

func try_attack(unit: PlaceholderUnit, target: PlaceholderUnit) -> bool:
	if battle_over:
		return false
	if not target in available_targets(unit):
		feedback = "Choose an enemy within %d hexes with an unused attack." % ATTACK_RANGE
		state_changed.emit()
		return false
	unit.ability_used = true
	unit.play_spirit_pulse(target.global_position)
	target.take_damage(ATTACK_DAMAGE)
	feedback = "%s hit %s for %d damage." % [unit.display_name(), target.display_name(), ATTACK_DAMAGE]
	if target.health == 0:
		feedback += " Defeated!"
		units.erase(target)
		unit_tiles.erase(target)
		if selected_unit == target:
			target.set_selected(false)
			selected_unit = null
			selection_changed.emit(null)
		target.queue_free()
	targeting_attack = false
	_check_battle_result()
	_refresh()
	return true

func available_moves(unit: PlaceholderUnit) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not can_act(unit) or unit.has_moved:
		return result
	# Breadth-first search counts the shortest walk around occupied hexes.
	var origin := unit_tiles[unit]
	var frontier: Array[Vector2i] = [origin]
	var distances: Dictionary[Vector2i, int] = {origin: 0}
	var occupied := unit_tiles.values()
	var index := 0
	while index < frontier.size():
		var current := frontier[index]
		index += 1
		if distances[current] >= MOVE_RANGE:
			continue
		for offset: Vector2i in HexGrid.AXIAL_NEIGHBORS:
			var cell := current + offset
			if not tiles.has(cell) or cell in occupied or distances.has(cell):
				continue
			distances[cell] = distances[current] + 1
			frontier.append(cell)
			result.append(cell)
	return result

func tile_position(cell: Vector2i) -> Vector3:
	return HexGrid.tile_position(tiles[cell])

func try_move(unit: PlaceholderUnit, cell: Vector2i) -> bool:
	if battle_over:
		return false
	if not cell in available_moves(unit):
		if not can_act(unit):
			feedback = "Select a %s unit to act." % active_team_name()
		elif unit.has_moved:
			feedback = "%s has already moved this turn." % unit.display_name()
		else:
			feedback = "Choose a highlighted hex within %d steps." % MOVE_RANGE
		state_changed.emit()
		return false
	var origin := unit.global_position
	unit_tiles[unit] = cell
	unit.global_position = tile_position(cell)
	unit.play_move(origin)
	unit.has_moved = true
	feedback = "%s moved." % unit.display_name()
	_refresh()
	return true

func use_selected_ability() -> bool:
	if not can_use_ability(selected_unit):
		return false
	targeting_attack = not targeting_attack
	if targeting_attack:
		feedback = "Click a red-ringed enemy to deal %d damage." % ATTACK_DAMAGE
		if available_targets(selected_unit).is_empty():
			feedback = "No enemies within %d hexes. Cancel to move." % ATTACK_RANGE
	else:
		feedback = "Attack cancelled. Click a gold-ringed hex to move."
	_refresh()
	return true

func end_turn() -> void:
	if battle_over:
		return
	# Discard clicks queued before the handoff so they cannot act for the new team.
	_pending_clicks.clear()
	active_team = PlaceholderUnit.other_team(active_team)
	turn_number += 1
	for unit in units:
		if unit.team == active_team:
			unit.reset_actions()
	select_unit(null)
	feedback = "%s's turn. Select a unit." % active_team_name()
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if battle_over:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pending_clicks.append(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
		_pending_clicks.clear()
		select_unit(null)
		get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	# A lethal attack may clear the queue during this loop.
	while not _pending_clicks.is_empty() and not battle_over:
		var screen_position: Vector2 = _pending_clicks.pop_front()
		var camera := get_viewport().get_camera_3d()
		if camera == null:
			continue
		var origin := camera.project_ray_origin(screen_position)
		var end := origin + camera.project_ray_normal(screen_position) * camera.far
		var query := PhysicsRayQueryParameters3D.create(origin, end, PICK_MASK)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		var collider := hit.get("collider") as Node
		if targeting_attack:
			if collider is PlaceholderUnit:
				try_attack(selected_unit, collider)
			else:
				feedback = "Click a red-ringed enemy, or cancel the attack."
				state_changed.emit()
		elif collider is PlaceholderUnit:
			select_unit(collider)
		elif collider != null and HexGrid.has_cell(collider.get_parent()) and can_act(selected_unit):
			try_move(selected_unit, HexGrid.cell_of(collider.get_parent()))
		else:
			select_unit(null)
	_pending_clicks.clear()

func select_unit(unit: PlaceholderUnit) -> void:
	if battle_over:
		return
	targeting_attack = false
	if is_instance_valid(unit) and (not unit in units or unit.health <= 0):
		unit = null
	if selected_unit == unit:
		_refresh()
		return
	if is_instance_valid(selected_unit):
		selected_unit.set_selected(false)
	selected_unit = unit
	if is_instance_valid(selected_unit):
		selected_unit.set_selected(true)
	feedback = "Select a %s unit." % active_team_name()
	if unit != null:
		if not can_act(unit):
			feedback = "This unit is waiting for its team's turn."
		elif unit.has_moved and unit.ability_used:
			feedback = "All actions used. Select another unit or end turn."
		elif unit.has_moved:
			feedback = "Move used. %s attack is still available." % unit.ability_name()
		elif available_moves(unit).is_empty():
			feedback = "No reachable empty hexes to move to."
		else:
			feedback = "Click a highlighted hex to move up to %d steps." % MOVE_RANGE
	selection_changed.emit(selected_unit)
	_refresh()

func _refresh() -> void:
	var moves := available_moves(selected_unit)
	var target_cells: Array[Vector2i] = []
	if targeting_attack:
		for target in available_targets(selected_unit):
			target_cells.append(unit_tiles[target])
	var highlight_material := _highlight_target_material if targeting_attack else _highlight_move_material
	for cell: Vector2i in _highlights:
		var marker := _highlights[cell]
		marker.visible = cell in target_cells if targeting_attack else cell in moves
		marker.material_override = highlight_material
	state_changed.emit()
