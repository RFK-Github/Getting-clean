extends Node
## Game flow: which level is running, fading between levels, and a reading panel
## for things the player reads (clipboard, schedule board, later: letters).
## main.tscn reads Game.current_level when it starts; change_level() fades out and reloads it.

var current_level: String = Config.START_LEVEL
var previous_level := ""
var wake_message := ""   # shown when the hospital loads after a day passes
var in_cutscene := false

const CutscenePlayer := preload("res://scripts/cutscenes/cutscene_player.gd")

var _fade: ColorRect
var _busy := false
var _panel: Control
var _panel_title: Label
var _panel_body: Label
var _ending: Control
var _ending_text: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_build_panel(layer)
	_build_ending(layer)
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


# ------------------------------------------------------------------ Cutscenes

## Plays an in-engine cutscene (a script extending cutscene_base.gd) over the game.
## The game is paused while it plays. Use with await.
func play_cutscene(scene_script: GDScript) -> void:
	in_cutscene = true
	var p := CutscenePlayer.new()
	add_child(p)
	await p.play(scene_script)
	p.queue_free()
	in_cutscene = false


# ------------------------------------------------------------------ Endings
# Placeholder text screens. Build step 10 replaces them with final cutscenes A and B.

## Final cutscene B: the countdown ran out.
func game_over() -> void:
	_show_ending("She came.\n\nYou weren't ready.\n\nShe left.")


## Final cutscene A: Recovery reached 100 and the doctor lets you go.
func good_ending() -> void:
	_show_ending("\"You're ready.\"\n\nYou walk out into the daylight.\nShe is waiting for you.")


func is_ending() -> bool:
	return _ending.visible


func _show_ending(text: String) -> void:
	if _busy:
		return
	_busy = true
	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, Config.LEVEL_FADE_TIME * 2.0)
	await out.finished
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_ending_text.text = text
	_ending.visible = true
	_fade.color.a = 0.0  # the fade layer sits on top of the ending screen
	_busy = false


## Start the whole game over from the first level.
func restart() -> void:
	_ending.visible = false
	Withdrawal.reset()
	Recovery.reset()
	wake_message = ""
	previous_level = ""
	current_level = Config.START_LEVEL
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, Config.LEVEL_FADE_TIME)


func _build_ending(layer: CanvasLayer) -> void:
	_ending = ColorRect.new()
	(_ending as ColorRect).color = Color.BLACK
	_ending.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ending.visible = false
	var th := Theme.new()
	th.default_font_size = Config.UI_FONT_SIZE
	_ending.theme = th
	layer.add_child(_ending)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ending.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 40)
	center.add_child(box)
	_ending_text = Label.new()
	_ending_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_text.add_theme_color_override("font_color", Color(0.85, 0.85, 0.82))
	box.add_child(_ending_text)
	var hint := Label.new()
	hint.text = "[E] Start again"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	hint.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE_SMALL)
	box.add_child(hint)


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
	if _ending.visible:
		if event.is_action_pressed("interact"):
			restart()
		get_viewport().set_input_as_handled()
		return
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
