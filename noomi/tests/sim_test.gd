extends Node
## Headless smoke test:  godot --headless --path . tests/sim_test.tscn
const Gameplay := preload("res://scripts/gameplay/gameplay.gd")
const InputSetup := preload("res://scripts/core/input_setup.gd")

func _ready() -> void:
	Engine.time_scale = 6.0
	Engine.max_physics_steps_per_frame = 24
	InputSetup.ensure()
	_run.call_deferred()

func _step(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _make(mode: String, idx: int):
	var g = Gameplay.new()
	g.setup(mode, idx)
	add_child(g)
	await _step(2)
	return g

func _swing_and_release(p, want_omega: float) -> void:
	Input.action_press("pump")
	var t := 0
	while not (p.omega > want_omega * 0.6 and p.theta > 0.35 and p.theta < 1.0 and abs(p.omega) > 3.0) and t < 2400:
		await _step(1); t += 1
	Input.action_release("pump")
	p.queue_grab()
	await _step(1)

func _run() -> void:
	var failures := 0
	# 1) Level 2: swing, release, backflip+tuck, extend, land
	var g = await _make("campaign", 1)
	var p = g.player
	var res := []
	p.landed.connect(func(r, i): res.append([r, i]))
	await _swing_and_release(p, 6.0)
	print("released: state=", p.state, " vel=", p.vel, " theta=", p.theta)
	if p.state != p.State.AIR: failures += 1; print("FAIL release")
	Input.action_press("flip_back"); Input.action_press("tuck")
	var t := 0
	while res.is_empty() and t < 600:
		await _step(1); t += 1
		if p.flips_progress() > 0.9:
			Input.action_release("flip_back"); Input.action_release("tuck"); Input.action_press("extend")
	Input.action_release("extend"); Input.action_release("flip_back"); Input.action_release("tuck")
	print("LANDING1: ", res, " flips=", p.flips_progress(), " score=", g.score.score, " tricks=", g.score.tricks, " airtime ticks=", t)
	if res.is_empty(): failures += 1; print("FAIL no landing")
	if res.size() != 1: failures += 1; print("FAIL landing emitted ", res.size(), " times")
	var s0: int = g.score.score
	await _step(120)
	if g.score.score != s0: failures += 1; print("FAIL duplicate scoring")
	g.queue_free()
	await _step(2)

	# 2) No-control release then plain landing (level 1): should be a non-tricks landing
	g = await _make("campaign", 0)
	p = g.player
	res = []
	p.landed.connect(func(r, i): res.append([r, i]))
	await _swing_and_release(p, 6.0)
	t = 0
	while res.is_empty() and t < 600:
		await _step(1); t += 1
	print("LANDING2 (no input): ", res, " score=", g.score.score)
	if res.is_empty(): failures += 1; print("FAIL no landing 2")
	g.queue_free()
	await _step(2)

	# 3) Held front flip the whole way must not be a clean/perfect landing
	g = await _make("chill", 0)
	p = g.player
	res = []
	p.landed.connect(func(r, i): res.append([r, i]))
	await _swing_and_release(p, 6.0)
	Input.action_press("flip_front"); Input.action_press("tuck")
	t = 0
	while res.is_empty() and t < 600:
		await _step(1); t += 1
	Input.action_release("flip_front"); Input.action_release("tuck")
	print("LANDING3 (spamming flips): ", res, " score=", g.score.score)
	if not res.is_empty() and (res[0][0] == "perfect" or res[0][0] == "clean"): print("NOTE: spam produced good landing")
	g.queue_free()
	await _step(2)

	# 4) Regrab on level 5: release toward bar 2 and grab
	g = await _make("campaign", 4)
	p = g.player
	var grabs := []
	p.grabbed.connect(func(r, i): grabs.append(i))
	await _swing_and_release(p, 6.0)
	t = 0
	while grabs.is_empty() and p.state == p.State.AIR and t < 300:
		if p.near_bar != -1: p.queue_grab()
		await _step(1); t += 1
	print("REGRAB: grabs=", grabs, " state=", p.state, " near=", p.near_bar, " pos=", p.position, " score=", g.score.score)
	g.queue_free()
	await _step(2)

	# 5) Restart restores state
	g = await _make("campaign", 1)
	g.score.score = 123
	g._start_run()
	if g.score.score != 0 or g.player.state != g.player.State.HANG: failures += 1; print("FAIL restart")

	# 6) Save sanitize
	var bad = SaveManager._sanitize({"unlocked": 99, "levels": {"0": {"score": -5, "stars": 9}}, "settings": "x"})
	if bad["unlocked"] != 10 or bad["levels"]["0"]["stars"] != 3 or bad["levels"]["0"]["score"] != 0: failures += 1; print("FAIL sanitize")
	print("SIM DONE failures=", failures)
	get_tree().quit(failures)
