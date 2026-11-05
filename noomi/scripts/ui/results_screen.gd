extends Control

signal retry
signal next
signal menu

const UI := preload("res://scripts/core/ui_util.gd")

var result: Dictionary = {}

func setup(r: Dictionary) -> void:
	result = r

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
	vb.add_theme_constant_override("separation", 10)
	cc.add_child(vb)
	var done: bool = result["completed"]
	vb.add_child(UI.label(String(result["level_name"]), 40, UI.LAV))
	vb.add_child(UI.label("COMPLETE" if (done and result["mode"] == "campaign") else ("RESULTS" if result["mode"] == "rush" else "TRY AGAIN"), 72, UI.GOLD if done else UI.PINK))
	vb.add_child(UI.label(String(result["reason"]), 28, Color.WHITE))
	vb.add_child(UI.label("Score: %d" % result["score"], 56, Color.WHITE))
	if result["new_best"] and result["score"] > 0:
		vb.add_child(UI.label("NEW PERSONAL BEST!", 36, UI.GOLD))
	else:
		vb.add_child(UI.label("Personal best: %d" % result["personal_best"], 30, UI.LAV))
	if result["mode"] == "campaign":
		vb.add_child(UI.label("Stars: %d / 3" % result["stars"], 36, UI.GOLD))
		vb.add_child(UI.label("Landing: %s" % String(result["landing"]).capitalize(), 30, UI.CYAN))
	vb.add_child(UI.label("Best combo: %d" % result["best_combo"], 30, UI.CYAN))
	var names: Array = result["tricks"]
	vb.add_child(UI.label("Tricks (%d): %s" % [names.size(), ", ".join(names) if not names.is_empty() else "none"], 24, Color.WHITE))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	var r := UI.button("Retry", UI.PURPLE, Vector2(240, 84))
	r.pressed.connect(func(): retry.emit())
	row.add_child(r)
	if result["has_next"]:
		var n := UI.button("Continue", UI.CYAN.darkened(0.3), Vector2(240, 84))
		n.pressed.connect(func(): next.emit())
		row.add_child(n)
	var m := UI.button("Menu", UI.PANEL, Vector2(240, 84))
	m.pressed.connect(func(): menu.emit())
	row.add_child(m)

func on_back() -> void:
	menu.emit()
