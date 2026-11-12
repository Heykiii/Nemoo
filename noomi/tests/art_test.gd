extends Node
## Every character x every player state must draw without script errors.
const PlayerScript := preload("res://scripts/player/player.gd")
const LevelData := preload("res://scripts/core/level_data.gd")
const CharacterData := preload("res://scripts/core/character_data.gd")
const InputSetup := preload("res://scripts/core/input_setup.gd")
func _ready() -> void:
	InputSetup.ensure()
	var n := 0
	for ch in CharacterData.LIST:
		var p = PlayerScript.new()
		add_child(p)
		p.setup(LevelData.levels()[4])
		p.palette = ch
		for state in [p.State.HANG, p.State.AIR, p.State.LANDED, p.State.FALLEN]:
			p.state = state
			for ext in [false, true]:
				p.extended = ext
				p.tucked = ext
				p.last_result = "unstable" if ext else "perfect"
				p.queue_redraw()
				await get_tree().process_frame
				n += 1
		p.queue_free()
	print("ART TEST OK, drew ", n, " combinations for ", CharacterData.LIST.size(), " characters")
	get_tree().quit()
