extends RefCounted

const NAVY := Color("0b1030")
const PANEL := Color("1a1f4d")
const LAV := Color("b79cff")
const PURPLE := Color("7b4dff")
const CYAN := Color("4de8d0")
const GOLD := Color("ffc048")
const PINK := Color("ff4d8d")

static func button(text: String, color: Color = PURPLE, min_size: Vector2 = Vector2(300, 84)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 32)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.5))
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = color
		if s == "pressed":
			sb.bg_color = color.darkened(0.25)
		if s == "disabled":
			sb.bg_color = Color(0.25, 0.25, 0.38)
		sb.set_corner_radius_all(22)
		b.add_theme_stylebox_override(s, sb)
	b.pressed.connect(func(): AudioManager.play("button"))
	return b

static func label(text: String, size: int = 32, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l
