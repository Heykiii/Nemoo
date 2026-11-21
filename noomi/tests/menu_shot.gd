extends Node
func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/p_main.png")
	main._show_train()
	for i in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/p_warm.png")
	get_tree().quit()
