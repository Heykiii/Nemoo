extends Node
## Story data, story flow and game speed:  godot --headless --path . tests/story_test.tscn
const StoryData := preload("res://scripts/core/story_data.gd")
const LevelData := preload("res://scripts/core/level_data.gd")
const CharacterData := preload("res://scripts/core/character_data.gd")
const Gameplay := preload("res://scripts/gameplay/gameplay.gd")
const KEYS := ["body", "pants", "accent", "skin", "hair", "shoe", "kind", "name"]

func _ready() -> void:
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _run() -> void:
	var failures := 0
	SaveManager.data = SaveManager.default_data()
	# --- story data
	if StoryData.count() != SaveManager.LEVEL_COUNT: failures += 1; print("FAIL chapter count")
	var levels := LevelData.levels()
	for i in StoryData.count():
		if levels[i]["name"] != StoryData.title(i): failures += 1; print("FAIL level name != chapter title ", i)
		for kind in ["intro", "outro"]:
			var lines: Array = StoryData.intro_lines(i) if kind == "intro" else StoryData.outro_lines(i)
			if lines.is_empty(): failures += 1; print("FAIL empty ", kind, " ", i)
			for line in lines:
				var who: String = line[0]
				var txt: String = line[1]
				if txt.is_empty() or txt.length() > 170: failures += 1; print("FAIL bad text length ", i, " ", txt.length())
				var pal: Dictionary = StoryData.palette_for(who)
				for k in KEYS:
					if not pal.has(k): failures += 1; print("FAIL palette missing ", k, " for ", who)
				if who != "hero" and who != "baron" and who != String(pal["id"]): failures += 1; print("FAIL unknown speaker ", who)
	# --- speed setting
	SaveManager.data["speed"] = 1
	if absf(SaveManager.speed_scale() - 0.75) > 0.001: failures += 1; print("FAIL default speed")
	SaveManager.cycle_speed(); SaveManager.cycle_speed(); SaveManager.cycle_speed()
	if int(SaveManager.data["speed"]) != 1: failures += 1; print("FAIL speed cycle")
	var d = SaveManager._sanitize({"speed": 9, "story_seen": {"intro_0": true, "x": false, "outro_9": 1}})
	if d["speed"] != 2 or not d["story_seen"].has("intro_0") or d["story_seen"].has("x") or not d["story_seen"].has("outro_9"): failures += 1; print("FAIL sanitize speed/story")
	# --- flow: intro plays once, then straight into the level; time slows down; resets on exit
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(3)
	main._play_campaign(0)
	await _frames(2)
	if main.current.get_script() != main.StoryScreen: failures += 1; print("FAIL intro story not shown first time")
	main.current._finish()
	await _frames(40)
	if main.current.get_script() != main.Gameplay: failures += 1; print("FAIL gameplay did not start after story")
	if not SaveManager.story_seen("intro_0"): failures += 1; print("FAIL intro not remembered")
	var ts := Engine.time_scale
	print("time_scale on the ground: ", ts)
	if absf(ts - 0.75) > 0.03: failures += 1; print("FAIL time scale not ~0.75")
	var g = main.current
	g.player.omega = 4.0
	g.player.queue_grab()
	await _frames(90)
	print("time_scale in the air: ", Engine.time_scale, " airborne=", g.player.is_airborne())
	if g.player.is_airborne() and Engine.time_scale > 0.75 * 0.85 + 0.03: failures += 1; print("FAIL no air focus slow-down")
	main._show_menu()
	await _frames(2)
	if absf(Engine.time_scale - 1.0) > 0.001: failures += 1; print("FAIL time scale not restored in menu")
	main._play_campaign(0)
	await _frames(40)
	if main.current.get_script() != main.Gameplay: failures += 1; print("FAIL intro replayed")
	# --- flow: outro shown once, before results
	var r := {"mode": "campaign", "level_index": 0, "level_name": "x", "score": 10, "tricks": [], "landing": "clean", "best_combo": 0,
		"new_best": false, "personal_best": 10, "stars": 1, "completed": true, "reason": "ok", "has_next": true}
	main._show_results(r)
	await _frames(2)
	if main.current.get_script() != main.StoryScreen: failures += 1; print("FAIL outro not shown")
	main.current._finish()
	await _frames(2)
	if main.current.get_script() != main.ResultsScreen: failures += 1; print("FAIL results not shown after outro")
	main._show_results(r)
	await _frames(2)
	if main.current.get_script() != main.ResultsScreen: failures += 1; print("FAIL outro replayed")
	var r2 = r.duplicate()
	r2["completed"] = false
	r2["level_index"] = 3
	main._show_results(r2)
	await _frames(2)
	if main.current.get_script() != main.ResultsScreen: failures += 1; print("FAIL outro shown for failed level")
	print("STORY TEST DONE failures=", failures)
	get_tree().quit(failures)
