extends Node
## Does a real backflip still register and score, with wind enabled?  godot --headless --path . tests/flip_test.tscn
const PlayerScript := preload("res://scripts/player/player.gd")
const LevelData := preload("res://scripts/core/level_data.gd")
const ScoreManager := preload("res://scripts/gameplay/score_manager.gd")
const InputSetup := preload("res://scripts/core/input_setup.gd")
const DT := 1.0 / 60.0

func _ready() -> void:
	InputSetup.ensure()
	var failures := 0
	var tricks := 0
	var scored := 0
	var false_tricks := 0
	var n := 40
	for i in n:
		seed(i * 31 + 5)
		var r := _flight(true)
		if "Backflip" in r["tricks"]: tricks += 1
		if r["score"] > 0: scored += 1
		var q := _flight(false)
		if q["tricks"].size() > 0: false_tricks += 1
	print("backflip registered in %d/%d flights, scored in %d/%d, tricks from NOT flipping: %d" % [tricks, n, scored, n, false_tricks])
	if tricks < int(n * 0.5): failures += 1; print("FAIL backflip rarely registers")
	if false_tricks > 0: failures += 1; print("FAIL trick awarded without flipping")
	print("FLIP TEST DONE failures=", failures)
	get_tree().quit(failures)

func _flight(do_flip: bool) -> Dictionary:
	var p = PlayerScript.new()
	add_child(p)
	p.setup(LevelData.levels()[1])
	p.difficulty = 1.0
	var sm = ScoreManager.new()
	var landed := []
	p.flight_ended.connect(func(sum, how): sm.bank_flight(sum, how))
	p.landed.connect(func(res, _i): landed.append(res); sm.apply_landing(res))
	p.theta = 0.7
	p.omega = 5.0
	p.queue_grab()
	p._physics_process(DT)
	var t := 0
	while landed.is_empty() and t < 900:
		if do_flip and p.flips_progress() < 0.65:
			Input.action_press("flip_back"); Input.action_press("tuck"); Input.action_release("extend")
		else:
			Input.action_release("flip_back"); Input.action_release("tuck"); Input.action_press("extend")
		p._physics_process(DT)
		t += 1
	for a in ["flip_back", "tuck", "extend"]:
		Input.action_release(a)
	p.queue_free()
	return {"tricks": sm.tricks, "score": sm.score}
