extends Node
## Renders story screens + HUD to /tmp (needs a display: xvfb-run).
const StoryData := preload("res://scripts/core/story_data.gd")
const GameplayScript := preload("res://scripts/gameplay/gameplay.gd")
func _ready() -> void:
	GameplayScript.time_control = false
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 3:
		await get_tree().process_frame
	main._show_story(StoryData.intro_lines(9), 9, "Start!", func(): pass)
	await get_tree().create_timer(1.6).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/story_baron.png")
	main.current._on_next()
	main.current._on_next()
	main.current._on_next()
	await get_tree().create_timer(2.6).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/story_hero.png")
	main._show_story(StoryData.intro_lines(1), 1, "Start!", func(): pass)
	await get_tree().create_timer(2.6).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/story_chef.png")
	main._start("campaign", 7)
	for i in 20:
		await get_tree().physics_frame
	get_viewport().get_texture().get_image().save_png("/tmp/hud.png")
	main._show_menu()
	await get_tree().process_frame
	main.current.call("_show_settings")
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/settings.png")
	print("story shots saved")
	get_tree().quit()
