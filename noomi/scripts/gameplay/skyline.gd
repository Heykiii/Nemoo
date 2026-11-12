extends Node2D
## Cheap parallax city skyline (drawn on a background CanvasLayer).

var cam_x := 0.0
const W := 140.0

func _draw() -> void:
	var vp := get_viewport_rect().size
	var base := vp.y
	var off := cam_x * 0.2
	var first := int(floorf(off / W))
	for i in range(first - 1, first + int(vp.x / W) + 3):
		var h := 120.0 + float((i * 7919) % 5) * 55.0
		var x := float(i) * W - off
		draw_rect(Rect2(x, base - h - 60.0, W - 10.0, h + 60.0), Color("141a45"))
		draw_line(Vector2(x, base - h - 60.0), Vector2(x + W - 10.0, base - h - 60.0), Color(0.3, 0.9, 0.82, 0.25), 3.0)
