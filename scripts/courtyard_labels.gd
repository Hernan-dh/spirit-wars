extends CanvasLayer
## Runtime presentation only; the battlefield stays clear in the 3D editor.
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

func add_label(parent: Control, text: String, position: Vector2, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
