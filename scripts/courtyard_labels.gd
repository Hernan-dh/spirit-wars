extends CanvasLayer
## Runtime presentation only; the battlefield stays clear in the 3D editor.
var selection_label: Label

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
	panel.position = Vector2(-330, 30)
	panel.custom_minimum_size = Vector2(292, 0)
	# This information panel does not consume battlefield clicks.
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	add_status_row(rows, "OPPOSING TEAMS", 12, Color("cbb58e"))
	add_status_row(rows, "JADE   /   2 units", 18, Color("52e0c0"))
	add_status_row(rows, "EMBER   /   2 units", 18, Color("ff825e"))
	selection_label = add_status_row(rows, "No unit selected", 16, Color("ffe08a"))
	add_status_row(rows, "Left click a unit to select\nEmpty space / Esc to clear", 13, Color("a7bbc3"))
	get_parent().get_node("Skirmish").selection_changed.connect(_on_selection_changed)

func _on_selection_changed(unit: PlaceholderUnit) -> void:
	selection_label.text = "Selected: %s" % unit.display_name() if unit != null else "No unit selected"

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
