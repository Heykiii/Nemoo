extends Node
## Audio hooks. Drop .ogg files named after the events into res://assets/audio/
## (grab, release, swing, trick, regrab, land, perfect, fall, level_complete, button).
## Missing files are silently skipped, so nothing breaks without assets.

var _cache := {}

func play(event: String) -> void:
	if not SaveManager.setting("sound"):
		return
	var path := "res://assets/audio/%s.ogg" % event
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	var stream = _cache[path]
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream = stream
	p.finished.connect(p.queue_free)
	p.play()
