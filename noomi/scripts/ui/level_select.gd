extends Control

signal chosen(index: int)
signal back

const UI := preload("res://scripts/core/ui_util.gd")
const LevelData := preload("res://scripts/core/level_data.gd")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UI.NAVY
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	add_child(cc)
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	cc.add_child(vb)
	vb.add_child(UI.label("Campaign", 64, UI.LAV))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	vb.add_child(grid)
	var lv := LevelData.levels()
	var unlocked := int(SaveManager.data["unlocked"])
	for i in lv.size():
		var e: Dictionary = SaveManager.level_entry(i)
		var open := i < unlocked
		var txt := "%d\n%s" % [i + 1, lv[i]["name"]] if open else "%d\nLocked" % (i + 1)
		if open:
			txt += "\n%d/3 stars" % int(e["stars"])
		var b := UI.button(txt, UI.PURPLE, Vector2(220, 150))
		b.add_theme_font_size_override("font_size", 24)
		b.disabled = not open
		var idx := i
		b.pressed.connect(func(): chosen.emit(idx))
		grid.add_child(b)
	var back_btn := UI.button("Back", UI.PANEL)
	back_btn.pressed.connect(func(): back.emit())
	vb.add_child(back_btn)

func on_back() -> void:
	back.emit()
