extends Node2D
## Renders all characters in several poses to /tmp/sheet.png (needs a display; run with xvfb-run).
const Art := preload("res://scripts/player/player_art.gd")
const CharacterData := preload("res://scripts/core/character_data.gd")
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("0b1030"))
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/sheet.png")
	print("saved ", img.get_size())
	get_tree().quit()
var poses: Array = []
func _draw() -> void:
	var t := 0.4
	poses = [Art.pose_stand(true, false, t), Art.pose_air(false, false), Art.pose_air(false, true), Art.pose_air(true, false), Art.pose_hang(80.0, 6.0), Art.pose_flail(t)]
	var n := CharacterData.LIST.size()
	for r in range(poses.size()):
		for i in range(n):
			var pos := Vector2(80 + i * 112, 100 + r * 150)
			draw_set_transform(pos, 0.0, Vector2(0.95, 0.95))
			if r == 4:
				draw_set_transform(pos + Vector2(0, -Art.SHIFT_HANG * 0.95), 0.0, Vector2(0.95, 0.95))
				draw_line(Vector2(-30, -62), Vector2(30, -62), Color("4de8d0"), 4.0)
			Art.draw_character(self, poses[r], CharacterData.LIST[i], t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
