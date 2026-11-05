extends Node2D
## Draws the level (surfaces, bars, hazards) with simple geometry and animates hazards.

var level: Dictionary = {}
var player = null
var time := 0.0
var hazard_pos: Array = []

const NAVY2 := Color("1a1f4d")
const CYAN := Color("4de8d0")
const GOLD := Color("ffc048")
const PINK := Color("ff4d8d")
const LAV := Color("b79cff")

func setup(lv: Dictionary, p) -> void:
	level = lv
	player = p
	_update_hazards()

func _update_hazards() -> void:
	hazard_pos.clear()
	for h in level["hazards"]:
		var c: Vector2 = h["center"]
		var ax: Vector2 = h["axis"]
		hazard_pos.append(c + ax * sin(time * float(h["speed"]) + float(h["phase"])) * float(h["amp"]))

func _physics_process(delta: float) -> void:
	time += delta
	_update_hazards()
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for s in level["surfaces"]:
		var r: Rect2 = s
		draw_rect(r, NAVY2)
		var x := floorf(r.position.x / 120.0) * 120.0
		while x <= r.end.x:
			if x >= r.position.x:
				draw_line(Vector2(x, r.position.y), Vector2(x, r.position.y + 160.0), Color(1, 1, 1, 0.06), 2.0)
			x += 120.0
		draw_rect(Rect2(r.position.x, r.position.y - 3.0, r.size.x, 8.0), CYAN)
	var tg: Dictionary = level.get("target", {})
	if not tg.is_empty():
		var tr := Rect2(float(tg["x"]), float(tg["y"]) - 6.0, float(tg["w"]), 14.0)
		draw_rect(tr, GOLD)
		draw_string(font, Vector2(tr.position.x, tr.position.y + 44.0), "TARGET", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)
		var cx := tr.position.x
		while cx <= tr.end.x:
			draw_line(Vector2(cx, tr.position.y - 4.0), Vector2(cx + 14.0, tr.position.y - 20.0), GOLD, 3.0)
			draw_line(Vector2(cx + 14.0, tr.position.y - 20.0), Vector2(cx + 28.0, tr.position.y - 4.0), GOLD, 3.0)
			cx += 56.0
	var bars: Array = level["bars"]
	for i in bars.size():
		var b: Vector2 = bars[i]
		draw_line(b, Vector2(b.x, 600.0), Color(0.45, 0.4, 0.75, 0.35), 8.0)
		draw_circle(b, 13.0, LAV)
		draw_circle(b, 8.0, CYAN)
		if player != null and player.near_bar == i:
			var pulse := 0.6 + 0.4 * sin(time * 10.0)
			draw_arc(b, 34.0, 0.0, TAU, 40, Color(GOLD.r, GOLD.g, GOLD.b, pulse), 5.0)
	for p in hazard_pos:
		draw_circle(p, 32.0, PINK)
		draw_circle(p, 20.0, Color("2a0f2a"))
		draw_arc(p, 38.0, 0.0, TAU, 24, Color(PINK.r, PINK.g, PINK.b, 0.5), 3.0)
