extends Node3D
## Single-unit inspection for either opposing team. Pick in the physics step.
signal selection_changed(unit: PlaceholderUnit)

var selected_unit: PlaceholderUnit
var _pending_clicks: Array[Vector2] = []

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
		# Include the board (layer 1) so its surface can occlude a unit.
		var query := PhysicsRayQueryParameters3D.create(origin, end, 3)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		select_unit(hit.get("collider") as PlaceholderUnit)
	_pending_clicks.clear()

func select_unit(unit: PlaceholderUnit) -> void:
	if selected_unit == unit:
		return
	if is_instance_valid(selected_unit):
		selected_unit.set_selected(false)
	selected_unit = unit
	if is_instance_valid(selected_unit):
		selected_unit.set_selected(true)
	selection_changed.emit(selected_unit)
