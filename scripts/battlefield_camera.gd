extends Node3D
## Orbit the courtyard without modifying the authored scene.
@export_range(16.0, 40.0) var minimum_zoom := 18.0
@export_range(20.0, 50.0) var maximum_zoom := 34.0
@export var orbit_sensitivity := 0.006
@onready var camera: Camera3D = $Camera3D
var dragging := false
var yaw := 0.57
var elevation := 0.63
const TARGET := Vector3(0, 0.6, -0.6)

func _ready() -> void:
	_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = maxf(minimum_zoom, camera.size - 1.0)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = minf(maximum_zoom, camera.size + 1.0)
	if event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x * orbit_sensitivity
		elevation = clampf(elevation + event.relative.y * orbit_sensitivity, 0.42, 1.25)
		_update_camera()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		yaw = 0.57
		elevation = 0.63
		camera.size = 24.5
		_update_camera()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		dragging = false

func _update_camera() -> void:
	camera.position = TARGET + Vector3(sin(yaw) * cos(elevation), sin(elevation), cos(yaw) * cos(elevation)) * 34.0
	camera.look_at(TARGET)
