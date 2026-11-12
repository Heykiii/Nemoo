extends Control
## Animated character preview used by the character select cards.

const Art := preload("res://scripts/player/player_art.gd")

var palette: Dictionary = {}
## true = arms up (character select); false = relaxed talking pose (story).
var victory := true
var phase := 0.0

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	if palette.is_empty():
		return
	var s := minf(size.x / 100.0, size.y / 150.0)
	draw_set_transform(Vector2(size.x * 0.5, size.y * 0.5 + 17.0 * s), 0.0, Vector2(s, s))
	Art.draw_character(self, Art.pose_stand(victory, false, phase), palette, phase)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
