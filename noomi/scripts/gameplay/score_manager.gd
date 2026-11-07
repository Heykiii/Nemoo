extends RefCounted
## Scoring + combo. Points are banked once per flight (regrab / landing), never per button press,
## so tricks only score when the measured rotation was actually completed.

const FLIP_POINTS := 100
const TWIST_HALF_POINTS := 80
const AIRTIME_PER_SEC := 40.0
const REGRAB_BONUS := 120
const LANDING_POINTS := {"perfect": 500, "clean": 250, "unstable": 60, "fall": 0}
const MULT_STEP := 0.5
const MULT_CAP := 5.0
const BREAK_ON_PLAIN_REGRAB := true

var score := 0
var combo := 0
var best_combo := 0
var tricks: Array = []
var regrabs := 0
var max_flips := 0
var max_twist := 0
var trick_total := 0

func multiplier() -> float:
	return minf(1.0 + MULT_STEP * float(maxi(combo - 1, 0)), MULT_CAP)

func reset_combo() -> void:
	combo = 0

static func trick_name(flips: int, dir: int, halves: int) -> String:
	var base := ""
	if flips >= 1:
		var d := "Backflip" if dir < 0 else "Frontflip"
		match flips:
			1: base = d
			2: base = "Double " + d
			3: base = "Triple " + d
			_: base = "%dx %s" % [flips, d]
	var tw := ""
	match halves:
		0: tw = ""
		1: tw = "Half Twist"
		2: tw = "Full Twist"
		3: tw = "Twist and a Half"
		4: tw = "Double Twist"
		_: tw = "%d Half Twists" % halves
	if base == "":
		return tw
	if tw == "":
		return base
	return "%s with %s" % [base, tw]

static func trick_desc(flips: int, dir: int, halves: int) -> String:
	var parts: Array = []
	if flips > 0:
		parts.append("%d %s rotation(s)" % [flips, "backward" if dir < 0 else "forward"])
	if halves > 0:
		parts.append("%d half twist(s)" % halves)
	return "Complete " + " and ".join(parts) + " in one flight."

## Returns {points, trick, desc, combo, mult, regrab}
func bank_flight(summary: Dictionary, how: String) -> Dictionary:
	var res := {"points": 0, "trick": "", "desc": "", "combo": combo, "mult": multiplier(), "regrab": false, "flips": 0}
	if how == "fall":
		reset_combo()
		res["combo"] = 0
		return res
	var flips: int = summary["flips"]
	var halves: int = summary["halves"]
	var dir: int = summary["dir"]
	var pts := 0.0
	if flips >= 1 or halves >= 1:
		combo += 1
		best_combo = maxi(best_combo, combo)
		pts += float(FLIP_POINTS * flips) * (1.0 + 0.5 * float(maxi(flips - 1, 0)))
		pts += float(TWIST_HALF_POINTS * halves)
		if flips > 0 and halves > 0:
			pts *= 1.25
		pts += float(summary["airtime"]) * AIRTIME_PER_SEC
		pts *= multiplier()
		res["trick"] = trick_name(flips, dir, halves)
		res["desc"] = trick_desc(flips, dir, halves)
		res["flips"] = flips
		tricks.append(res["trick"])
		trick_total += 1
		max_flips = maxi(max_flips, flips)
		max_twist = maxi(max_twist, halves)
	elif how == "regrab" and BREAK_ON_PLAIN_REGRAB:
		reset_combo()
	if how == "regrab" and summary["different_bar"]:
		pts += REGRAB_BONUS
		regrabs += 1
		res["regrab"] = true
	res["points"] = int(roundf(pts))
	res["combo"] = combo
	res["mult"] = multiplier()
	score += int(res["points"])
	return res

func apply_landing(result: String) -> int:
	var p: int = LANDING_POINTS.get(result, 0)
	score += p
	if result == "fall":
		reset_combo()
	return p
