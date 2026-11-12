extends Node
## Gameplay-level simulation (manual stepping, no real-time waiting):
##   godot --headless --path . tests/sim_test.tscn
const Gameplay := preload("res://scripts/gameplay/gameplay.gd")
const InputSetup := preload("res://scripts/core/input_setup.gd")
const DT := 1.0 / 60.0

func _ready() -> void:
	Gameplay.time_control = false
	InputSetup.ensure()
	_run.call_deferred()

func _make(mode: String, idx: int):
	var g = Gameplay.new()
	g.setup(mode, idx)
	add_child(g)
	await get_tree().process_frame
	await get_tree().process_frame
	return g

func _release(p) -> void:
	p.theta = 0.7
	p.omega = 5.0
	p.queue_grab()
	p._physics_process(DT)

func _run() -> void:
	var failures := 0
	# 1) Backflip on level 2: score + trick name, landing reported once.
	seed(11)
	var g = await _make("campaign", 1)
	var p = g.player
	p.difficulty = 0.5
	var res := []
	p.landed.connect(func(r, _i): res.append(r))
	_release(p)
	if p.state != p.State.AIR: failures += 1; print("FAIL release")
	var t := 0
	while res.is_empty() and t < 900:
		if p.flips_progress() < 0.65:
			Input.action_press("flip_back"); Input.action_press("tuck"); Input.action_release("extend")
		else:
			Input.action_release("flip_back"); Input.action_release("tuck"); Input.action_press("extend")
		p._physics_process(DT)
		t += 1
	for a in ["flip_back", "tuck", "extend"]:
		Input.action_release(a)
	print("LANDING1: ", res, " score=", g.score.score, " tricks=", g.score.tricks)
	if res.size() != 1: failures += 1; print("FAIL landing reported ", res.size(), " times")
	var s0: int = g.score.score
	for i in 180:
		p._physics_process(DT)
	if g.score.score != s0: failures += 1; print("FAIL duplicate scoring")
	if res[0] != "fall" and not ("Backflip" in g.score.tricks): failures += 1; print("FAIL landed but no Backflip scored")
	# 2) Restart restores the initial state.
	g.score.score = 123
	g._start_run()
	if g.score.score != 0 or p.state != p.State.HANG: failures += 1; print("FAIL restart")
	g.queue_free()
	await get_tree().process_frame

	# 3) Doing nothing on a hard level must never score trick points.
	seed(3)
	g = await _make("campaign", 8)
	p = g.player
	res = []
	p.landed.connect(func(r, _i): res.append(r))
	_release(p)
	t = 0
	while res.is_empty() and t < 900:
		p._physics_process(DT)
		t += 1
	print("LANDING3 (no input, hard level): ", res, " tricks=", g.score.tricks)
	if g.score.tricks.size() > 0: failures += 1; print("FAIL tricks without flipping")
	g.queue_free()
	await get_tree().process_frame

	# 4) Regrab on level 5.
	g = await _make("campaign", 4)
	p = g.player
	var grabs := []
	p.grabbed.connect(func(_r, i): grabs.append(i))
	_release(p)
	t = 0
	while grabs.is_empty() and p.state == p.State.AIR and t < 300:
		if p.near_bar != -1:
			p.queue_grab()
		p._physics_process(DT)
		t += 1
	print("REGRAB: grabs=", grabs, " state=", p.state)
	g.queue_free()
	await get_tree().process_frame

	# 5) Save sanitizing.
	var bad = SaveManager._sanitize({"unlocked": 99, "levels": {"0": {"score": -5, "stars": 9}}, "settings": "x"})
	if bad["unlocked"] != 10 or bad["levels"]["0"]["stars"] != 3 or bad["levels"]["0"]["score"] != 0: failures += 1; print("FAIL sanitize")
	print("SIM DONE failures=", failures)
	get_tree().quit(failures)
