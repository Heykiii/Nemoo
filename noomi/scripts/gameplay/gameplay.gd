extends Node2D
## One play session: campaign level, Trick Rush (timed) or Chill (sandbox).

signal finished(result: Dictionary)
signal exit_requested

const PlayerScript := preload("res://scripts/player/player.gd")
const LevelView := preload("res://scripts/gameplay/level_view.gd")
const ScoreManager := preload("res://scripts/gameplay/score_manager.gd")
const Skyline := preload("res://scripts/gameplay/skyline.gd")
const HoldButton := preload("res://scripts/ui/hold_button.gd")
const LevelData := preload("res://scripts/core/level_data.gd")
const UI := preload("res://scripts/core/ui_util.gd")

const RUSH_TIME := 60.0
const RESPAWN_DELAY := 1.2
const TUTORIAL := [
	"Tap RELEASE to let go, then tap GRAB when the bar glows gold.",
	"Hold PUMP to build a big swing.",
	"Tap RELEASE on the forward swing to launch.",
	"Hold BACK FLIP (or FRONT FLIP) to rotate.",
	"Hold EXTEND to slow the spin, then land on your feet in the gold zone.",
]

var mode := "campaign"
var level_index := 0
var level: Dictionary = {}
var player
var view
var skyline
var camera: Camera2D
var score
var run_over := false
var respawn_pending := false
var time_left := RUSH_TIME
var tut_step := -1
var shake := 0.0
var hint_time := 10.0

var hud: CanvasLayer
var area: Control
var score_label: Label
var combo_label: Label
var status_label: Label
var timer_label: Label
var popup_label: Label
var hint_label: Label
var grab_btn
var hold_buttons: Array = []
var overlay: CanvasLayer = null
var popup_tween: Tween

func setup(p_mode: String, p_index: int = 0) -> void:
	mode = p_mode
	level_index = p_index

func _ready() -> void:
	level = LevelData.levels()[level_index] if mode == "campaign" else LevelData.rush_layout()
	score = ScoreManager.new()
	_build_world()
	_build_hud()
	_start_run()

# ------------------------------------------------------------ build
func _build_world() -> void:
	var bg := CanvasLayer.new()
	bg.layer = -10
	add_child(bg)
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color("0b1030"))
	g.set_color(1, Color("2e1b66"))
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 256
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(tr)
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -9
	add_child(sky_layer)
	skyline = Skyline.new()
	sky_layer.add_child(skyline)
	view = LevelView.new()
	add_child(view)
	player = PlayerScript.new()
	add_child(player)
	player.setup(level)
	player.palette = SaveManager.character_palette()
	view.setup(level, player)
	player.grabbed.connect(_on_grabbed)
	player.released.connect(_on_released)
	player.rotation_completed.connect(_on_rotation)
	player.flight_ended.connect(_on_flight_ended)
	player.landed.connect(_on_landed)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)
	camera.global_position = player.global_position
	camera.make_current()

func _place(c: Control, ax: float, ay: float, l: float, t: float, r: float, b: float) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = l
	c.offset_top = t
	c.offset_right = r
	c.offset_bottom = b

func _safe_margins() -> Vector4:
	var m := Vector4(20, 16, 20, 16)
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	var vp := get_viewport().get_visible_rect().size
	if win.x > 0 and win.y > 0 and safe.size.x > 0:
		var sx := vp.x / float(win.x)
		var sy := vp.y / float(win.y)
		m.x = maxf(m.x, float(safe.position.x) * sx + 12.0)
		m.y = maxf(m.y, float(safe.position.y) * sy + 8.0)
		m.z = maxf(m.z, float(win.x - safe.end.x) * sx + 12.0)
		m.w = maxf(m.w, float(win.y - safe.end.y) * sy + 8.0)
	return m

func _hold(text: String, action: String, color: Color, ax: float, l: float, t: float, r: float, b: float):
	var h = HoldButton.new()
	h.label = text
	h.action = action
	h.color = color
	area.add_child(h)
	_place(h, ax, 1.0, l, t, r, b)
	hold_buttons.append(h)
	return h

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mc := MarginContainer.new()
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := _safe_margins()
	mc.add_theme_constant_override("margin_left", int(m.x))
	mc.add_theme_constant_override("margin_top", int(m.y))
	mc.add_theme_constant_override("margin_right", int(m.z))
	mc.add_theme_constant_override("margin_bottom", int(m.w))
	root.add_child(mc)
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	area = Control.new()
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_child(area)

	score_label = UI.label("SCORE 0", 38, UI.GOLD)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	area.add_child(score_label)
	_place(score_label, 0.0, 0.0, 0, 0, 360, 50)
	combo_label = UI.label("", 30, UI.CYAN)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	area.add_child(combo_label)
	_place(combo_label, 0.0, 0.0, 0, 50, 360, 90)
	status_label = UI.label("", 24, UI.LAV)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	area.add_child(status_label)
	_place(status_label, 0.0, 0.0, 0, 90, 460, 126)
	timer_label = UI.label("", 56, Color.WHITE)
	area.add_child(timer_label)
	_place(timer_label, 0.5, 0.0, -100, 0, 100, 70)
	popup_label = UI.label("", 42, UI.CYAN)
	popup_label.modulate.a = 0.0
	area.add_child(popup_label)
	_place(popup_label, 0.5, 0.0, -450, 70, 450, 130)
	hint_label = UI.label("", 26, UI.LAV)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	area.add_child(hint_label)
	_place(hint_label, 0.5, 0.0, -420, 135, 420, 215)

	var pause_btn := UI.button("II", UI.PURPLE, Vector2(84, 84))
	area.add_child(pause_btn)
	pause_btn.anchor_left = 1.0
	pause_btn.anchor_right = 1.0
	pause_btn.offset_left = -84
	pause_btn.offset_right = 0
	pause_btn.offset_top = 0
	pause_btn.offset_bottom = 84
	pause_btn.pressed.connect(_open_pause)
	var retry_btn := UI.button("Retry", UI.PINK, Vector2(150, 84))
	area.add_child(retry_btn)
	retry_btn.anchor_left = 1.0
	retry_btn.anchor_right = 1.0
	retry_btn.offset_left = -246
	retry_btn.offset_right = -96
	retry_btn.offset_top = 0
	retry_btn.offset_bottom = 84
	retry_btn.pressed.connect(_quick_restart)

	var pump = _hold("PUMP", "pump", UI.PURPLE, 0.0, 0, -190, 210, -10)
	grab_btn = _hold("RELEASE", "", UI.CYAN.darkened(0.3), 0.0, 230, -190, 440, -10)
	grab_btn.down.connect(player.queue_grab)
	var front = _hold("FRONT FLIP", "flip_front", UI.PURPLE, 1.0, -220, -190, -10, -10)
	var back = _hold("BACK FLIP", "flip_back", UI.PURPLE, 1.0, -440, -190, -230, -10)
	_hold("TUCK", "tuck", UI.LAV.darkened(0.3), 1.0, -450, -330, -310, -210)
	_hold("EXTEND", "extend", UI.LAV.darkened(0.3), 1.0, -300, -330, -160, -210)
	_hold("TWIST", "twist", UI.PINK.darkened(0.2), 1.0, -150, -330, -10, -210)
	timer_label.visible = mode == "rush"
	score_label.visible = mode != "chill"
	combo_label.visible = mode != "chill"

# ------------------------------------------------------------ run control
func _start_run() -> void:
	score = ScoreManager.new()
	run_over = false
	respawn_pending = false
	time_left = RUSH_TIME
	hint_time = 10.0
	shake = 0.0
	view.time = 0.0
	player.reset(0)
	tut_step = 0 if (mode == "campaign" and level_index == 0 and not SaveManager.data["tutorial_done"]) else -1
	_refresh_hud()

func _quick_restart() -> void:
	if score.score > 0 and not run_over:
		_show_overlay("Restart this attempt?", [["Yes, restart", _confirm_restart], ["Keep playing", _close_overlay]])
	else:
		_start_run()

func _confirm_restart() -> void:
	_close_overlay()
	_start_run()

func _refresh_hud() -> void:
	score_label.text = "SCORE %d" % score.score
	combo_label.text = "" if score.combo < 2 else "COMBO x%.1f" % score.multiplier()

func _process(delta: float) -> void:
	if camera == null or player == null:
		return
	camera.global_position = player.global_position
	var base := Vector2(110, -40)
	if shake > 0.01:
		shake = move_toward(shake, 0.0, delta * 30.0)
		base += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
	camera.offset = base
	skyline.cam_x = camera.global_position.x
	skyline.queue_redraw()
	grab_btn.set_label("RELEASE" if player.is_hanging() else "GRAB")
	grab_btn.set_highlight(player.near_bar != -1 and player.is_airborne())
	if player.is_airborne():
		status_label.text = "Flip %.1f   Twist %.1f" % [player.flips_progress(), player.twist_progress()]
	else:
		status_label.text = ""
	_update_tutorial()
	if hint_time > 0.0 and tut_step < 0:
		hint_time -= delta
		hint_label.text = level.get("hint", "") if hint_time > 0.0 else ""

func _physics_process(delta: float) -> void:
	if player == null:
		return
	for i in view.hazard_pos.size():
		var hp: Vector2 = view.hazard_pos[i]
		var rad: float = float(level["hazards"][i]["radius"]) + 14.0
		for p in player.body_points():
			if hp.distance_to(p) < rad:
				player.hit_hazard()
				break
	if mode == "rush" and not run_over:
		time_left -= delta
		timer_label.text = str(maxi(int(ceilf(time_left)), 0))
		if time_left <= 0.0:
			_finish_rush()

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("grab"):
		player.queue_grab()
	elif event.is_action_pressed("restart"):
		_quick_restart()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_inside_tree():
		_open_pause()

# ------------------------------------------------------------ tutorial
func _update_tutorial() -> void:
	if tut_step < 0:
		return
	if tut_step == 1 and player.is_hanging() and absf(player.omega) > 4.0:
		tut_step = 2
	elif tut_step == 3 and player.attempted:
		tut_step = 4
	hint_label.text = TUTORIAL[clampi(tut_step, 0, TUTORIAL.size() - 1)]

# ------------------------------------------------------------ feedback
func popup(text: String, color: Color) -> void:
	popup_label.text = text
	popup_label.add_theme_color_override("font_color", color)
	popup_label.modulate.a = 1.0
	if popup_tween != null:
		popup_tween.kill()
	popup_tween = create_tween()
	popup_tween.tween_interval(1.0)
	popup_tween.tween_property(popup_label, "modulate:a", 0.0, 0.5)

func _haptic(ms: int) -> void:
	if SaveManager.setting("haptics"):
		Input.vibrate_handheld(ms)

func _shake(amount: float) -> void:
	if not SaveManager.setting("reduce_motion"):
		shake = amount

func _ach(ids: Array) -> void:
	for id in ids:
		popup("Achievement: " + SaveManager.ACHIEVEMENTS[id], UI.GOLD)

# ------------------------------------------------------------ player events
func _on_grabbed(is_regrab: bool, _i: int) -> void:
	AudioManager.play("regrab" if is_regrab else "grab")
	if is_regrab:
		_haptic(20)
		if tut_step == 0:
			tut_step = 1
		elif tut_step >= 3:
			tut_step = 2

func _on_released(_speed: float, good: bool) -> void:
	AudioManager.play("release")
	if good:
		popup("Perfect release!", UI.GOLD)
	if tut_step == 1 or tut_step == 2:
		tut_step = 3

func _on_rotation(count: int, dir: int) -> void:
	popup(ScoreManager.trick_name(count, dir, 0) + "!", UI.CYAN)

func _on_flight_ended(summary: Dictionary, how: String) -> void:
	if run_over:
		return
	var r: Dictionary = score.bank_flight(summary, how)
	var ach: Array = []
	if r["trick"] != "":
		popup("%s  +%d" % [r["trick"], r["points"]], UI.CYAN)
		SaveManager.record_trick(r["trick"], r["desc"])
		AudioManager.play("trick")
		if int(r["flips"]) > 0 and SaveManager.unlock_achievement("first_rotation"):
			ach.append("first_rotation")
		if int(r["combo"]) >= 2 and SaveManager.unlock_achievement("first_combo"):
			ach.append("first_combo")
	elif r["regrab"]:
		popup("Regrab  +%d" % r["points"], UI.GOLD)
	if r["regrab"] and SaveManager.unlock_achievement("first_regrab"):
		ach.append("first_regrab")
	if not ach.is_empty():
		_ach(ach)
	_refresh_hud()

func _on_landed(result: String, info: Dictionary) -> void:
	if run_over or respawn_pending:
		return
	score.apply_landing(result)
	var ach: Array = SaveManager.register_landing(result)
	_refresh_hud()
	match result:
		"perfect":
			AudioManager.play("perfect")
			popup("PERFECT LANDING!", UI.GOLD)
			_shake(6.0)
			_haptic(40)
		"clean":
			AudioManager.play("land")
			popup("Clean landing", UI.CYAN)
			_shake(4.0)
			_haptic(25)
		"unstable":
			AudioManager.play("land")
			popup("Unstable landing", UI.LAV)
			_shake(3.0)
		_:
			AudioManager.play("fall")
			popup("Fall!", UI.PINK)
			_shake(9.0)
			_haptic(80)
	if not ach.is_empty():
		_ach(ach)
	if tut_step >= 0 and result != "fall":
		SaveManager.data["tutorial_done"] = true
		SaveManager.save()
		tut_step = -1
	match mode:
		"campaign":
			_finish_campaign(result, info)
		_:
			_schedule_respawn()

func _schedule_respawn() -> void:
	respawn_pending = true
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if not is_inside_tree() or run_over:
		return
	var best := 0
	var bd := 1e9
	for i in level["bars"].size():
		var d := absf(level["bars"][i].x - player.position.x)
		if d < bd:
			bd = d
			best = i
	respawn_pending = false
	player.reset(best)

func _stars_for(sc: int) -> int:
	var n := 0
	for t in level["stars"]:
		if sc >= int(t):
			n += 1
	return maxi(n, 1)

func _objective_met() -> bool:
	var o: Dictionary = level.get("objective", {})
	return score.max_flips >= int(o.get("flips", 0)) and score.max_twist >= int(o.get("twist", 0)) \
		and score.regrabs >= int(o.get("regrabs", 0)) and score.trick_total >= int(o.get("tricks", 0))

func _finish_campaign(result: String, info: Dictionary) -> void:
	run_over = true
	var good_landing := result == "clean" or result == "perfect"
	var on_target: bool = info.get("on_target", false)
	var obj_ok := _objective_met()
	var completed := good_landing and on_target and obj_ok
	var reason := ""
	if completed:
		reason = "Level complete!"
	elif result == "fall":
		reason = "You fell. Land feet-first, upright, and not too fast."
	elif not good_landing:
		reason = "Shaky landing. Slow your spin with EXTEND for a clean landing."
	elif not on_target:
		reason = "Land inside the gold target zone."
	else:
		reason = "Objective missing: " + LevelData.objective_text(level.get("objective", {}))
	var stars := _stars_for(score.score) if completed else 0
	var new_best := SaveManager.record_level(level_index, score.score, stars, completed)
	if new_best and score.score > 0 and SaveManager.unlock_achievement("personal_best"):
		_ach(["personal_best"])
	if completed:
		AudioManager.play("level_complete")
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	finished.emit({
		"mode": "campaign", "level_index": level_index, "level_name": level["name"],
		"score": score.score, "tricks": score.tricks, "landing": result,
		"best_combo": score.best_combo, "new_best": new_best,
		"personal_best": int(SaveManager.level_entry(level_index)["score"]),
		"stars": stars, "completed": completed, "reason": reason,
		"has_next": completed and level_index + 1 < SaveManager.LEVEL_COUNT,
	})

func _finish_rush() -> void:
	run_over = true
	var new_best := SaveManager.record_rush(score.score)
	if new_best and score.score > 0 and SaveManager.unlock_achievement("personal_best"):
		_ach(["personal_best"])
	finished.emit({
		"mode": "rush", "level_index": 0, "level_name": "Trick Rush",
		"score": score.score, "tricks": score.tricks, "landing": "time up",
		"best_combo": score.best_combo, "new_best": new_best,
		"personal_best": int(SaveManager.data["rush_best"]),
		"stars": 0, "completed": true, "reason": "Time's up!", "has_next": false,
	})

# ------------------------------------------------------------ pause / overlay
func on_back() -> void:
	if overlay != null:
		_close_overlay()
	else:
		_open_pause()

func _open_pause() -> void:
	if overlay != null:
		return
	var sound := "Sound: ON" if SaveManager.setting("sound") else "Sound: OFF"
	_show_overlay("Paused", [["Resume", _close_overlay], ["Restart", _confirm_restart], [sound, _toggle_sound], ["Main menu", _exit]])

func _toggle_sound() -> void:
	SaveManager.toggle_setting("sound")
	_close_overlay()
	_open_pause()

func _exit() -> void:
	get_tree().paused = false
	exit_requested.emit()

func _show_overlay(title: String, items: Array) -> void:
	if overlay != null:
		_close_overlay()
	for h in hold_buttons:
		h.reset()
	get_tree().paused = true
	overlay = CanvasLayer.new()
	overlay.layer = 20
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.08, 0.75)
	overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	overlay.add_child(cc)
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	cc.add_child(vb)
	vb.add_child(UI.label(title, 56, Color.WHITE))
	for it in items:
		var b := UI.button(it[0])
		b.pressed.connect(it[1])
		vb.add_child(b)

func _close_overlay() -> void:
	if overlay != null:
		overlay.queue_free()
		overlay = null
	get_tree().paused = false
