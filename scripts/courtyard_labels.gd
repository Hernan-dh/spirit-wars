extends CanvasLayer
## Runtime presentation only; the battlefield stays clear in the 3D editor.
var selection_label: Label
var turn_label: Label
var actions_label: Label
var feedback_label: Label
var ability_button: Button
var end_turn_button: Button
var result_overlay: ColorRect
var result_label: Label
var result_details: Label
var restart_button: Button
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
	var grid := get_parent().get_node("BattlefieldGrid")
	count.text = "%d × %d   /   %d HEXES" % [grid.get_meta("rows"), grid.get_meta("columns"), grid.get_child_count()]
	count.add_theme_font_size_override("font_size", 13)
	count.add_theme_color_override("font_color", Color("cbb58e"))
	count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	count.position = Vector2(-200, -43)
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
	ability_button.tooltip_text = "Choose an enemy within three hexes to deal one damage.\nOne attack per turn; move and attack in either order."
	ability_button.pressed.connect(skirmish.use_selected_ability)
	rows.add_child(ability_button)
	add_status_row(rows, "Attack: 1 damage / 3 hex range\nMove and attack in either order.", 13, Color("a7bbc3"))
	feedback_label = add_status_row(rows, "", 14, Color("ffe08a"))
	feedback_label.custom_minimum_size = Vector2(276, 48)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_status_row(rows, "Click unit to select / inspect\nGold rings: move up to %d hexes\nRed rings: enemies in attack range\nEmpty space / Esc to clear selection" % SkirmishController.MOVE_RANGE, 13, Color("a7bbc3"))
	result_overlay = ColorRect.new()
	result_overlay.name = "BattleResult"
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.color = Color(0.015, 0.03, 0.045, 0.65)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.hide()
	frame.add_child(result_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_overlay.add_child(center)
	var result_panel := PanelContainer.new()
	result_panel.custom_minimum_size = Vector2(420, 0)
	result_panel.add_theme_stylebox_override("panel", style.duplicate())
	center.add_child(result_panel)
	var result_rows := VBoxContainer.new()
	result_rows.add_theme_constant_override("separation", 18)
	result_panel.add_child(result_rows)
	var heading := add_status_row(result_rows, "B A T T L E   C O M P L E T E", 14, Color("cbb58e"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label = add_status_row(result_rows, "", 36, Color.WHITE)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_details = add_status_row(result_rows, "", 16, Color("d6e1e2"))
	result_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_button = Button.new()
	restart_button.name = "RestartEncounter"
	restart_button.text = "Restart Encounter"
	restart_button.custom_minimum_size.y = 48
	restart_button.pressed.connect(skirmish.restart_encounter)
	result_rows.add_child(restart_button)
	skirmish.state_changed.connect(_refresh_status)
	_refresh_status()

func _refresh_status() -> void:
	var show_result := skirmish.battle_over and not result_overlay.visible
	result_overlay.visible = skirmish.battle_over
	end_turn_button.disabled = skirmish.battle_over
	if skirmish.battle_over:
		result_label.text = skirmish.result_text()
		result_label.modulate = Color("52e0c0") if skirmish.winner == PlaceholderUnit.Team.JADE else Color("ff825e")
		if skirmish.winner == -1:
			result_label.modulate = Color.WHITE
		result_details.text = "Encounter ended on turn %d.\nRestart to play again from the beginning." % skirmish.turn_number
		if show_result:
			restart_button.grab_focus()
	turn_label.text = "TURN %d  /  %s" % [skirmish.turn_number, skirmish.active_team_name().to_upper()]
	if skirmish.battle_over:
		turn_label.text = "BATTLE COMPLETE"
	turn_label.modulate = Color("52e0c0") if skirmish.active_team == PlaceholderUnit.Team.JADE else Color("ff825e")
	end_turn_button.text = "End Turn  →  %s" % ("Ember" if skirmish.active_team == PlaceholderUnit.Team.JADE else "Jade")
	var unit := skirmish.selected_unit
	selection_label.text = "%s  /  %d of %d HP" % [unit.display_name(), unit.health, PlaceholderUnit.MAX_HEALTH] if unit != null else "No unit selected"
	ability_button.disabled = not skirmish.can_use_ability(unit)
	ability_button.text = "Attack"
	if unit != null:
		ability_button.text = "%s  /  %s" % [unit.ability_name(), "Used" if unit.ability_used else "Attack"]
	if skirmish.targeting_attack:
		ability_button.text = "Cancel Attack"
	if unit == null:
		actions_label.text = "Each unit: 3 HP / 1 move + 1 attack"
	elif unit.team != skirmish.active_team:
		actions_label.text = "Waiting for %s's turn" % unit.team_name()
	else:
		actions_label.text = "Move: %s   /   Attack: %s" % ["used" if unit.has_moved else "ready", "used" if unit.ability_used else "ready"]
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
