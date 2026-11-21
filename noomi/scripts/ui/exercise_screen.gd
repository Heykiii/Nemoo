extends Control
## "Train for Coins": guided real-life exercise timer. Offline. Honor system (the game cannot see you).

signal back

const UI := preload("res://scripts/core/ui_util.gd")
const ExerciseData := preload("res://scripts/core/exercise_data.gd")
const AdService := preload("res://scripts/core/ad_service.gd")

## The warm-up note is shown once per app launch.
static var warmed_up := false

var _box: VBoxContainer
var _state := "list"
var _ex: Dictionary = {}
var _elapsed := 0.0
var _running := false
var _count_label: Label
var _rep_label: Label
var _start_btn: Button
var _last_claim := 0

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
	_box.add_theme_constant_override("separation", 8)
	cc.add_child(_box)
	if warmed_up:
		_show_list()
	else:
		_show_warmup()

func on_back() -> void:
	if _state == "list":
		back.emit()
	else:
		_running = false
		_show_list()

func _clear() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()

func _wrap(text: String, size: int, color: Color, width: float = 900.0) -> Label:
	var l := UI.label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l

func _btn(text: String, cb: Callable, color: Color = UI.PURPLE, size: Vector2 = Vector2(520, 72)) -> Button:
	var b := UI.button(text, color, size)
	b.pressed.connect(cb)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(b)
	return b

func _show_warmup() -> void:
	_state = "warmup"
	_clear()
	_box.add_child(UI.label("Warm up first!", 64, UI.GOLD))
	_box.add_child(_wrap("Roll your shoulders, swing your arms and march on the spot for 20 seconds.", 32, Color.WHITE))
	_box.add_child(_wrap(ExerciseData.SAFETY, 24, UI.LAV))
	_box.add_child(_wrap("These are real exercises. The game cannot see your body, so it runs a guided timer and trusts you.", 24, UI.CYAN))
	_btn("I am warmed up", func():
		warmed_up = true
		_show_list(), UI.CYAN.darkened(0.3))
	_btn("Back", func(): back.emit(), UI.PANEL)

func _status_line() -> String:
	var st := SaveManager.streak()
	var s := "Coins: %d   |   Streak: %d day%s" % [int(SaveManager.data["coins"]), st, "" if st == 1 else "s"]
	if SaveManager.fever_active():
		s += "   |   GOLD CHALK FEVER x1.5"
	return s

func _show_list() -> void:
	_state = "list"
	_running = false
	_clear()
	_box.add_child(UI.label("Train for Coins", 44, UI.LAV))
	_box.add_child(UI.label(_status_line(), 26, UI.GOLD))
	_box.add_child(_wrap("3 days in a row = Gold Chalk Fever: x1.5 coins. Each exercise pays once a day.", 20, UI.CYAN))
	for e in ExerciseData.LIST:
		var id := String(e["id"])
		var done := SaveManager.exercise_done_today(id)
		var label := "%s  -  done today" % e["name"] if done else "%s   +%d coins" % [e["name"], int(e["coins"])]
		var b := _btn(label, func(): _show_guide(id), UI.PURPLE if not done else UI.PANEL, Vector2(620, 54))
		b.disabled = done
	if SaveManager.chalk_box_ready():
		_btn("Open daily Chalk Box  +%d" % SaveManager.CHALK_BOX_COINS, func():
			SaveManager.open_chalk_box()
			_show_list(), UI.GOLD.darkened(0.3), Vector2(620, 54))
	_box.add_child(_wrap(ExerciseData.SAFETY, 16, UI.LAV, 1000.0))
	_btn("Back", func(): back.emit(), UI.PANEL, Vector2(300, 52))

func _show_guide(id: String) -> void:
	_state = "guide"
	_ex = ExerciseData.get_def(id)
	_elapsed = 0.0
	_running = false
	_clear()
	_box.add_child(UI.label(String(_ex["name"]), 56, UI.LAV))
	_box.add_child(_wrap(String(_ex["how"]), 28, Color.WHITE))
	_box.add_child(UI.label("Reward: +%d coins%s" % [_pay(), " (fever x1.5)" if SaveManager.fever_active() else ""], 30, UI.GOLD))
	_count_label = UI.label("%d" % int(ceilf(ExerciseData.duration(id))), 120, UI.CYAN)
	_box.add_child(_count_label)
	_rep_label = UI.label("", 32, Color.WHITE)
	_box.add_child(_rep_label)
	_start_btn = _btn("Start", _begin, UI.CYAN.darkened(0.3))
	_box.add_child(_wrap("Honor system: do the real exercise. The game only times it.", 22, UI.LAV))
	_btn("Back", func(): _show_list(), UI.PANEL, Vector2(300, 60))

func _pay() -> int:
	return int(roundf(float(_ex["coins"]) * (SaveManager.FEVER_MULT if SaveManager.fever_active() else 1.0)))

func _begin() -> void:
	_running = true
	_elapsed = 0.0
	_start_btn.disabled = true
	_start_btn.text = "Go!"

func _process(delta: float) -> void:
	tick(delta)

## Public so tests can drive the clock.
func tick(delta: float) -> void:
	if not _running or _state != "guide":
		return
	_elapsed += delta
	var total := ExerciseData.duration(String(_ex["id"]))
	var left := maxf(total - _elapsed, 0.0)
	_count_label.text = "%d" % int(ceilf(left))
	if int(_ex["reps"]) > 0:
		var rep := mini(int(_elapsed / float(_ex["secs_per_rep"])) + 1, int(_ex["reps"]))
		_rep_label.text = "Rep %d / %d" % [rep, int(_ex["reps"])]
	else:
		_rep_label.text = "Hold steady..."
	if _elapsed >= total:
		_running = false
		_finish()

func claim_available() -> bool:
	return _state == "claim"

func _finish() -> void:
	_state = "claim"
	_count_label.text = "0"
	_rep_label.text = "Great work!"
	_start_btn.text = "Claim +%d coins" % _pay()
	_start_btn.disabled = false
	for c in _start_btn.pressed.get_connections():
		_start_btn.pressed.disconnect(c["callable"])
	_start_btn.pressed.connect(_claim)
	AudioManager.play("perfect")

func _claim() -> void:
	_last_claim = SaveManager.claim_exercise(String(_ex["id"]))
	_show_reward()

func _show_reward() -> void:
	_state = "reward"
	_clear()
	_box.add_child(UI.label("+%d coins!" % _last_claim, 90, UI.GOLD))
	_box.add_child(UI.label(_status_line(), 28, UI.CYAN))
	if AdService.available():
		_btn("Watch an ad to double", func(): AdService.show_rewarded("exercise_double", func(): SaveManager.add_coins(_last_claim)), UI.PURPLE)
	_btn("More training", _show_list, UI.PURPLE)
	_btn("Menu", func(): back.emit(), UI.PANEL)
