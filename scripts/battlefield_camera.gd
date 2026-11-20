extends Node3D
## Angled battlefield view. Pan and orbit share a movable, bounded focus point.
@export_range(4.0, 40.0) var minimum_zoom := 10.0
@export_range(20.0, 60.0) var maximum_zoom := 58.0
@export var pan_speed := 10.0
@export var fast_pan_multiplier := 2.0
@export var pan_limits := Vector2(18.0, 18.0)
@export var orbit_sensitivity := 0.006
@export var keyboard_rotation_speed := 1.5
@onready var camera: Camera3D = $Camera3D

const DEFAULT_FOCUS := Vector3(0, 1.0, -1.8)
const DEFAULT_YAW := 0.57
const DEFAULT_ELEVATION := 0.63
const DEFAULT_ZOOM := 39.0
const DEFAULT_FAR := 150.0
const DEFAULT_CAMERA_POSITION := Vector3(24.3, 33.0, 37.4)
const ORBIT_DISTANCE := 54.0
const MIN_ELEVATION := 0.55
const MAX_ELEVATION := 1.25
const ZOOM_STEP := 1.1

var focus := DEFAULT_FOCUS
var yaw := DEFAULT_YAW
var elevation := DEFAULT_ELEVATION
var panning := false
var rotating := false
var window_focused := true

func _ready() -> void:
	reset_view()

func _process(delta: float) -> void:
	if not window_focused:
		return
	var movement := Input.get_vector("camera_left", "camera_right", "camera_forward", "camera_back")
	var turn := Input.get_axis("camera_rotate_left", "camera_rotate_right")
	if movement.is_zero_approx() and is_zero_approx(turn):
		return
	yaw = wrapf(yaw + turn * keyboard_rotation_speed * delta, -PI, PI)
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var back := Vector3(sin(yaw), 0, cos(yaw))
	var speed := pan_speed * camera.size / DEFAULT_ZOOM
	if Input.is_action_pressed("camera_fast_pan"):
		speed *= fast_pan_multiplier
	focus += (right * movement.x + back * movement.y) * speed * delta
	_clamp_focus()
	_update_camera()

func _input(event: InputEvent) -> void:
	# Releases must end a drag even when the pointer is over an interface control.
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			panning = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_reset"):
		reset_view()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				panning = true
				rotating = false
			MOUSE_BUTTON_RIGHT:
				rotating = true
				panning = false
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				var direction := -1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
				camera.size = clampf(camera.size * pow(ZOOM_STEP, direction * event.factor), minimum_zoom, maximum_zoom)
			_:
				return
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		panning = panning and (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0
		rotating = rotating and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0
		if panning:
			_pan_drag(event.position - event.relative, event.position)
		elif rotating:
			yaw = wrapf(yaw - event.relative.x * orbit_sensitivity, -PI, PI)
			elevation = clampf(elevation + event.relative.y * orbit_sensitivity, MIN_ELEVATION, MAX_ELEVATION)
			_update_camera()
		else:
			return
		get_viewport().set_input_as_handled()

func _pan_drag(previous: Vector2, current: Vector2) -> void:
	# Ground intersections keep the grabbed point under the cursor at any zoom,
	# angle or window size. No collision geometry is needed to pan over water.
	var plane := Plane(Vector3.UP, to_global(focus).y)
	var start = plane.intersects_ray(camera.project_ray_origin(previous), camera.project_ray_normal(previous))
	var end = plane.intersects_ray(camera.project_ray_origin(current), camera.project_ray_normal(current))
	if start == null or end == null:
		return
	focus += to_local(start) - to_local(end)
	_clamp_focus()
	_update_camera()

func _clamp_focus() -> void:
	focus.x = clampf(focus.x, DEFAULT_FOCUS.x - pan_limits.x, DEFAULT_FOCUS.x + pan_limits.x)
	focus.z = clampf(focus.z, DEFAULT_FOCUS.z - pan_limits.y, DEFAULT_FOCUS.z + pan_limits.y)
	focus.y = DEFAULT_FOCUS.y

func reset_view() -> void:
	focus = DEFAULT_FOCUS
	yaw = DEFAULT_YAW
	elevation = DEFAULT_ELEVATION
	camera.size = clampf(DEFAULT_ZOOM, minimum_zoom, maximum_zoom)
	panning = false
	rotating = false
	_update_camera()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		window_focused = false
		panning = false
		rotating = false
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		window_focused = true

func _update_camera() -> void:
	camera.position = focus + Vector3(sin(yaw) * cos(elevation), sin(elevation), cos(yaw) * cos(elevation)) * ORBIT_DISTANCE
	camera.look_at(to_global(focus))
