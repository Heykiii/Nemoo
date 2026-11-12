extends Control
## Main menu with sub pages: Modes, Characters, Settings, Trick Book.

signal open_levels
signal start_rush
signal start_chill

const UI := preload("res://scripts/core/ui_util.gd")
const CharacterData := preload("res://scripts/core/character_data.gd")
const CharPreview := preload("res://scripts/ui/char_preview.gd")

var _box: VBoxContainer
var _page := "main"
var _btn_size := Vector2(300, 84)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UI.NAVY
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	add_child(cc)
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 14)
	cc.add_child(_box)
	_show_main()

func on_back() -> void:
	if _page == "main":
		get_tree().quit()
	else:
		_show_main()

func _clear() -> void:
	_btn_size = Vector2(300, 84)
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()

func _btn(text: String, cb: Callable, color: Color = UI.PURPLE, disabled: bool = false) -> Button:
	var b := UI.button(text, color, _btn_size)
	b.disabled = disabled
	b.pressed.connect(cb)
	_box.add_child(b)
	return b

func _show_main() -> void:
	_page = "main"
	_clear()
	_box.add_child(UI.label("NOOMI", 110, UI.LAV))
	_box.add_child(UI.label("Swing. Release. Flip. Stick it.", 28, UI.CYAN))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	_box.add_child(gap)
	_btn("Play", func(): open_levels.emit(), UI.PURPLE)
	_btn("Modes", _show_modes)
	_btn("Characters", _show_characters)
	_btn("Trick Book", _show_book)
	_btn("Settings", _show_settings)
	if not OS.has_feature("mobile"):
		_btn("Quit", func(): get_tree().quit(), UI.PINK)

func _show_modes() -> void:
	_page = "modes"
	_clear()
	_box.add_child(UI.label("Modes", 64, UI.LAV))
	_btn("Campaign (10 levels)", func(): open_levels.emit())
	_btn("Trick Rush (60s)", func(): start_rush.emit(), UI.PINK)
	_btn("Chill Mode (sandbox)", func(): start_chill.emit(), UI.CYAN.darkened(0.3))
	_btn("Daily Challenge - coming soon", func(): pass, UI.PURPLE, true)
	_btn("Parkour Race - coming soon", func(): pass, UI.PURPLE, true)
	_btn("Back", _show_main, UI.PANEL)

func _show_characters() -> void:
	_page = "characters"
	_clear()
	_box.add_child(UI.label("Choose your character", 42, UI.LAV))
	_box.add_child(UI.label("Cosmetic only - everyone flips the same.", 20, UI.CYAN))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(1180, 456)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	sc.add_child(grid)
	for i in CharacterData.LIST.size():
		grid.add_child(_char_card(i))
	var back_btn := UI.button("Back", UI.PANEL, Vector2(300, 64))
	back_btn.pressed.connect(_show_main)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(back_btn)

func _char_card(i: int) -> Control:
	var ch: Dictionary = CharacterData.LIST[i]
	var selected := int(SaveManager.data["character"]) == i
	var b := Button.new()
	b.custom_minimum_size = Vector2(186, 222)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = UI.PANEL if st != "pressed" else UI.PANEL.lightened(0.15)
		sb.set_corner_radius_all(20)
		if selected:
			sb.border_color = UI.GOLD
			sb.set_border_width_all(5)
		b.add_theme_stylebox_override(st, sb)
	var idx := i
	b.pressed.connect(func():
		SaveManager.data["character"] = idx
		SaveManager.save()
		AudioManager.play("button")
		_show_characters())
	var prev := CharPreview.new()
	prev.palette = ch
	prev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(prev)
	prev.anchor_right = 1.0
	prev.anchor_bottom = 1.0
	prev.offset_top = 6
	prev.offset_bottom = -60
	var nm := UI.label(String(ch["name"]), 24, UI.GOLD if selected else Color.WHITE)
	b.add_child(nm)
	nm.anchor_left = 0.0
	nm.anchor_right = 1.0
	nm.anchor_top = 1.0
	nm.anchor_bottom = 1.0
	nm.offset_top = -60
	nm.offset_bottom = -34
	var tg := UI.label(String(ch["tag"]), 14, UI.LAV)
	tg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_child(tg)
	tg.anchor_left = 0.0
	tg.anchor_right = 1.0
	tg.anchor_top = 1.0
	tg.anchor_bottom = 1.0
	tg.offset_left = 6
	tg.offset_right = -6
	tg.offset_top = -34
	tg.offset_bottom = -2
	return b

func _show_settings() -> void:
	_page = "settings"
	_clear()
	_btn_size = Vector2(440, 64)
	_box.add_child(UI.label("Settings", 46, UI.LAV))
	var opts := [["sound", "Sound"], ["music", "Music (no tracks yet)"], ["haptics", "Vibration"], ["reduce_motion", "Reduce motion"]]
	for o in opts:
		var key: String = o[0]
		_btn("%s: %s" % [o[1], "ON" if SaveManager.setting(key) else "OFF"], func():
			SaveManager.toggle_setting(key)
			_show_settings())
	_btn("Game speed: %s" % SaveManager.speed_name(), func():
		SaveManager.cycle_speed()
		_show_settings())
	_btn("Reset progress", func():
		SaveManager.data = SaveManager.default_data()
		SaveManager.save()
		_show_settings(), UI.PINK)
	_btn("Back", _show_main, UI.PANEL)

func _show_book() -> void:
	_page = "book"
	_clear()
	_box.add_child(UI.label("Trick Book", 64, UI.LAV))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(900, 380)
	_box.add_child(sc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	sc.add_child(vb)
	var tricks: Dictionary = SaveManager.data["tricks"]
	if tricks.is_empty():
		vb.add_child(UI.label("No tricks discovered yet. Go flip something!", 28, Color.WHITE))
	for k in tricks:
		var e: Dictionary = tricks[k]
		vb.add_child(UI.label("%s  x%d  -  %s" % [k, e["count"], e["desc"]], 24, UI.CYAN))
	vb.add_child(UI.label("", 20))
	vb.add_child(UI.label("Achievements", 36, UI.GOLD))
	for id in SaveManager.ACHIEVEMENTS:
		var done: bool = SaveManager.data["achievements"].has(id)
		vb.add_child(UI.label("[%s] %s" % ["X" if done else " ", SaveManager.ACHIEVEMENTS[id]], 24, UI.GOLD if done else Color(1, 1, 1, 0.5)))
	_btn("Back", _show_main, UI.PANEL)
