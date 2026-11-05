extends RefCounted
## Data-driven level definitions. All numbers are tuning values.
## bars: grab points. surfaces: Rect2 whose top edge is walkable.
## target: gold landing zone {x, w, y}. hazards: moving danger circles.
## objective: required stats (flips, twist = half-twists, regrabs, tricks).
## stars: score thresholds for 1/2/3 stars.

const GROUND_Y := 600.0

static func ground(x0: float, x1: float, y: float = GROUND_Y) -> Rect2:
	return Rect2(x0, y, x1 - x0, 400.0)

static func hazard(cx: float, cy: float, ax: float, ay: float, amp: float, spd: float, r: float = 32.0) -> Dictionary:
	return {"center": Vector2(cx, cy), "axis": Vector2(ax, ay), "amp": amp, "speed": spd, "radius": r, "phase": 0.0}

static func levels() -> Array:
	return [
		{"name": "First Swing", "hint": "Hold PUMP, release on the forward swing, land in the gold zone.",
			"bars": [Vector2(450, 250)], "surfaces": [ground(-1000, 3000)],
			"target": {"x": 700.0, "w": 550.0, "y": GROUND_Y}, "hazards": [],
			"objective": {}, "stars": [200, 300, 500]},
		{"name": "First Flip", "hint": "Release, hold BACK FLIP (add TUCK for speed), then EXTEND to land.",
			"bars": [Vector2(450, 250)], "surfaces": [ground(-1000, 3000)],
			"target": {"x": 780.0, "w": 400.0, "y": GROUND_Y}, "hazards": [],
			"objective": {"flips": 1}, "stars": [300, 550, 800]},
		{"name": "Stick It", "hint": "Smaller target. Time your release for a perfect landing.",
			"bars": [Vector2(450, 250)], "surfaces": [ground(-1000, 3000)],
			"target": {"x": 830.0, "w": 220.0, "y": GROUND_Y}, "hazards": [],
			"objective": {}, "stars": [200, 300, 500]},
		{"name": "Half Twist", "hint": "Hold TWIST in the air for a half twist, then land.",
			"bars": [Vector2(450, 250)], "surfaces": [ground(-1000, 3000)],
			"target": {"x": 760.0, "w": 420.0, "y": GROUND_Y}, "hazards": [],
			"objective": {"twist": 1}, "stars": [350, 600, 850]},
		{"name": "Regrab", "hint": "Release toward the second bar and tap GRAB when it glows.",
			"bars": [Vector2(400, 250), Vector2(650, 290)], "surfaces": [ground(-1000, 3000)],
			"target": {"x": 900.0, "w": 450.0, "y": GROUND_Y}, "hazards": [],
			"objective": {"regrabs": 1}, "stars": [400, 650, 900]},
		{"name": "Combo", "hint": "Do a flip between the bars AND a flip on the way down.",
			"bars": [Vector2(400, 250), Vector2(650, 280)], "surfaces": [ground(-1000, 3500)],
			"target": {"x": 950.0, "w": 500.0, "y": GROUND_Y}, "hazards": [],
			"objective": {"tricks": 2, "regrabs": 1}, "stars": [600, 1000, 1400]},
		{"name": "Gap Crossing", "hint": "Swing bar to bar over the pit. Falling in the pit ends the run.",
			"bars": [Vector2(450, 250), Vector2(700, 280), Vector2(950, 310)],
			"surfaces": [ground(-1000, 500), ground(1300, 3500)],
			"target": {"x": 1350.0, "w": 450.0, "y": GROUND_Y}, "hazards": [],
			"objective": {"regrabs": 2}, "stars": [500, 800, 1100]},
		{"name": "Moving Danger", "hint": "Avoid the pink orb as you fly past it.",
			"bars": [Vector2(450, 250)], "surfaces": [ground(-1000, 3000)],
			"target": {"x": 850.0, "w": 450.0, "y": GROUND_Y},
			"hazards": [hazard(700, 430, 1, 0, 160, 2.0)],
			"objective": {}, "stars": [200, 300, 500]},
		{"name": "Platform Hop", "hint": "Land on the raised platform. Two tricks needed.",
			"bars": [Vector2(400, 250), Vector2(650, 290), Vector2(900, 330)],
			"surfaces": [ground(-1000, 1100), Rect2(1150, 500, 600, 500)],
			"target": {"x": 1250.0, "w": 400.0, "y": 500.0}, "hazards": [],
			"objective": {"tricks": 2}, "stars": [700, 1100, 1500]},
		{"name": "Grand Finale", "hint": "Chain bars, dodge the orb, land on the far ground.",
			"bars": [Vector2(400, 250), Vector2(650, 290), Vector2(900, 330), Vector2(1150, 370)],
			"surfaces": [ground(-1000, 500), ground(1500, 3500)],
			"target": {"x": 1650.0, "w": 400.0, "y": GROUND_Y},
			"hazards": [hazard(1330, 450, 0, 1, 110, 2.5)],
			"objective": {"regrabs": 2, "tricks": 2}, "stars": [900, 1400, 1900]},
	]

static func rush_layout() -> Dictionary:
	return {"name": "Playground", "hint": "", "bars": [Vector2(300, 250), Vector2(900, 250), Vector2(1500, 250), Vector2(2100, 250)],
		"surfaces": [ground(-800, 3000)], "target": {}, "hazards": [], "objective": {}, "stars": [0, 0, 0]}

static func objective_text(o: Dictionary) -> String:
	var parts: Array = []
	if o.get("flips", 0) > 0:
		parts.append("complete %d flip(s)" % o["flips"])
	if o.get("twist", 0) > 0:
		parts.append("do %d half twist(s)" % o["twist"])
	if o.get("regrabs", 0) > 0:
		parts.append("regrab %d time(s)" % o["regrabs"])
	if o.get("tricks", 0) > 0:
		parts.append("land %d trick(s)" % o["tricks"])
	if parts.is_empty():
		return ""
	return ", ".join(parts)
