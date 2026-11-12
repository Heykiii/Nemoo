extends Node
## Renders the character select screen and a gameplay frame to /tmp (needs a display: xvfb-run).
func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 3:
		await get_tree().process_frame
	main.current.call("_show_characters")
	for i in 20:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/select.png")
	main._start("campaign", 5)
	for i in 30:
		await get_tree().physics_frame
	var g = main.current
	g.player.omega = 4.0
	g.player.queue_grab()
	for i in 30:
		await get_tree().physics_frame
	g.player.gust_vis = 0.45
	g.player.gust_dir_vis = 1
	for i in 6:
		await get_tree().physics_frame
	get_viewport().get_texture().get_image().save_png("/tmp/play.png")
	print("shots saved")
	get_tree().quit()
