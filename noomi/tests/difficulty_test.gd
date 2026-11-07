extends Node
## Statistical difficulty check:  godot --headless --path . tests/difficulty_test.tscn
## Bots play many flights. "novice" does nothing after release, "extender" only brakes the spin
## (what the tutorial teaches), "skilled" also corrects its angle before landing.
const PlayerScript := preload("res://scripts/player/player.gd")
const LevelData := preload("res://scripts/core/level_data.gd")
const InputSetup := preload("res://scripts/core/input_setup.gd")
const DT := 1.0 / 60.0
const TRIALS := 60
const REACTION_FRAMES := 9
const QUICK_FRAMES := 3
var _hist: Array = []

func _ready() -> void:
	InputSetup.ensure()
	var failures := 0
	var rate := {}
	for d in [0.5, 1.0, 1.4]:
		for skill in ["novice", "extender", "tapper", "quick"]:
			var counts := {"perfect": 0, "clean": 0, "unstable": 0, "fall": 0, "timeout": 0}
			for i in TRIALS:
				counts[_trial(skill, d, i + 1)] += 1
			var good := float(counts["perfect"] + counts["clean"]) / float(TRIALS)
			rate["%s_%.1f" % [skill, d]] = good
			print("difficulty %.1f  %-9s  good=%3d%%  %s" % [d, skill, int(good * 100.0), counts])
	# Expectations: friendly level 1, "not every flight is clean" at normal difficulty,
	# harder levels hurt, and counter-tapping a gust is a real skill that helps.
	if rate["novice_0.5"] < 0.5: failures += 1; print("FAIL level-1 style flights too hard for a first-time player")
	if rate["extender_0.5"] < 0.85: failures += 1; print("FAIL level-1 style flights too hard for a beginner")
	if rate["extender_1.0"] > 0.85: failures += 1; print("FAIL normal difficulty too easy (every flight is clean)")
	if rate["extender_1.0"] < 0.35: failures += 1; print("FAIL normal difficulty too brutal")
	if rate["novice_1.0"] > 0.25: failures += 1; print("FAIL doing nothing should rarely work at normal difficulty")
	if rate["extender_1.4"] > rate["extender_0.5"] - 0.25: failures += 1; print("FAIL hard difficulty is not clearly harder")
	if rate["tapper_1.0"] < rate["extender_1.0"]: failures += 1; print("FAIL counter-tapping does not help at normal difficulty")
	if rate["quick_1.4"] < 0.5: failures += 1; print("FAIL hard difficulty not solvable for a quick player")
	print("DIFFICULTY TEST DONE failures=", failures)
	get_tree().quit(failures)

func _trial(skill: String, difficulty: float, seed_i: int) -> String:
	seed(seed_i * 7919)
	var p = PlayerScript.new()
	add_child(p)
	p.setup(LevelData.levels()[1])
	p.difficulty = difficulty
	p.theta = 0.7
	p.omega = 5.0
	var out := []
	p.landed.connect(func(r, _i): out.append(r))
	p.queue_grab()
	p._physics_process(DT)
	var t := 0
	_pulse = 0
	_cool = 0
	_hist.clear()
	while out.is_empty() and t < 900:
		_hist.append([p.rot, p.rot_vel])
		_bot(p, skill)
		p._physics_process(DT)
		t += 1
	for a in ["extend", "flip_back", "flip_front"]:
		Input.action_release(a)
	p.queue_free()
	return out[0] if not out.is_empty() else "timeout"

var _pulse := 0
var _cool := 0

func _bot(p, skill: String) -> void:
	if skill == "novice":
		return
	var h: float = p._height_above()
	if skill == "tapper" or skill == "quick":
		var lag := REACTION_FRAMES if skill == "tapper" else QUICK_FRAMES
		if _pulse > 0:
			_pulse -= 1
		var seen: Array = _hist[maxi(_hist.size() - 1 - lag, 0)]
		var rv: float = seen[1]
		var e: float = wrapf(float(seen[0]), -PI, PI)
		_cool = maxi(_cool - 1, 0)
		if _pulse == 0:
			Input.action_release("flip_back")
			Input.action_release("flip_front")
			if _cool == 0 and absf(rv) < 1.2 and absf(e) > 0.3 and h > 70.0 and h < 420.0:
				_pulse = 5
				_cool = 14 if skill == "tapper" else 8
				if e > 0.0:
					Input.action_press("flip_back")
				else:
					Input.action_press("flip_front")
		if _pulse > 0:
			Input.action_release("extend")
			return
	Input.action_press("extend")
