extends Node
## Economy, exercise, perks and abilities.
const CS := preload("res://scripts/core/character_stats.gd")
const CD := preload("res://scripts/core/character_data.gd")
const Gameplay := preload("res://scripts/gameplay/gameplay.gd")
const SM := preload("res://scripts/gameplay/score_manager.gd")
const ES := preload("res://scripts/ui/exercise_screen.gd")
const AD := preload("res://scripts/core/ad_service.gd")
var fails := 0

func check(c: bool, msg: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", msg)

func _ready() -> void:
	preload("res://scripts/core/input_setup.gd").ensure()
	Gameplay.time_control = false
	SaveManager.data = SaveManager.default_data()
	# --- table covers every hero, costs per design doc
	for ch in CD.LIST:
		check(CS.STATS.has(ch["id"]), "stats for " + ch["id"])
	var want := {"gymnast": 0, "ninja": 500, "chef": 600, "pirate": 1200, "clown": 1500, "viking": 1800, "scientist": 3000, "dino": 3500, "robot": 4000, "wizard": 7500, "astro": 10000}
	for k in want:
		check(CS.cost(k) == want[k], "cost " + k)
	# --- economy
	check(SaveManager.is_owned("gymnast"), "gymnast free")
	check(not SaveManager.buy_character("ninja"), "cannot buy broke")
	SaveManager.add_coins(500)
	check(SaveManager.buy_character("ninja") and SaveManager.data["coins"] == 0, "buy ninja")
	check(not SaveManager.buy_character("ninja"), "no double buy")
	var ni := 3
	check(CD.LIST[ni]["id"] == "ninja" and SaveManager.select_character(ni), "select owned")
	check(not SaveManager.select_character(2), "cannot select locked astro")
	check(SaveManager.palette_for_mode("campaign")["id"] == "ninja", "campaign uses selected")
	SaveManager.data["chill_character"] = 2
	check(SaveManager.palette_for_mode("chill")["id"] == "astro", "chill uses any hero")
	check(not SaveManager.is_owned("astro"), "chill does not unlock")
	# --- sanitize: unowned selection falls back
	var bad := SaveManager.default_data()
	bad["character"] = 2
	var clean := SaveManager._sanitize(bad)
	check(int(clean["character"]) == 0, "sanitize unowned selection")
	# --- exercise + streak + fever
	SaveManager.data = SaveManager.default_data()
	SaveManager.date_override = "2026-11-01"
	check(SaveManager.claim_exercise("squats") == 150, "squats 150")
	check(SaveManager.claim_exercise("squats") == 0, "once per day")
	check(SaveManager.streak() == 1 and not SaveManager.fever_active(), "day1 streak")
	SaveManager.date_override = "2026-11-02"
	check(SaveManager.claim_exercise("jacks") == 150 and SaveManager.streak() == 2, "day2")
	SaveManager.date_override = "2026-11-03"
	check(SaveManager.claim_exercise("plank") == 300, "day3 fever plank 200x1.5")
	check(SaveManager.fever_active(), "fever on")
	check(SaveManager.coin_mult("gymnast") == 1.5, "fever mult")
	check(absf(SaveManager.coin_mult("pirate") - 1.8) < 0.001, "pirate x fever")
	SaveManager.date_override = "2026-11-04"
	check(SaveManager.fever_active(), "streak alive next day")
	SaveManager.date_override = "2026-11-06"
	check(SaveManager.streak() == 0 and not SaveManager.fever_active(), "streak broken")
	check(SaveManager.claim_exercise("squats") == 150 and SaveManager.streak() == 1, "restart streak")
	check(SaveManager.claim_exercise("nonsense") == 0, "unknown exercise")
	check(SaveManager.chalk_box_ready() and SaveManager.open_chalk_box() == 50 and not SaveManager.chalk_box_ready(), "chalk box once")
	# level coins use multiplier
	SaveManager.data = SaveManager.default_data()
	SaveManager.date_override = "2026-12-01"
	SaveManager.data["owned"]["pirate"] = true
	SaveManager.data["character"] = 4
	SaveManager.record_level(0, 500, 2, true)
	check(SaveManager.last_coins == 24 and SaveManager.data["coins"] == 24, "pirate coins 20*1.2 = %d" % SaveManager.last_coins)
	# --- ads honest
	check(not AD.available(), "no ad network")
	# --- exercise screen flow
	SaveManager.data = SaveManager.default_data()
	ES.warmed_up = true
	var scr = ES.new()
	add_child(scr)
	await get_tree().process_frame
	scr._show_guide("squats")
	scr._begin()
	scr.tick(10.0)
	check(not scr.claim_available(), "not done at 10s")
	scr.tick(16.0)
	check(scr.claim_available(), "claim after 25s")
	scr._claim()
	check(SaveManager.data["coins"] == 150, "screen paid 150")
	scr.queue_free()
	# --- score perk
	var sm = SM.new()
	sm.multi_flip_mult = 2.0
	var r2: Dictionary = sm.bank_flight({"flips": 2, "halves": 0, "dir": 1, "airtime": 1.0, "different_bar": true}, "landing")
	var sm1 = SM.new()
	var r1: Dictionary = sm1.bank_flight({"flips": 2, "halves": 0, "dir": 1, "airtime": 1.0, "different_bar": true}, "landing")
	check(r2["points"] == r1["points"] * 2, "astro x2 multi flip")
	var sm3 = SM.new()
	sm3.multi_flip_mult = 2.0
	var rs: Dictionary = sm3.bank_flight({"flips": 1, "halves": 0, "dir": 1, "airtime": 1.0, "different_bar": true}, "landing")
	var rs1: Dictionary = SM.new().bank_flight({"flips": 1, "halves": 0, "dir": 1, "airtime": 1.0, "different_bar": true}, "landing")
	check(rs["points"] == rs1["points"], "single flip unchanged")
	# --- abilities
	var g = Gameplay.new()
	g.setup("chill", 0)
	add_child(g)
	await get_tree().physics_frame
	var p = g.player
	for id in CS.STATS:
		p.set_character(id)
		p.reset(0)
		check(not p.activate_ability(), "no ability while hanging " + id)
		p.omega = 5.0
		p.theta = 0.3
		p._release()
		check(p.state == p.State.AIR and p.can_use_ability(), "ready in air " + id)
		var v0: Vector2 = p.vel
		var fa0: float = p.flip_accum
		check(p.activate_ability(), "activate " + id)
		check(not p.activate_ability(), "once per jump " + id)
		match CS.of(id)["ability"]:
			"dash": check(absf(p.vel.x) > absf(v0.x) + 300.0, "dash")
			"leap": check(p.vel.y < v0.y - 300.0, "leap")
			"extra_flip": check(absf(p.flip_accum - fa0) > 6.0, "extra flip")
			"stabilize": check(p.rot_vel == 0.0, "stabilize")
			"hook": check(p.hook_t > 0.0, "hook")
			"slowmo", "carpet": check(p.slowmo_t > 1.0, "slowmo " + id)
			"float", "zerog", "carpet": check(p.float_t > 0.5, "float " + id)
		# re-arm on next release
		p.reset(0)
		check(p.ability_ready, "re-armed " + id)
	# float actually slows falling
	p.set_character("astro")
	p.reset(0); p.omega = 5.0; p._release(); p.activate_ability()
	var y_before: float = p.vel.y
	for i in 30:
		p._physics_process(1.0 / 60.0)
	check(p.vel.y - y_before < 0.3 * 1200.0 * 0.5 + 40.0, "zero-g slows gravity (dvy=%.0f)" % (p.vel.y - y_before))
	# preview path
	p.set_character("scientist")
	p.reset(0); p.omega = 4.0
	check(p.perk_preview and p.predict_path().size() > 5, "preview path")
	# gymnast baseline untouched
	p.set_character("gymnast")
	check(p.perk_grab == 1.0 and p.perk_pump == 1.0 and p.perk_spin == 1.0 and p.perk_land == 1.0, "gymnast neutral")
	print("POWER TEST ", "OK" if fails == 0 else "FAILED %d" % fails)
	get_tree().quit()
