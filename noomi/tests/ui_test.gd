extends Node
func _ready():
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	for page in ["_show_modes","_show_characters","_show_settings","_show_book"]:
		main.current.call(page); await get_tree().process_frame
	main._show_levels(); await get_tree().process_frame
	for i in range(10):
		main._start("campaign", i); await get_tree().physics_frame; await get_tree().physics_frame
	main._start("rush", 0); await get_tree().physics_frame
	main.current._open_pause(); await get_tree().process_frame
	main.current._close_overlay()
	main._show_results({"mode":"campaign","level_index":0,"level_name":"x","score":10,"tricks":["Backflip"],"landing":"clean","best_combo":1,"new_best":true,"personal_best":10,"stars":2,"completed":true,"reason":"ok","has_next":true})
	await get_tree().process_frame
	print("UI OK")
	get_tree().quit()
