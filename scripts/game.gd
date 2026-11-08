extends Node
## Which level is running, and fading between levels.
## main.tscn reads Game.current_level when it starts; change_level() fades out and reloads it.

var current_level: String = Config.START_LEVEL

var _fade: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


func change_level(level_id: String) -> void:
	if _busy:
		return
	_busy = true
	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, Config.LEVEL_FADE_TIME)
	await out.finished
	current_level = level_id
	get_tree().paused = false
	get_tree().reload_current_scene()
	await get_tree().process_frame
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, Config.LEVEL_FADE_TIME)
	await back.finished
	_busy = false
