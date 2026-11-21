extends Node
## Screenshots of the new screens (needs a display: xvfb-run).
func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 3:
		await get_tree().process_frame
	SaveManager.data = SaveManager.default_data()
	SaveManager.data["coins"] = 1300
	SaveManager.data["owned"]["ninja"] = true
	main.current.call("_show_characters")
	for i in 15: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/p_select.png")
	main.current.call("_show_detail", 4)
	for i in 15: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/p_detail.png")
	main._show_train()
	for i in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/p_warm.png")
	main.current._show_list()
	for i in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/p_train.png")
	main.current._show_guide("squats")
	main.current._begin()
	main.current.tick(6.0)
	for i in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/p_guide.png")
	SaveManager.data["character"] = 3
	main._start("campaign", 2)
	for i in 30: await get_tree().physics_frame
	var g = main.current
	g.player.omega = 4.0
	g.player.queue_grab()
	for i in 20: await get_tree().physics_frame
	get_viewport().get_texture().get_image().save_png("/tmp/p_play.png")
	print("shots saved")
	get_tree().quit()
