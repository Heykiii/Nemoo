extends RefCounted
## Procedural humanoid: head, torso, TWO arms and TWO legs.
## Limbs use 2-bone IK, so poses only say where hands and feet go and the elbows/knees are solved.
## Local space: origin = body centre, +x = facing direction, -y = up. Feet ~ +44, head top ~ -52.
## All 11 costumes are drawn with plain shapes (no image files), so they are easy to replace later.

const DARK := Color("1b1630")
const WHITE := Color("ffffff")
const SHOULDER := Vector2(0, -22)
const HIP := Vector2(0, 6)
const HEAD := Vector2(0, -40)
const HEAD_R := 12.5
const ARM_A := 21.0
const ARM_B := 20.0
const LEG_A := 20.0
const LEG_B := 18.0
## While hanging, the body is drawn this much closer to the bar so the arms can reach it.
const SHIFT_HANG := 18.0

# ------------------------------------------------------------------ poses
static func pose_hang(cur_len: float, lag: float) -> Dictionary:
	var top := SHIFT_HANG - cur_len
	return {
		"hb": Vector2(-3, top), "hf": Vector2(3, top),
		"fb": Vector2(-5.0 - lag, 41.0), "ff": Vector2(4.0 - lag, 43.0),
	}

static func pose_air(extended: bool, tucked: bool) -> Dictionary:
	if tucked:
		return {"hb": Vector2(13, 12), "hf": Vector2(18, 14),
			"fb": Vector2(2, 30), "ff": Vector2(7, 32)}
	if extended:
		return {"hb": Vector2(-3, -64), "hf": Vector2(4, -64),
			"fb": Vector2(-2, 45), "ff": Vector2(3, 45)}
	return {"hb": Vector2(-28, -54), "hf": Vector2(30, -52),
		"fb": Vector2(-12, 44), "ff": Vector2(13, 44)}

static func pose_stand(victory: bool, wobbly: bool, t: float) -> Dictionary:
	var bob := sin(t * 6.0) * 2.0
	if wobbly:
		var w := sin(t * 22.0)
		return {"hb": Vector2(-30, -34 + w * 10.0), "hf": Vector2(30, -34 - w * 10.0),
			"fb": Vector2(-9 + w * 3.0, 44), "ff": Vector2(9 + w * 3.0, 44)}
	if victory:
		return {"hb": Vector2(-26, -58 + bob), "hf": Vector2(27, -58 - bob),
			"fb": Vector2(-11, 44), "ff": Vector2(12, 44)}
	return {"hb": Vector2(-14, 8 + bob), "hf": Vector2(15, 8 - bob),
		"fb": Vector2(-11, 44), "ff": Vector2(12, 44)}

static func pose_flail(t: float) -> Dictionary:
	return {
		"hb": Vector2(-24 + sin(t * 17.0) * 10.0, -40 + cos(t * 13.0) * 14.0),
		"hf": Vector2(26 + sin(t * 15.0 + 1.0) * 10.0, -36 + cos(t * 19.0) * 14.0),
		"fb": Vector2(-14 + sin(t * 14.0) * 9.0, 38 + cos(t * 11.0) * 5.0),
		"ff": Vector2(14 + sin(t * 16.0 + 2.0) * 9.0, 38 + cos(t * 12.0) * 5.0),
	}

static func lerp_pose(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	var out := {}
	for k in ["hb", "hf", "fb", "ff"]:
		out[k] = (a[k] as Vector2).lerp(b[k], w)
	return out

# ------------------------------------------------------------------ helpers
static func _ik(root: Vector2, target: Vector2, a: float, b: float, side: float) -> Vector2:
	var delta := target - root
	var dist := maxf(delta.length(), 0.001)
	var d := clampf(dist, absf(a - b) + 0.5, a + b - 0.5)
	var dir := delta / dist
	var x := (d * d + a * a - b * b) / (2.0 * d)
	var h := sqrt(maxf(a * a - x * x, 0.0))
	var perp := Vector2(-dir.y, dir.x)
	return root + dir * x + perp * h * side

static func _seg(c: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	c.draw_line(a, b, col, w)
	c.draw_circle(a, w * 0.5, col)
	c.draw_circle(b, w * 0.5, col)

static func _poly(c: CanvasItem, pts: Array, col: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array(pts), col)

static func _spike(c: CanvasItem, base: Vector2, dir: Vector2, length: float, width: float, col: Color) -> void:
	var perp := Vector2(-dir.y, dir.x) * width * 0.5
	c.draw_colored_polygon(PackedVector2Array([base - perp, base + perp, base + dir * length]), col)

# ------------------------------------------------------------------ main entry
static func draw_character(c: CanvasItem, pose: Dictionary, p: Dictionary, t: float) -> void:
	var kind: String = p["kind"]
	var hb: Vector2 = pose["hb"]
	var hf: Vector2 = pose["hf"]
	var fb: Vector2 = pose["fb"]
	var ff: Vector2 = pose["ff"]
	var eb := _ik(SHOULDER, hb, ARM_A, ARM_B, -1.0)
	var ef := _ik(SHOULDER, hf, ARM_A, ARM_B, 1.0)
	var kb := _ik(HIP, fb, LEG_A, LEG_B, -1.0)
	var kf := _ik(HIP, ff, LEG_A, LEG_B, -1.0)
	_back_layer(c, kind, p, t)
	_leg(c, kind, p, kb, fb, true)
	_arm(c, kind, p, eb, hb, true)
	_torso(c, kind, p)
	_leg(c, kind, p, kf, ff, false)
	_skirt(c, kind, p)
	_arm(c, kind, p, ef, hf, false)
	_head(c, kind, p, t)

# ------------------------------------------------------------------ limbs
static func _arm(c: CanvasItem, kind: String, p: Dictionary, elbow: Vector2, hand: Vector2, back: bool) -> void:
	var dk := 0.22 if back else 0.0
	var skin: Color = p["skin"]
	var body: Color = p["body"]
	var accent: Color = p["accent"]
	var upper := body
	var lower := body
	var glove := skin
	match kind:
		"gymnast", "viking":
			upper = skin
			lower = skin
		"chef":
			lower = skin
		"astro":
			glove = accent
		"robot":
			glove = accent
		"ninja":
			glove = body
		"scientist":
			glove = accent
		"clown":
			glove = WHITE
		"dino":
			glove = body.lightened(0.15)
	_seg(c, SHOULDER, elbow, 10.0, upper.darkened(dk))
	_seg(c, elbow, hand, 9.0, lower.darkened(dk))
	if kind == "viking":
		_seg(c, elbow.lerp(hand, 0.35), hand, 10.0, (p["accent"] as Color).darkened(0.35 + dk))
	if kind == "robot":
		c.draw_circle(elbow, 3.0, accent.darkened(dk))
	c.draw_circle(hand, 5.5, glove.darkened(dk))

static func _leg(c: CanvasItem, kind: String, p: Dictionary, knee: Vector2, foot: Vector2, back: bool) -> void:
	var dk := 0.22 if back else 0.0
	var pants: Color = (p["pants"] as Color).darkened(dk)
	var shoe: Color = (p["shoe"] as Color).darkened(dk)
	var w := 12.0
	var shoe_len := 11.0
	var shoe_w := 8.0
	if kind == "clown":
		w = 14.0
		shoe_len = 21.0
		shoe_w = 12.0
	elif kind == "robot" or kind == "wizard":
		w = 10.0
	_seg(c, HIP, knee, w, pants)
	_seg(c, knee, foot, w - 1.0, pants)
	var heel := foot + Vector2(-2.0, 2.0)
	var toe := foot + Vector2(shoe_len, 2.0)
	c.draw_line(heel, toe, shoe, shoe_w)
	c.draw_circle(heel, shoe_w * 0.5, shoe)
	c.draw_circle(toe, shoe_w * 0.5, shoe)
	if kind == "robot":
		c.draw_circle(knee, 3.0, (p["accent"] as Color).darkened(dk))
	elif kind == "clown":
		c.draw_circle(toe + Vector2(-2, -1), 3.0, (p["accent"] as Color).darkened(dk))
	elif kind == "viking":
		c.draw_line(foot + Vector2(-4, -8), foot + Vector2(4, -8), (p["hair"] as Color).darkened(dk), 5.0)

# ------------------------------------------------------------------ body
static func _torso(c: CanvasItem, kind: String, p: Dictionary) -> void:
	var body: Color = p["body"]
	var pants: Color = p["pants"]
	var accent: Color = p["accent"]
	if kind == "robot":
		c.draw_rect(Rect2(-12, -25, 24, 36), body)
		c.draw_rect(Rect2(-12, -25, 24, 36), body.darkened(0.35), false, 2.0)
		c.draw_circle(Vector2(1, -11), 5.5, DARK)
		c.draw_circle(Vector2(1, -11), 3.6, accent)
		c.draw_line(Vector2(-8, 1), Vector2(10, 1), body.darkened(0.3), 2.0)
		c.draw_circle(Vector2(-9, -22), 1.6, body.darkened(0.4))
		c.draw_circle(Vector2(9, -22), 1.6, body.darkened(0.4))
		return
	c.draw_line(SHOULDER + Vector2(0, -2), Vector2(0, 0), body, 22.0)
	c.draw_circle(SHOULDER + Vector2(0, -2), 11.0, body)
	c.draw_line(Vector2(0, 0), Vector2(0, 8), pants, 21.0)
	c.draw_circle(Vector2(0, 8), 10.5, pants)
	match kind:
		"gymnast":
			c.draw_line(Vector2(-11, 0), Vector2(11, 0), accent, 3.0)
			c.draw_circle(Vector2(3, -12), 3.2, accent)
		"chef":
			c.draw_circle(Vector2(4, -14), 1.8, DARK)
			c.draw_circle(Vector2(4, -7), 1.8, DARK)
			c.draw_circle(Vector2(0, -21), 4.0, accent)
		"astro":
			c.draw_rect(Rect2(-6, -17, 12, 10), accent.darkened(0.1))
			c.draw_circle(Vector2(-2, -12), 1.6, Color("4de8d0"))
			c.draw_circle(Vector2(3, -12), 1.6, Color("e63946"))
			c.draw_line(Vector2(-11, 0), Vector2(11, 0), accent, 3.0)
		"ninja":
			c.draw_line(Vector2(-11, 0), Vector2(11, 0), accent, 6.0)
		"pirate":
			for y in [-17.0, -11.0, -5.0]:
				c.draw_line(Vector2(-10.5, y), Vector2(10.5, y), Color("2b4c8c"), 2.6)
			c.draw_line(Vector2(-11, 1), Vector2(11, 1), Color("3a2410"), 4.0)
			c.draw_rect(Rect2(1, -1, 5, 5), accent)
		"wizard":
			c.draw_line(Vector2(-11, 0), Vector2(11, 0), accent, 3.0)
		"clown":
			c.draw_circle(Vector2(-5, -15), 2.6, accent)
			c.draw_circle(Vector2(5, -8), 2.6, accent)
			c.draw_circle(Vector2(-4, -3), 2.2, accent)
			for i in range(5):
				var col := WHITE if i % 2 == 0 else accent
				c.draw_circle(Vector2(-10.0 + 5.0 * float(i), -22.0), 4.5, col)
		"dino":
			c.draw_line(Vector2(3, -18), Vector2(3, 2), Color("d6f5c0"), 11.0)
		"viking":
			c.draw_line(Vector2(-11, 0), Vector2(11, 0), Color("2e2218"), 5.0)
			c.draw_circle(Vector2(2, 0), 3.0, accent)
			for i in range(4):
				c.draw_circle(Vector2(-9.0 + 6.0 * float(i), -22.0), 5.0, Color("d8d2c4"))

static func _skirt(c: CanvasItem, kind: String, p: Dictionary) -> void:
	var body: Color = p["body"]
	var accent: Color = p["accent"]
	match kind:
		"wizard":
			_poly(c, [Vector2(-12, -22), Vector2(12, -22), Vector2(20, 32), Vector2(-20, 32)], body)
			c.draw_line(Vector2(-20, 31), Vector2(20, 31), accent, 4.0)
			c.draw_line(Vector2(-12, 0), Vector2(13, 0), accent, 3.0)
			c.draw_circle(Vector2(-7, 14), 2.2, accent)
			c.draw_circle(Vector2(8, 8), 2.2, accent)
			c.draw_circle(Vector2(-1, 23), 2.2, accent)
		"scientist":
			_poly(c, [Vector2(-12, -22), Vector2(12, -22), Vector2(15, 27), Vector2(-15, 27)], body)
			c.draw_line(Vector2(0, 4), Vector2(0, 27), body.darkened(0.25), 1.6)
			c.draw_rect(Rect2(3, 2, 8, 7), body.darkened(0.18), false, 1.6)
			c.draw_line(Vector2(8, 0), Vector2(8, 5), Color("e63946"), 2.2)
			c.draw_line(Vector2(-12, -22), Vector2(0, -8), body.darkened(0.2), 1.6)
			c.draw_line(Vector2(12, -22), Vector2(0, -8), body.darkened(0.2), 1.6)
		"chef":
			_poly(c, [Vector2(-9, -4), Vector2(11, -4), Vector2(13, 25), Vector2(-9, 25)], Color("e9e3d3"))
			c.draw_rect(Rect2(-5, 6, 10, 7), Color("d2c9b3"), false, 1.6)
		"viking":
			_poly(c, [Vector2(-11, 4), Vector2(11, 4), Vector2(14, 19), Vector2(-14, 19)], body.darkened(0.12))
			c.draw_line(Vector2(-14, 18), Vector2(14, 18), accent.darkened(0.3), 2.0)
		"pirate":
			c.draw_circle(Vector2(-10, -30), 5.0, Color("e63946"))
			c.draw_circle(Vector2(-8, -36), 3.6, Color("e63946"))
			_poly(c, [Vector2(-5, -37), Vector2(-1, -35), Vector2(-5, -34)], Color("ff9f1c"))
			c.draw_circle(Vector2(-8, -37), 0.9, DARK)
			c.draw_line(Vector2(-12, -26), Vector2(-19, -16), Color("2fbf6a"), 3.0)

static func _back_layer(c: CanvasItem, kind: String, p: Dictionary, t: float) -> void:
	var body: Color = p["body"]
	var accent: Color = p["accent"]
	match kind:
		"gymnast":
			var tip := Vector2(-24.0 + sin(t * 7.0) * 3.0, -32.0 + cos(t * 6.0) * 3.0)
			c.draw_line(Vector2(-9, -46), tip, p["hair"], 6.0)
			c.draw_circle(tip, 4.0, p["hair"])
			c.draw_circle(Vector2(-10, -46), 3.0, accent)
		"astro":
			c.draw_rect(Rect2(-21, -27, 12, 32), body.darkened(0.2))
			c.draw_rect(Rect2(-21, -17, 12, 4), accent)
			c.draw_circle(Vector2(-15, 9), 3.0, accent.darkened(0.2))
		"ninja":
			c.draw_line(Vector2(-12, -32), Vector2(9, 11), Color("c0c7d1"), 3.0)
			c.draw_line(Vector2(-12, -32), Vector2(-16, -39), Color("e63946"), 4.0)
		"dino":
			var wag := sin(t * 8.0) * 3.0
			_poly(c, [Vector2(-8, 0), Vector2(-30, 6 + wag), Vector2(-47, 24 + wag), Vector2(-28, 20 + wag * 0.5), Vector2(-8, 14)], body)
			for i in range(3):
				var y := -14.0 + 9.0 * float(i)
				_spike(c, Vector2(-10, y), Vector2(-1, 0), 8.0, 8.0, accent)
		"viking":
			c.draw_circle(Vector2(-13, -8), 15.0, Color("8a5a2b").lightened(0.1))
			c.draw_arc(Vector2(-13, -8), 15.0, 0.0, TAU, 20, accent, 3.0)
			c.draw_circle(Vector2(-13, -8), 4.5, accent)

# ------------------------------------------------------------------ head
static func _head(c: CanvasItem, kind: String, p: Dictionary, t: float) -> void:
	var skin: Color = p["skin"]
	var hair: Color = p["hair"]
	var accent: Color = p["accent"]
	var body: Color = p["body"]
	# things that sit behind the face
	match kind:
		"clown":
			var cols := [Color("ff4d8d"), Color("ffc048"), Color("4de8d0"), Color("7b4dff"), Color("ff7a45"), Color("ffc048")]
			var pts := [Vector2(-16, -39), Vector2(-14, -51), Vector2(-3, -57), Vector2(9, -55), Vector2(16, -46), Vector2(-15, -28)]
			for i in range(pts.size()):
				c.draw_circle(pts[i], 8.5, cols[i])
		"scientist":
			for i in range(9):
				var a := PI + (float(i) + 0.5) * PI / 9.0
				var dir := Vector2(cos(a), sin(a))
				var length := 10.0 + float(i % 2) * 5.0
				c.draw_line(HEAD + dir * HEAD_R * 0.7, HEAD + dir * (HEAD_R + length), hair, 4.5)
		"wizard", "viking":
			c.draw_line(Vector2(-6, -46), Vector2(-12, -16), hair, 9.0)
		"pirate":
			c.draw_line(Vector2(-6, -46), Vector2(-11, -26), hair, 8.0)
	if kind == "robot":
		_robot_head(c, p, t)
		return
	c.draw_circle(HEAD, HEAD_R, skin)
	# eyes and mouth
	var eyes := kind != "scientist" and kind != "ninja"
	if eyes:
		c.draw_circle(Vector2(5, -41), 2.2, DARK)
		c.draw_circle(Vector2(5.8, -41.8), 0.8, WHITE)
	if kind in ["gymnast", "chef", "astro", "pirate", "scientist", "dino"]:
		c.draw_arc(Vector2(6, -36), 3.6, 0.3, PI - 0.3, 8, DARK, 1.6)
	match kind:
		"gymnast":
			c.draw_arc(HEAD, HEAD_R - 1.5, PI + 0.15, TAU - 0.15, 14, hair, 6.0)
			c.draw_line(Vector2(-11.5, -45), Vector2(11.5, -45), accent, 4.5)
		"chef":
			c.draw_line(Vector2(3, -35), Vector2(12, -36.5), hair, 3.4)
			c.draw_circle(Vector2(12, -36.5), 2.1, hair)
			c.draw_rect(Rect2(-11, -58, 22, 9), Color("fbfbfb"))
			c.draw_circle(Vector2(-8, -62), 8.0, Color("fbfbfb"))
			c.draw_circle(Vector2(0, -67), 9.5, Color("fbfbfb"))
			c.draw_circle(Vector2(8, -62), 8.0, Color("fbfbfb"))
			c.draw_line(Vector2(-11, -51), Vector2(11, -51), Color("d3d3d3"), 1.6)
		"astro":
			c.draw_circle(HEAD, 17.0, Color(0.35, 0.9, 0.85, 0.16))
			c.draw_arc(HEAD, 17.0, 0.0, TAU, 28, body, 4.5)
			c.draw_arc(HEAD, 13.5, PI + 0.5, PI + 1.3, 6, Color(1, 1, 1, 0.9), 2.4)
			c.draw_line(Vector2(-9, -23), Vector2(9, -23), body.darkened(0.15), 5.0)
		"ninja":
			c.draw_circle(HEAD, HEAD_R + 0.6, body)
			c.draw_rect(Rect2(0, -45, 12, 7), skin)
			c.draw_circle(Vector2(6, -41), 1.9, WHITE)
			c.draw_circle(Vector2(6.6, -41), 1.0, DARK)
			c.draw_line(Vector2(1, -46.5), Vector2(11, -43.5), DARK, 2.4)
			c.draw_line(Vector2(-12.5, -47), Vector2(12.5, -47), accent, 4.5)
			for i in range(2):
				var end := Vector2(-27.0, -47.0 + float(i) * 7.0 + sin(t * 9.0 + float(i)) * 4.0)
				c.draw_line(Vector2(-12, -47), end, accent, 3.4)
		"pirate":
			c.draw_circle(Vector2(6, -41), 4.2, DARK)
			c.draw_line(Vector2(6, -41), Vector2(-11, -48), DARK, 1.6)
			c.draw_circle(Vector2(-1, -32), 1.8, accent)
			_poly(c, [Vector2(-19, -47), Vector2(19, -47), Vector2(14, -57), Vector2(0, -63), Vector2(-14, -57)], Color("23232e"))
			c.draw_line(Vector2(-19, -47), Vector2(19, -47), accent, 2.6)
			c.draw_circle(Vector2(1, -54), 3.4, WHITE)
			c.draw_circle(Vector2(0, -54.5), 0.9, DARK)
			c.draw_circle(Vector2(2.4, -54.5), 0.9, DARK)
		"wizard":
			c.draw_line(Vector2(2, -46), Vector2(10, -45), hair, 2.6)
			_poly(c, [Vector2(-9, -34), Vector2(10, -34), Vector2(7, -14), Vector2(0, -6), Vector2(-6, -14)], hair)
			var hat := body.darkened(0.15)
			_poly(c, [Vector2(-16, -48), Vector2(16, -48), Vector2(6, -72), Vector2(-3, -85)], hat)
			c.draw_line(Vector2(-23, -48), Vector2(23, -48), hat, 6.0)
			c.draw_line(Vector2(-14, -53), Vector2(14, -53), accent, 4.0)
			c.draw_circle(Vector2(2, -65), 2.6, accent)
			c.draw_circle(Vector2(-1, -76), 2.0, accent)
		"clown":
			c.draw_circle(Vector2(2, -34), 3.0, Color(1.0, 0.5, 0.6, 0.65))
			c.draw_circle(Vector2(5, -42), 3.8, Color("2f80ed"))
			c.draw_circle(Vector2(5, -42), 2.2, DARK)
			c.draw_arc(Vector2(5, -35), 6.0, 0.2, PI - 0.2, 10, Color("e63946"), 2.4)
			c.draw_circle(Vector2(12, -39), 5.2, Color("e63946"))
			c.draw_circle(Vector2(10.5, -40.5), 1.4, Color(1, 1, 1, 0.8))
		"scientist":
			c.draw_line(Vector2(-12.5, -43), Vector2(12.5, -43), DARK, 4.0)
			for x in [0.0, 9.0]:
				c.draw_circle(Vector2(x, -42), 5.8, DARK)
				c.draw_circle(Vector2(x, -42), 4.2, accent)
				c.draw_circle(Vector2(x - 1.2, -43.4), 1.2, WHITE)
		"dino":
			c.draw_arc(HEAD, HEAD_R, PI - 0.4, TAU + 0.4, 20, body, 9.0)
			c.draw_circle(Vector2(11, -50), 6.5, body)
			c.draw_circle(Vector2(14, -52), 1.1, DARK)
			for i in range(4):
				var x := -2.0 + 4.6 * float(i)
				_poly(c, [Vector2(x, -46), Vector2(x + 4.0, -46), Vector2(x + 2.0, -42)], WHITE)
			c.draw_circle(Vector2(3, -55), 5.0, WHITE)
			c.draw_circle(Vector2(4.5, -55), 2.2, DARK)
			c.draw_circle(Vector2(-6, -54), 4.4, WHITE)
			c.draw_circle(Vector2(-5, -54), 2.0, DARK)
			for i in range(3):
				var a := PI + 0.35 + float(i) * 0.5
				var dir := Vector2(cos(a), sin(a))
				_spike(c, HEAD + dir * (HEAD_R + 3.0), dir, 8.0, 7.0, accent)
		"viking":
			c.draw_line(Vector2(1, -46), Vector2(10, -44), hair, 2.6)
			_poly(c, [Vector2(-8, -33), Vector2(11, -33), Vector2(8, -12), Vector2(1, -6), Vector2(-5, -14)], hair)
			c.draw_line(Vector2(1, -12), Vector2(1, -5), hair.darkened(0.3), 1.6)
			c.draw_arc(HEAD, HEAD_R - 0.5, PI, TAU, 14, accent, 8.0)
			c.draw_line(Vector2(-13, -45), Vector2(13, -45), accent.darkened(0.3), 4.0)
			var horn := Color("f2ead3")
			c.draw_line(Vector2(-11, -47), Vector2(-21, -56), horn, 5.5)
			c.draw_line(Vector2(-21, -56), Vector2(-20, -67), horn, 4.0)
			c.draw_line(Vector2(11, -47), Vector2(21, -56), horn, 5.5)
			c.draw_line(Vector2(21, -56), Vector2(20, -67), horn, 4.0)

static func _robot_head(c: CanvasItem, p: Dictionary, t: float) -> void:
	var body: Color = p["body"]
	var accent: Color = p["accent"]
	c.draw_rect(Rect2(-13, -53, 26, 25), body)
	c.draw_rect(Rect2(-13, -53, 26, 25), body.darkened(0.35), false, 2.0)
	c.draw_rect(Rect2(-10, -48, 22, 11), DARK)
	c.draw_circle(Vector2(-2, -42), 3.2, accent)
	c.draw_circle(Vector2(8, -42), 3.2, accent)
	for i in range(3):
		var x := -6.0 + 5.0 * float(i)
		c.draw_line(Vector2(x, -33), Vector2(x, -30), DARK, 1.6)
	c.draw_circle(Vector2(-13, -40), 3.0, body.darkened(0.3))
	c.draw_circle(Vector2(13, -40), 3.0, body.darkened(0.3))
	c.draw_line(Vector2(0, -53), Vector2(0, -63), body.darkened(0.3), 2.5)
	c.draw_circle(Vector2(0, -65), 3.6 + sin(t * 6.0) * 0.6, accent)
