class_name SkirmishController
extends Node3D
## Local hot-seat turns, authoritative action checks, and physics-step picking.
signal selection_changed(unit: PlaceholderUnit)
signal state_changed

const NEIGHBORS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 1)]
const MOVE_RANGE := 3
const ATTACK_RANGE := 3
const ATTACK_DAMAGE := 1

var selected_unit: PlaceholderUnit
var active_team: PlaceholderUnit.Team = PlaceholderUnit.Team.JADE
var turn_number := 1
var feedback := "Select a Jade unit to begin."
var units: Array[PlaceholderUnit] = []
var tiles: Dictionary[Vector2i, Node3D] = {}
var unit_tiles: Dictionary[PlaceholderUnit, Vector2i] = {}
var _highlights: Dictionary[Vector2i, MeshInstance3D] = {}
var _pending_clicks: Array[Vector2] = []
var targeting_attack := false

func _ready() -> void:
	for tile: Node3D in get_parent().get_node("BattlefieldGrid").get_children():
		var cell := Vector2i(tile.get_meta("axial_q"), tile.get_meta("axial_r"))
		tiles[cell] = tile
		var marker := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.58
		ring.outer_radius = 0.65
		ring.rings = 24
		ring.ring_segments = 6
		marker.mesh = ring
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("ffe08a")
		marker.material_override = material
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tile.add_child(marker)
		marker.position.y = float(tile.get_meta("surface_height", 0.35)) + 0.04
		marker.visible = false
		_highlights[cell] = marker
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

func active_team_name() -> String:
	return "Jade" if active_team == PlaceholderUnit.Team.JADE else "Ember"

func can_act(unit: PlaceholderUnit) -> bool:
	return is_instance_valid(unit) and unit in units and unit.health > 0 and unit.team == active_team

func can_use_ability(unit: PlaceholderUnit) -> bool:
	return can_act(unit) and not unit.ability_used

func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var delta := a - b
	return maxi(absi(delta.x), maxi(absi(delta.y), absi(delta.x + delta.y)))

func available_targets(unit: PlaceholderUnit) -> Array[PlaceholderUnit]:
	var result: Array[PlaceholderUnit] = []
	if not can_use_ability(unit):
		return result
	for target in units:
		if target.team != unit.team and target.health > 0 and hex_distance(unit_tiles[unit], unit_tiles[target]) <= ATTACK_RANGE:
			result.append(target)
	return result

func try_attack(unit: PlaceholderUnit, target: PlaceholderUnit) -> bool:
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
		for offset: Vector2i in NEIGHBORS:
			var cell := current + offset
			if not tiles.has(cell) or cell in occupied or distances.has(cell):
				continue
			distances[cell] = distances[current] + 1
			frontier.append(cell)
			result.append(cell)
	return result

func tile_position(cell: Vector2i) -> Vector3:
	return tiles[cell].to_global(Vector3(0, float(tiles[cell].get_meta("surface_height", 0.35)), 0))

func try_move(unit: PlaceholderUnit, cell: Vector2i) -> bool:
	if not cell in available_moves(unit):
		if not can_act(unit):
			feedback = "Select a %s unit to act." % active_team_name()
		elif unit.has_moved:
			feedback = "%s has already moved this turn." % unit.display_name()
		else:
			feedback = "Choose a highlighted hex within %d steps." % MOVE_RANGE
		state_changed.emit()
		return false
	unit_tiles[unit] = cell
	unit.global_position = tile_position(cell)
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
	# Discard clicks queued before the handoff so they cannot act for the new team.
	_pending_clicks.clear()
	active_team = PlaceholderUnit.Team.EMBER if active_team == PlaceholderUnit.Team.JADE else PlaceholderUnit.Team.JADE
	turn_number += 1
	for unit in units:
		if unit.team == active_team:
			unit.reset_actions()
	select_unit(null)
	feedback = "%s's turn. Select a unit." % active_team_name()
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pending_clicks.append(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
		_pending_clicks.clear()
		select_unit(null)
		get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	for screen_position in _pending_clicks:
		var camera := get_viewport().get_camera_3d()
		if camera == null:
			continue
		var origin := camera.project_ray_origin(screen_position)
		var end := origin + camera.project_ray_normal(screen_position) * camera.far
		var query := PhysicsRayQueryParameters3D.create(origin, end, 3)
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
		elif collider != null and collider.get_parent().has_meta("axial_q") and can_act(selected_unit):
			var tile := collider.get_parent()
			try_move(selected_unit, Vector2i(tile.get_meta("axial_q"), tile.get_meta("axial_r")))
		else:
			select_unit(null)
	_pending_clicks.clear()

func select_unit(unit: PlaceholderUnit) -> void:
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
			feedback = "Move used. Spirit Pulse attack is still available."
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
	for cell: Vector2i in _highlights:
		_highlights[cell].visible = cell in target_cells if targeting_attack else cell in moves
		var material := _highlights[cell].material_override as StandardMaterial3D
		material.albedo_color = Color("ff625e") if targeting_attack else Color("ffe08a")
	state_changed.emit()
