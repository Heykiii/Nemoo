extends Control
## Multi-touch capable hold button. Handles raw touch events so several buttons can be held at once.
## Sets the matching Input action, so keyboard and touch drive the same gameplay code.

signal down
signal up

var label := ""
var color := Color("7b4dff")
var action := ""
var highlight := false
var pressed := false
var _touches := {}
var _mouse := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_label(t: String) -> void:
	if t != label:
		label = t
		queue_redraw()

func set_highlight(v: bool) -> void:
	if v != highlight:
		highlight = v
		queue_redraw()

func reset() -> void:
	_touches.clear()
	_mouse = false
	_update()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed and get_global_rect().has_point(e.position):
			_touches[e.index] = true
			_update()
		elif not e.pressed and _touches.has(e.index):
			_touches.erase(e.index)
			_update()
	elif event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.button_index != MOUSE_BUTTON_LEFT:
			return
		if m.pressed and get_global_rect().has_point(m.position):
			_mouse = true
			_update()
		elif not m.pressed and _mouse:
			_mouse = false
			_update()

func _update() -> void:
	var now := _touches.size() > 0 or _mouse
	if now == pressed:
		return
	pressed = now
	if action != "":
		if pressed:
			Input.action_press(action)
		else:
			Input.action_release(action)
	if pressed:
		down.emit()
	else:
		up.emit()
	queue_redraw()

func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color.r, color.g, color.b, 0.92 if pressed else 0.55)
	sb.set_corner_radius_all(26)
	if highlight:
		sb.border_color = Color("ffc048")
		sb.set_border_width_all(6)
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	var font := ThemeDB.fallback_font
	var fs := 26
	var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	draw_string(font, Vector2((size.x - ts.x) / 2.0, (size.y - ts.y) / 2.0 + font.get_ascent(fs)), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
