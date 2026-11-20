@tool
class_name LanternSpirit
extends PlaceholderUnit
## Lantern soul with a floating paper body and independent silk / wisp motion.
const WISP_BASE_HEIGHTS := [1.10, .76]

const PULSE_START := Vector3(0, 1.35, 0)
const PULSE_END := Vector3(0, 1.1, 0)
const PULSE_RADIUS := 0.18
const PULSE_HEIGHT := 0.48
const PULSE_FLIGHT_TIME := 0.22
const PULSE_ARC := 0.45
const PULSE_SPIN := TAU
const IMPACT_INNER_RADIUS := 0.38
const IMPACT_OUTER_RADIUS := 0.47
const IMPACT_HEIGHT := 0.2
const IMPACT_DELAY := 0.22
const IMPACT_DURATION := 0.4
const IMPACT_SCALE := Vector3(2.8, 1.0, 2.8)

var _time := 0.0
var _flare := 0.0
var _body: Node3D
var _tassel: Node3D
var _wisps: Array[Node3D] = []
var _streamers: Array[Node3D] = []
var _inner_light: OmniLight3D

func display_name() -> String:
	return "%s Lantern %02d" % [team_name(), unit_number]

func _ready() -> void:
	super._ready()
	_time = unit_number * 1.7 + float(team) * 2.4
	var visual := $LanternVisual as Node3D
	_body = visual.get_node("FloatingBody") as Node3D
	_tassel = _body.get_node("Tassel") as Node3D
	_inner_light = _body.get_node("InnerLight") as OmniLight3D
	for i in WISP_BASE_HEIGHTS.size():
		_wisps.append(visual.get_node("Wisp%d" % i) as Node3D)
		_streamers.append(_body.get_node("Streamer%d" % i) as Node3D)

func _process(delta: float) -> void:
	_time += delta
	_flare = move_toward(_flare, 0.0, delta * 3.0)
	_body.position.y = sin(_time * 1.8) * .065
	_body.rotation.z = sin(_time * 1.2) * .045
	_body.rotation.y = sin(_time * .65) * .09
	_tassel.rotation.z = sin(_time * 2.2) * .09
	for i in _wisps.size():
		var wisp := _wisps[i]
		wisp.position.y = WISP_BASE_HEIGHTS[i] + sin(_time * 2.8 + i * PI) * .10
		wisp.rotation.y = _time * .5
		_streamers[i].rotation.z = sin(_time * 1.9 + i) * .08
	_inner_light.light_energy = .65 + sin(_time * 7.0) * .055 + _flare

func play_spirit_pulse(target_position: Vector3) -> void:
	_flare = 1.5
	# Effects live on the encounter so a lethal hit cannot delete their tweens.
	CombatEffects.play_projectile(
		get_parent(),
		global_position + PULSE_START,
		target_position + PULSE_END,
		SpiritPalette.LANTERN_FLAME,
		PULSE_RADIUS,
		PULSE_HEIGHT,
		PULSE_FLIGHT_TIME,
		PULSE_ARC,
		PULSE_SPIN,
		"LanternFirebolt"
	)
	CombatEffects.play_impact_ring(
		get_parent(),
		target_position,
		SpiritPalette.LANTERN_IMPACT,
		IMPACT_INNER_RADIUS,
		IMPACT_OUTER_RADIUS,
		CombatEffects.IMPACT_RINGS,
		CombatEffects.IMPACT_RING_SEGMENTS,
		IMPACT_HEIGHT,
		IMPACT_DELAY,
		IMPACT_DURATION,
		IMPACT_SCALE,
		"LanternImpact"
	)
