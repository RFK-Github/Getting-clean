extends Node
## Game flow: which level is running, fading between levels, and a reading panel
## for things the player reads (clipboard, schedule board, later: letters).
## main.tscn reads Game.current_level when it starts; change_level() fades out and reloads it.

var current_level: String = Config.START_LEVEL
var previous_level := ""

var _fade: ColorRect
var _busy := false
var _panel: Control
var _panel_title: Label
var _panel_body: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_build_panel(layer)
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
	previous_level = current_level
	current_level = level_id
	get_tree().paused = false
	get_tree().reload_current_scene()
	await get_tree().process_frame
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, Config.LEVEL_FADE_TIME)
	await back.finished
	_busy = false


# ------------------------------------------------------------------ Reading panel

func show_text(title: String, body: String) -> void:
	_panel_title.text = title
	_panel_body.text = body
	_panel.visible = true
	get_tree().paused = true


func is_reading() -> bool:
	return _panel.visible


func close_text() -> void:
	_panel.visible = false
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	if not _panel.visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("pause") \
			or (event is InputEventMouseButton and event.pressed):
		close_text()
		get_viewport().set_input_as_handled()


func _build_panel(layer: CanvasLayer) -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font_size = Config.UI_FONT_SIZE
	_panel.theme = th
	_panel.visible = false
	layer.add_child(_panel)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(center)

	var paper := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.88, 0.86, 0.78)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	paper.add_theme_stylebox_override("panel", style)
	paper.custom_minimum_size = Vector2(420, 0)
	center.add_child(paper)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	paper.add_child(box)
	_panel_title = Label.new()
	_panel_title.add_theme_color_override("font_color", Color(0.12, 0.12, 0.14))
	box.add_child(_panel_title)
	_panel_body = Label.new()
	_panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_body.custom_minimum_size = Vector2(372, 0)
	_panel_body.add_theme_color_override("font_color", Color(0.18, 0.18, 0.22))
	_panel_body.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE_SMALL)
	box.add_child(_panel_body)
	var hint := Label.new()
	hint.text = "[E] Close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	hint.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE_SMALL)
	box.add_child(hint)
