extends Control
## Story scene: a character portrait, a speech bubble with typewriter text, Next / Skip.
## Emits `finished` once, when the last line is done or the player skips.

signal finished

const UI := preload("res://scripts/core/ui_util.gd")
const StoryData := preload("res://scripts/core/story_data.gd")
const CharPreview := preload("res://scripts/ui/char_preview.gd")

var lines: Array = []
var chapter := 0
var last_button := "Start!"
var _index := 0
var _portrait
var _name_label: Label
var _text_label: Label
var _next_btn: Button
var _bubble_style: StyleBoxFlat
var _tween: Tween
var _done := false

func setup(p_lines: Array, p_chapter: int, p_last_button: String = "Start!") -> void:
	lines = p_lines
	chapter = p_chapter
	last_button = p_last_button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UI.NAVY
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	add_child(cc)
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := Control.new()
	root.custom_minimum_size = Vector2(1180, 650)
	cc.add_child(root)

	var chap := UI.label("CHAPTER %d" % (chapter + 1), 26, UI.LAV)
	root.add_child(chap)
	chap.position = Vector2(0, 0)
	chap.size = Vector2(1180, 34)
	var ttl := UI.label(StoryData.title(chapter), 58, Color.WHITE)
	root.add_child(ttl)
	ttl.position = Vector2(0, 32)
	ttl.size = Vector2(1180, 76)
	var plc := UI.label(StoryData.place(chapter), 24, UI.CYAN)
	root.add_child(plc)
	plc.position = Vector2(0, 104)
	plc.size = Vector2(1180, 34)

	_portrait = CharPreview.new()
	_portrait.victory = false
	root.add_child(_portrait)
	_portrait.position = Vector2(10, 160)
	_portrait.size = Vector2(300, 400)

	var bubble := PanelContainer.new()
	_bubble_style = StyleBoxFlat.new()
	_bubble_style.bg_color = UI.PANEL
	_bubble_style.set_corner_radius_all(28)
	_bubble_style.set_border_width_all(4)
	_bubble_style.set_content_margin_all(26)
	bubble.add_theme_stylebox_override("panel", _bubble_style)
	root.add_child(bubble)
	bubble.position = Vector2(340, 190)
	bubble.custom_minimum_size = Vector2(840, 320)
	bubble.size = Vector2(840, 320)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	bubble.add_child(vb)
	_name_label = UI.label("", 34, UI.GOLD)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(_name_label)
	_text_label = UI.label("", 36, Color.WHITE)
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(780, 200)
	vb.add_child(_text_label)

	var skip := UI.button("Skip", UI.PANEL, Vector2(220, 78))
	root.add_child(skip)
	skip.position = Vector2(10, 572)
	skip.pressed.connect(_finish)
	_next_btn = UI.button("Next", UI.PURPLE, Vector2(340, 84))
	root.add_child(_next_btn)
	_next_btn.position = Vector2(840, 566)
	_next_btn.pressed.connect(_on_next)
	_show_line()

func _show_line() -> void:
	var line: Array = lines[_index]
	var who: String = line[0]
	var pal: Dictionary = StoryData.palette_for(who)
	_portrait.palette = pal
	_name_label.text = StoryData.speaker_name(who)
	_bubble_style.border_color = (pal["accent"] as Color).lightened(0.2)
	_text_label.text = String(line[1])
	_text_label.visible_ratio = 0.0
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text_label, "visible_ratio", 1.0, maxf(0.5, float(_text_label.text.length()) * 0.022))
	_next_btn.text = last_button if _index == lines.size() - 1 else "Next"

func _typing() -> bool:
	return _text_label.visible_ratio < 1.0

func _on_next() -> void:
	if _typing():
		if _tween != null:
			_tween.kill()
		_text_label.visible_ratio = 1.0
		return
	if _index >= lines.size() - 1:
		_finish()
		return
	_index += 1
	_show_line()

func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()

func on_back() -> void:
	_finish()
