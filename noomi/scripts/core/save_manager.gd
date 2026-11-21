extends Node
## Versioned local save data (autoload). Validates everything it loads.

const SAVE_PATH := "user://noomi_save.json"
const SAVE_VERSION := 1
const LEVEL_COUNT := 10

## Game speed presets (Engine.time_scale). Slower = more time to press FLIP / TUCK / EXTEND.
const SPEED_NAMES := ["Relaxed", "Slow", "Normal"]
const SPEED_SCALES := [0.6, 0.75, 1.0]

const ACHIEVEMENTS := {
	"first_landing": "First successful landing",
	"first_rotation": "First full rotation",
	"three_clean": "Three clean landings",
	"five_streak": "Five clean landings in a row",
	"first_regrab": "First regrab",
	"first_combo": "First completed combo",
	"personal_best": "Personal best",
}

const CharacterData := preload("res://scripts/core/character_data.gd")
const CharacterStats := preload("res://scripts/core/character_stats.gd")
const ExerciseData := preload("res://scripts/core/exercise_data.gd")

const FEVER_DAYS := 3
const FEVER_MULT := 1.5
const CHALK_BOX_COINS := 50

## Tests set this ("YYYY-MM-DD") to fake the date.
var date_override := ""
## Coins paid out by the most recent record_level / record_rush call.
var last_coins := 0

var data: Dictionary = {}

func _ready() -> void:
	load_data()

func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"unlocked": 1,
		"levels": {},
		"coins": 0,
		"character": 0,
		"settings": {"sound": true, "music": true, "haptics": true, "reduce_motion": false},
		"tutorial_done": false,
		"tricks": {},
		"achievements": {},
		"rush_best": 0,
		"clean_total": 0,
		"clean_streak": 0,
		"speed": 1,
		"story_seen": {},
		"owned": {"gymnast": true},
		"chill_character": 0,
		"exercise": {"claims": {}, "streak": 0, "last_day": ""},
		"chalk_day": "",
	}

func load_data() -> void:
	data = default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file malformed; using defaults.")
		return
	data = _sanitize(parsed)

func _sanitize(raw: Dictionary) -> Dictionary:
	var d := default_data()
	d["unlocked"] = clampi(int(raw.get("unlocked", 1)), 1, LEVEL_COUNT)
	d["coins"] = maxi(int(raw.get("coins", 0)), 0)
	d["character"] = clampi(int(raw.get("character", 0)), 0, CharacterData.LIST.size() - 1)
	d["tutorial_done"] = bool(raw.get("tutorial_done", false))
	d["rush_best"] = maxi(int(raw.get("rush_best", 0)), 0)
	d["clean_total"] = maxi(int(raw.get("clean_total", 0)), 0)
	d["clean_streak"] = maxi(int(raw.get("clean_streak", 0)), 0)
	d["speed"] = clampi(int(raw.get("speed", 1)), 0, SPEED_SCALES.size() - 1)
	var ow = raw.get("owned", {})
	if typeof(ow) == TYPE_DICTIONARY:
		for k in ow:
			if bool(ow[k]) and CharacterStats.STATS.has(str(k)):
				d["owned"][str(k)] = true
	# The selected character must be one the player owns.
	if not d["owned"].has(str(CharacterData.LIST[int(d["character"])]["id"])):
		d["character"] = 0
	d["chill_character"] = clampi(int(raw.get("chill_character", 0)), 0, CharacterData.LIST.size() - 1)
	d["chalk_day"] = str(raw.get("chalk_day", ""))
	var ex = raw.get("exercise", {})
	if typeof(ex) == TYPE_DICTIONARY:
		d["exercise"]["streak"] = maxi(int(ex.get("streak", 0)), 0)
		d["exercise"]["last_day"] = str(ex.get("last_day", ""))
		var cl = ex.get("claims", {})
		if typeof(cl) == TYPE_DICTIONARY:
			for k in cl:
				d["exercise"]["claims"][str(k)] = str(cl[k])
	var ss = raw.get("story_seen", {})
	if typeof(ss) == TYPE_DICTIONARY:
		for k in ss:
			if bool(ss[k]):
				d["story_seen"][str(k)] = true
	var lv = raw.get("levels", {})
	if typeof(lv) == TYPE_DICTIONARY:
		for key in lv:
			var e = lv[key]
			if typeof(e) == TYPE_DICTIONARY:
				d["levels"][str(key)] = {
					"score": maxi(int(e.get("score", 0)), 0),
					"stars": clampi(int(e.get("stars", 0)), 0, 3),
				}
	var st = raw.get("settings", {})
	if typeof(st) == TYPE_DICTIONARY:
		for k in d["settings"]:
			d["settings"][k] = bool(st.get(k, d["settings"][k]))
	var tr = raw.get("tricks", {})
	if typeof(tr) == TYPE_DICTIONARY:
		for k in tr:
			var e2 = tr[k]
			if typeof(e2) == TYPE_DICTIONARY:
				d["tricks"][str(k)] = {"count": maxi(int(e2.get("count", 1)), 1), "desc": str(e2.get("desc", ""))}
	var ac = raw.get("achievements", {})
	if typeof(ac) == TYPE_DICTIONARY:
		for k in ac:
			if ACHIEVEMENTS.has(str(k)):
				d["achievements"][str(k)] = true
	return d

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write save file.")
		return
	f.store_string(JSON.stringify(data))

func setting(key: String) -> bool:
	return bool(data["settings"].get(key, false))

func toggle_setting(key: String) -> void:
	data["settings"][key] = not setting(key)
	save()

func character_palette() -> Dictionary:
	return CharacterData.LIST[int(data["character"])]

func character_id() -> String:
	return str(CharacterData.LIST[int(data["character"])]["id"])

## Character used in a given mode. Chill Mode lets you play ANY hero for free.
func palette_for_mode(mode: String) -> Dictionary:
	if mode == "chill":
		return CharacterData.LIST[int(data["chill_character"])]
	return character_palette()

func is_owned(id: String) -> bool:
	return data["owned"].has(id)

## Spends coins and unlocks the hero. Returns false if already owned or too poor.
func buy_character(id: String) -> bool:
	if is_owned(id) or not CharacterStats.STATS.has(id):
		return false
	var c := CharacterStats.cost(id)
	if int(data["coins"]) < c:
		return false
	data["coins"] = int(data["coins"]) - c
	data["owned"][id] = true
	save()
	return true

func select_character(idx: int) -> bool:
	var id := str(CharacterData.LIST[idx]["id"])
	if not is_owned(id):
		return false
	data["character"] = idx
	save()
	return true

# ---------------------------------------------------------------- dates, streak, coins
func today() -> String:
	if date_override != "":
		return date_override
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) + bias)

func _day_before(day: String) -> String:
	var t := Time.get_unix_time_from_datetime_string(day + "T12:00:00")
	return Time.get_date_string_from_unix_time(int(t) - 86400)

func streak() -> int:
	var ex: Dictionary = data["exercise"]
	var last := str(ex["last_day"])
	if last == today() or last == _day_before(today()):
		return int(ex["streak"])
	return 0

## "Gold Chalk Fever": 3+ days in a row of training -> x1.5 on exercise and level coins.
func fever_active() -> bool:
	return streak() >= FEVER_DAYS

func coin_mult(char_id: String = "") -> float:
	var id := char_id if char_id != "" else character_id()
	var m := CharacterStats.mult(id, "coins")
	if fever_active():
		m *= FEVER_MULT
	return m

func add_coins(n: int) -> void:
	data["coins"] = maxi(int(data["coins"]) + n, 0)
	save()

func exercise_done_today(ex_id: String) -> bool:
	return str(data["exercise"]["claims"].get(ex_id, "")) == today()

## Pays the exercise reward once per exercise per day. Returns coins paid (0 if already claimed).
func claim_exercise(ex_id: String) -> int:
	if exercise_done_today(ex_id):
		return 0
	var def: Dictionary = ExerciseData.get_def(ex_id)
	if def.is_empty():
		return 0
	var ex: Dictionary = data["exercise"]
	var t := today()
	if str(ex["last_day"]) != t:
		ex["streak"] = (int(ex["streak"]) + 1) if str(ex["last_day"]) == _day_before(t) else 1
		ex["last_day"] = t
	var pay := int(roundf(float(def["coins"]) * (FEVER_MULT if fever_active() else 1.0)))
	ex["claims"][ex_id] = t
	data["coins"] = int(data["coins"]) + pay
	save()
	return pay

func chalk_box_ready() -> bool:
	return str(data["chalk_day"]) != today()

func open_chalk_box() -> int:
	if not chalk_box_ready():
		return 0
	data["chalk_day"] = today()
	data["coins"] = int(data["coins"]) + CHALK_BOX_COINS
	save()
	return CHALK_BOX_COINS

func level_entry(idx: int) -> Dictionary:
	return data["levels"].get(str(idx), {"score": 0, "stars": 0})

## Returns true when score beats the previous best.
func record_level(idx: int, score: int, stars: int, completed: bool) -> bool:
	last_coins = 0
	var e: Dictionary = level_entry(idx).duplicate()
	var new_best := score > int(e["score"])
	if new_best:
		e["score"] = score
	e["stars"] = maxi(int(e["stars"]), stars)
	data["levels"][str(idx)] = e
	if completed:
		data["unlocked"] = maxi(int(data["unlocked"]), mini(idx + 2, LEVEL_COUNT))
		last_coins = int(roundf(float(10 + stars * 5) * coin_mult()))
		data["coins"] = int(data["coins"]) + last_coins
	save()
	return new_best

func record_rush(score: int) -> bool:
	var nb := score > int(data["rush_best"])
	if nb:
		data["rush_best"] = score
	last_coins = int(roundf(float(score / 100) * coin_mult()))
	data["coins"] = int(data["coins"]) + last_coins
	save()
	return nb

func record_trick(trick_name: String, desc: String) -> void:
	var e: Dictionary = data["tricks"].get(trick_name, {"count": 0, "desc": desc})
	e["count"] = int(e["count"]) + 1
	data["tricks"][trick_name] = e
	save()

## Returns true if newly unlocked.
func unlock_achievement(id: String) -> bool:
	if not ACHIEVEMENTS.has(id) or data["achievements"].has(id):
		return false
	data["achievements"][id] = true
	save()
	return true

## Updates landing counters. Returns list of newly unlocked achievement ids.
func register_landing(result: String) -> Array:
	var out: Array = []
	if result == "fall":
		data["clean_streak"] = 0
	else:
		if unlock_achievement("first_landing"):
			out.append("first_landing")
		if result == "clean" or result == "perfect":
			data["clean_total"] = int(data["clean_total"]) + 1
			data["clean_streak"] = int(data["clean_streak"]) + 1
			if int(data["clean_total"]) >= 3 and unlock_achievement("three_clean"):
				out.append("three_clean")
			if int(data["clean_streak"]) >= 5 and unlock_achievement("five_streak"):
				out.append("five_streak")
		else:
			data["clean_streak"] = 0
	save()
	return out

# ---------------------------------------------------------------- speed + story
func speed_scale() -> float:
	return SPEED_SCALES[int(data["speed"])]

func speed_name() -> String:
	return SPEED_NAMES[int(data["speed"])]

func cycle_speed() -> void:
	data["speed"] = (int(data["speed"]) + 1) % SPEED_SCALES.size()
	save()

func story_seen(key: String) -> bool:
	return data["story_seen"].has(key)

func mark_story(key: String) -> void:
	data["story_seen"][key] = true
	save()
