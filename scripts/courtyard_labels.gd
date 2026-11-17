extends CanvasLayer
## Runtime presentation only; the battlefield stays clear in the 3D editor.
var selection_label: Label
var turn_label: Label
var actions_label: Label
var feedback_label: Label
var ability_button: Button
var end_turn_button: Button
var skirmish: SkirmishController

func _ready() -> void:
	var frame := Control.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	add_label(frame, "S P I R I T   W A R S", Vector2(38, 27), 14, Color("cbb58e"))
	add_label(frame, "The Moonwell", Vector2(36, 49), 34, Color("e5e6dc"))
	add_label(frame, "S H R I N E   C O U R T Y A R D", Vector2(39, 94), 11, Color("a0bcc4"))
	var line := ColorRect.new()
	line.position = Vector2(39, 122)
	line.size = Vector2(48, 2)
	line.color = Color("cbb58e")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(line)
	var footer := Label.new()
	footer.text = "WASD / ARROWS / DRAG MMB  Pan     /     SHIFT  Fast pan\nDRAG RMB / Q E  Rotate     /     SCROLL  Zoom     /     R  Reset view"
	footer.add_theme_font_size_override("font_size", 13)
	footer.add_theme_color_override("font_color", Color("a7bbc3"))
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.position = Vector2(38, -64)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(footer)
	var count := Label.new()
	count.text = "7 × 7   /   49 HEXES"
	count.add_theme_font_size_override("font_size", 13)
	count.add_theme_color_override("font_color", Color("cbb58e"))
	count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	count.position = Vector2(-178, -43)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(count)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-350, 30)
	panel.custom_minimum_size = Vector2(312, 0)
	# Interactive panel blocks clicks from reaching the battlefield.
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.065, 0.09, 0.92)
	style.border_color = Color("52656d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	frame.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(rows)
	skirmish = get_parent().get_node("Skirmish")
	add_status_row(rows, "LOCAL PLAY  /  BOTH TEAMS", 12, Color("cbb58e"))
	turn_label = add_status_row(rows, "", 22, Color.WHITE)
	end_turn_button = Button.new()
	end_turn_button.name = "EndTurn"
	end_turn_button.custom_minimum_size.y = 42
	end_turn_button.pressed.connect(skirmish.end_turn)
	rows.add_child(end_turn_button)
	rows.add_child(HSeparator.new())
	selection_label = add_status_row(rows, "", 16, Color("ffe08a"))
	actions_label = add_status_row(rows, "", 14, Color("d6e1e2"))
	ability_button = Button.new()
	ability_button.name = "SpiritPulse"
	ability_button.custom_minimum_size.y = 40
	ability_button.tooltip_text = "Release a visible spirit burst. No damage yet.\nUses this unit's ability for the turn."
	ability_button.pressed.connect(skirmish.use_selected_ability)
	rows.add_child(ability_button)
	add_status_row(rows, "Spirit Pulse: a visible spirit burst.\nMove and ability in either order.", 13, Color("a7bbc3"))
	feedback_label = add_status_row(rows, "", 14, Color("ffe08a"))
	feedback_label.custom_minimum_size = Vector2(276, 48)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_status_row(rows, "Click unit to select / inspect\nGold rings: available moves\nEmpty space / Esc to clear", 13, Color("a7bbc3"))
	skirmish.state_changed.connect(_refresh_status)
	_refresh_status()

func _refresh_status() -> void:
	turn_label.text = "TURN %d  /  %s" % [skirmish.turn_number, skirmish.active_team_name().to_upper()]
	turn_label.modulate = Color("52e0c0") if skirmish.active_team == PlaceholderUnit.Team.JADE else Color("ff825e")
	end_turn_button.text = "End Turn  →  %s" % ("Ember" if skirmish.active_team == PlaceholderUnit.Team.JADE else "Jade")
	var unit := skirmish.selected_unit
	selection_label.text = "Selected: %s" % unit.display_name() if unit != null else "No unit selected"
	ability_button.disabled = not skirmish.can_use_ability(unit)
	ability_button.text = "Spirit Pulse" if unit == null or not unit.ability_used else "Spirit Pulse  /  Used"
	if unit == null:
		actions_label.text = "Each unit: 1 move + 1 ability"
	elif unit.team != skirmish.active_team:
		actions_label.text = "Waiting for %s's turn" % unit.team_name()
	else:
		actions_label.text = "Move: %s   /   Ability: %s" % ["used" if unit.has_moved else "ready", "used" if unit.ability_used else "ready"]
	feedback_label.text = skirmish.feedback

func add_status_row(parent: Control, text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func add_label(parent: Control, text: String, position: Vector2, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
