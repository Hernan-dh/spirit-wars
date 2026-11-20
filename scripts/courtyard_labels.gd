extends CanvasLayer
## Runtime presentation only; the battlefield stays clear in the 3D editor.

const HudStyle = preload("res://scripts/hud_style.gd")

@export_node_path("Node3D") var skirmish_path: NodePath = ^"../Skirmish"
@export_node_path("Node3D") var grid_path: NodePath = ^"../BattlefieldGrid"

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
var frame: Control

func _ready() -> void:
	skirmish = get_node_or_null(skirmish_path) as SkirmishController
	if skirmish == null:
		push_error("CourtyardLabels needs a Skirmish controller at %s." % skirmish_path)
		return
	frame = Control.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	_build_header()
	_build_footer()
	_build_grid_count()
	_build_status_panel()
	_build_result_overlay()
	skirmish.state_changed.connect(_refresh_status)
	_refresh_status()

func _build_header() -> void:
	_add_label(frame, HudStyle.HEADER_EYEBROW_TEXT, HudStyle.HEADER_EYEBROW_POS, HudStyle.HEADER_EYEBROW_SIZE, HudStyle.COLOR_ACCENT)
	_add_label(frame, HudStyle.HEADER_TITLE_TEXT, HudStyle.HEADER_TITLE_POS, HudStyle.HEADER_TITLE_SIZE, HudStyle.COLOR_TITLE)
	_add_label(frame, HudStyle.HEADER_SUBTITLE_TEXT, HudStyle.HEADER_SUBTITLE_POS, HudStyle.HEADER_SUBTITLE_SIZE, HudStyle.COLOR_SUBTITLE)
	var line := ColorRect.new()
	line.position = HudStyle.HEADER_RULE_POS
	line.size = HudStyle.HEADER_RULE_SIZE
	line.color = HudStyle.COLOR_ACCENT
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(line)

func _build_footer() -> void:
	var footer := Label.new()
	footer.text = HudStyle.FOOTER_TEXT
	footer.add_theme_font_size_override("font_size", HudStyle.FOOTER_SIZE)
	footer.add_theme_color_override("font_color", HudStyle.COLOR_HINT)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.position = HudStyle.FOOTER_POS
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(footer)

func _build_grid_count() -> void:
	var grid := get_node_or_null(grid_path)
	if grid == null:
		push_error("CourtyardLabels needs a grid at %s." % grid_path)
		return
	var count := Label.new()
	count.text = HudStyle.GRID_COUNT_FORMAT % [int(grid.get_meta("rows")), int(grid.get_meta("columns")), grid.get_child_count()]
	count.add_theme_font_size_override("font_size", HudStyle.GRID_COUNT_SIZE)
	count.add_theme_color_override("font_color", HudStyle.COLOR_ACCENT)
	count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	count.position = HudStyle.GRID_COUNT_POS
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(count)

func _build_status_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.position = HudStyle.STATUS_PANEL_POS
	panel.custom_minimum_size = Vector2(HudStyle.STATUS_PANEL_WIDTH, 0)
	# Interactive panel blocks clicks from reaching the battlefield.
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _panel_style())
	frame.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", HudStyle.STATUS_ROW_GAP)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(rows)
	_add_status_row(rows, HudStyle.LOCAL_PLAY_HEADING, HudStyle.STATUS_HEADING_SIZE, HudStyle.COLOR_ACCENT)
	turn_label = _add_status_row(rows, "", HudStyle.TURN_SIZE, Color.WHITE)
	end_turn_button = Button.new()
	end_turn_button.name = "EndTurn"
	end_turn_button.custom_minimum_size.y = HudStyle.END_TURN_HEIGHT
	end_turn_button.pressed.connect(skirmish.end_turn)
	rows.add_child(end_turn_button)
	rows.add_child(HSeparator.new())
	selection_label = _add_status_row(rows, "", HudStyle.SELECTION_SIZE, HudStyle.COLOR_GOLD)
	actions_label = _add_status_row(rows, "", HudStyle.ACTIONS_SIZE, HudStyle.COLOR_BODY)
	ability_button = Button.new()
	ability_button.name = "Ability"
	ability_button.custom_minimum_size.y = HudStyle.ABILITY_HEIGHT
	ability_button.tooltip_text = HudStyle.ABILITY_TOOLTIP % [SkirmishController.ATTACK_RANGE, SkirmishController.ATTACK_DAMAGE]
	ability_button.pressed.connect(skirmish.use_selected_ability)
	rows.add_child(ability_button)
	_add_status_row(rows, HudStyle.ATTACK_HELP % [SkirmishController.ATTACK_DAMAGE, SkirmishController.ATTACK_RANGE], HudStyle.HINT_SIZE, HudStyle.COLOR_HINT)
	feedback_label = _add_status_row(rows, "", HudStyle.FEEDBACK_SIZE, HudStyle.COLOR_GOLD)
	feedback_label.custom_minimum_size = HudStyle.FEEDBACK_MIN_SIZE
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add_status_row(rows, HudStyle.FIELD_HELP % SkirmishController.MOVE_RANGE, HudStyle.HINT_SIZE, HudStyle.COLOR_HINT)

func _build_result_overlay() -> void:
	result_overlay = ColorRect.new()
	result_overlay.name = "BattleResult"
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.color = HudStyle.COLOR_OVERLAY
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.hide()
	frame.add_child(result_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_overlay.add_child(center)
	var result_panel := PanelContainer.new()
	result_panel.custom_minimum_size = Vector2(HudStyle.RESULT_PANEL_WIDTH, 0)
	result_panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(result_panel)
	var result_rows := VBoxContainer.new()
	result_rows.add_theme_constant_override("separation", HudStyle.RESULT_ROW_GAP)
	result_panel.add_child(result_rows)
	var heading := _add_status_row(result_rows, HudStyle.OVERLAY_HEADING, HudStyle.RESULT_HEADING_SIZE, HudStyle.COLOR_ACCENT)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label = _add_status_row(result_rows, "", HudStyle.RESULT_TITLE_SIZE, Color.WHITE)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_details = _add_status_row(result_rows, "", HudStyle.RESULT_DETAILS_SIZE, HudStyle.COLOR_BODY)
	result_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_button = Button.new()
	restart_button.name = "RestartEncounter"
	restart_button.text = HudStyle.RESTART_TEXT
	restart_button.custom_minimum_size.y = HudStyle.RESTART_HEIGHT
	restart_button.pressed.connect(skirmish.restart_encounter)
	result_rows.add_child(restart_button)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = HudStyle.COLOR_PANEL
	style.border_color = HudStyle.COLOR_PANEL_BORDER
	style.set_border_width_all(HudStyle.PANEL_BORDER_WIDTH)
	style.set_corner_radius_all(HudStyle.PANEL_CORNER_RADIUS)
	style.content_margin_left = HudStyle.PANEL_MARGIN_HORIZONTAL
	style.content_margin_right = HudStyle.PANEL_MARGIN_HORIZONTAL
	style.content_margin_top = HudStyle.PANEL_MARGIN_VERTICAL
	style.content_margin_bottom = HudStyle.PANEL_MARGIN_VERTICAL
	return style

func _refresh_status() -> void:
	var show_result := skirmish.battle_over and not result_overlay.visible
	result_overlay.visible = skirmish.battle_over
	end_turn_button.disabled = skirmish.battle_over
	if skirmish.battle_over:
		result_label.text = skirmish.result_text()
		result_label.modulate = Color.WHITE if skirmish.winner == SkirmishController.NO_WINNER else PlaceholderUnit.color_for(skirmish.winner)
		result_details.text = HudStyle.RESULT_DETAILS % skirmish.turn_number
		if show_result:
			restart_button.grab_focus()
	turn_label.text = HudStyle.TURN_FORMAT % [skirmish.turn_number, skirmish.active_team_name().to_upper()]
	if skirmish.battle_over:
		turn_label.text = HudStyle.BATTLE_COMPLETE_TEXT
	turn_label.modulate = PlaceholderUnit.color_for(skirmish.active_team)
	end_turn_button.text = HudStyle.END_TURN_FORMAT % PlaceholderUnit.name_for(PlaceholderUnit.other_team(skirmish.active_team))
	var unit := skirmish.selected_unit
	var unit_valid := is_instance_valid(unit)
	selection_label.text = HudStyle.SELECTION_FORMAT % [unit.display_name(), unit.health, PlaceholderUnit.MAX_HEALTH] if unit_valid else HudStyle.NO_UNIT_TEXT
	ability_button.disabled = not skirmish.can_use_ability(unit)
	ability_button.text = HudStyle.ATTACK_TEXT
	if unit_valid:
		ability_button.text = HudStyle.ABILITY_STATUS_FORMAT % [unit.ability_name(), HudStyle.USED_TEXT if unit.ability_used else HudStyle.ATTACK_TEXT]
	if skirmish.targeting_attack:
		ability_button.text = HudStyle.CANCEL_ATTACK_TEXT
	if not unit_valid:
		actions_label.text = HudStyle.ACTIONS_HELP % PlaceholderUnit.MAX_HEALTH
	elif unit.team != skirmish.active_team:
		actions_label.text = HudStyle.WAITING_HELP % unit.team_name()
	else:
		actions_label.text = HudStyle.ACTION_STATUS % [HudStyle.USED_STATE_TEXT if unit.has_moved else HudStyle.READY_TEXT, HudStyle.USED_STATE_TEXT if unit.ability_used else HudStyle.READY_TEXT]
	feedback_label.text = skirmish.feedback

func _add_status_row(parent: Control, text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _add_label(parent: Control, text: String, position: Vector2, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
