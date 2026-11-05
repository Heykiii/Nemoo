extends Node
## Screen router. Swaps one screen at a time; autoloads are only SaveManager/AudioManager.

const InputSetup := preload("res://scripts/core/input_setup.gd")
const MenuScreen := preload("res://scripts/ui/menu_screen.gd")
const LevelSelect := preload("res://scripts/ui/level_select.gd")
const ResultsScreen := preload("res://scripts/ui/results_screen.gd")
const Gameplay := preload("res://scripts/gameplay/gameplay.gd")

var current: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputSetup.ensure()
	_show_menu()

func _swap(node: Node) -> void:
	get_tree().paused = false
	if current != null:
		remove_child(current)
		current.queue_free()
	current = node
	node.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(node)

func _show_menu() -> void:
	var m = MenuScreen.new()
	m.open_levels.connect(_show_levels)
	m.start_rush.connect(func(): _start("rush", 0))
	m.start_chill.connect(func(): _start("chill", 0))
	_swap(m)

func _show_levels() -> void:
	var s = LevelSelect.new()
	s.chosen.connect(func(i: int): _start("campaign", i))
	s.back.connect(_show_menu)
	_swap(s)

func _start(mode: String, idx: int) -> void:
	var g = Gameplay.new()
	g.setup(mode, idx)
	g.finished.connect(_show_results)
	g.exit_requested.connect(_show_menu)
	_swap(g)

func _show_results(r: Dictionary) -> void:
	var s = ResultsScreen.new()
	s.setup(r)
	s.retry.connect(func(): _start(r["mode"], r["level_index"]))
	s.next.connect(func(): _start("campaign", int(r["level_index"]) + 1))
	s.menu.connect(_show_menu)
	_swap(s)

func _on_back() -> void:
	if current != null and current.has_method("on_back"):
		current.call("on_back")
	else:
		_show_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_back()
