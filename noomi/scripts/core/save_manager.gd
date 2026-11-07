extends Node
## Versioned local save data (autoload). Validates everything it loads.

const SAVE_PATH := "user://noomi_save.json"
const SAVE_VERSION := 1
const LEVEL_COUNT := 10

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

func level_entry(idx: int) -> Dictionary:
	return data["levels"].get(str(idx), {"score": 0, "stars": 0})

## Returns true when score beats the previous best.
func record_level(idx: int, score: int, stars: int, completed: bool) -> bool:
	var e: Dictionary = level_entry(idx).duplicate()
	var new_best := score > int(e["score"])
	if new_best:
		e["score"] = score
	e["stars"] = maxi(int(e["stars"]), stars)
	data["levels"][str(idx)] = e
	if completed:
		data["unlocked"] = maxi(int(data["unlocked"]), mini(idx + 2, LEVEL_COUNT))
		data["coins"] = int(data["coins"]) + 10 + stars * 5
	save()
	return new_best

func record_rush(score: int) -> bool:
	var nb := score > int(data["rush_best"])
	if nb:
		data["rush_best"] = score
	data["coins"] = int(data["coins"]) + score / 100
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
