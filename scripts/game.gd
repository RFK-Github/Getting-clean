extends Node
## Game flow: which level is running, fading between levels, and a reading panel
## for things the player reads (clipboard, schedule board, later: letters).
## main.tscn reads Game.current_level when it starts; change_level() fades out and reloads it.

var current_level: String = Config.START_LEVEL
var previous_level := ""
var wake_message := ""   # shown when the hospital loads after a day passes
var in_cutscene := false
var has_gun := false        # picked up the revolver (kept across days)
var shots_fired := false    # once he has fired, everyone is afraid of him
var killed: Array[String] = []   # NPCs he has shot (they stay dead across days)

const CutscenePlayer := preload("res://scripts/cutscenes/cutscene_player.gd")
const Inventory := preload("res://scripts/inventory.gd")

var inventory: CanvasLayer

var _fade: ColorRect
var _busy := false
var _panel: Control
var _panel_title: Label
var _panel_body: Label
var _ending: Control
var _ending_text: Label
var _dialogue: Control
var _dialogue_speaker: Label
var _dialogue_text: Label
var _dialogue_choices: VBoxContainer
var _dialogue_options := 0   # number of choices on screen (0 = "continue")

signal _dialogue_pick(index: int)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_build_panel(layer)
	_build_dialogue(layer)
	_build_ending(layer)
	inventory = Inventory.new()
	add_child(inventory)
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
## end_black: stay black and paused afterwards (e.g. a day passes right after).
func play_cutscene(scene_script: GDScript, end_black := false) -> void:
	in_cutscene = true
	var p := CutscenePlayer.new()
	add_child(p)
	await p.play(scene_script, end_black)
	if end_black:
		_fade.color.a = 1.0
	p.queue_free()
	in_cutscene = false


# ------------------------------------------------------------------ Dialogue

## Runs a conversation and returns the choices the player picked (as dictionaries).
## tree: {node_id: {"speaker", "text", "next"} or {"speaker", "text", "choices": [
##   {"text", "next", "requires" ("truth" = all flashbacks seen), ...any extra keys}]}}
## Starts at "start" and ends when "next" is "" or missing. Pauses the game. Use with await.
func start_dialogue(tree: Dictionary, start := "start") -> Array:
	var picked: Array = []
	var id := start
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_dialogue.visible = true
	while id != "" and tree.has(id):
		var node: Dictionary = tree[id]
		_dialogue_speaker.text = node.get("speaker", "")
		_dialogue_text.text = node.get("text", "")
		for c in _dialogue_choices.get_children():
			c.queue_free()
		var choices: Array = node.get("choices", []).filter(_choice_available)
		_dialogue_options = choices.size()
		if choices.is_empty():
			_add_choice_button("[E] Continue", 0)
			await _dialogue_pick
			id = node.get("next", "")
		else:
			for i in choices.size():
				_add_choice_button("%d.  %s" % [i + 1, choices[i]["text"]], i)
			var index: int = await _dialogue_pick
			picked.append(choices[index])
			id = choices[index].get("next", "")
	_dialogue.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return picked


func is_talking() -> bool:
	return _dialogue.visible


func _choice_available(choice: Dictionary) -> bool:
	if choice.get("requires", "") == "truth":
		return Recovery.flashbacks_seen.size() >= Config.FLASHBACKS_TOTAL
	return true


func _add_choice_button(text: String, index: int) -> void:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): _dialogue_pick.emit(index))
	_dialogue_choices.add_child(b)


func _build_dialogue(layer: CanvasLayer) -> void:
	_dialogue = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.06, 0.92)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	_dialogue.add_theme_stylebox_override("panel", style)
	_dialogue.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue.offset_left = 24
	_dialogue.offset_right = -24
	_dialogue.offset_top = -210
	_dialogue.offset_bottom = -16
	var th := Theme.new()
	th.default_font_size = Config.UI_FONT_SIZE
	_dialogue.theme = th
	_dialogue.visible = false
	layer.add_child(_dialogue)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_dialogue.add_child(box)
	_dialogue_speaker = Label.new()
	_dialogue_speaker.add_theme_color_override("font_color", Color(0.7, 0.8, 0.85))
	box.add_child(_dialogue_speaker)
	_dialogue_text = Label.new()
	_dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_text.add_theme_color_override("font_color", Color(0.92, 0.9, 0.85))
	box.add_child(_dialogue_text)
	_dialogue_choices = VBoxContainer.new()
	box.add_child(_dialogue_choices)


# ------------------------------------------------------------------ Endings and menu

const EndingGood := preload("res://scripts/cutscenes/ending_good.gd")
const EndingBad := preload("res://scripts/cutscenes/ending_bad.gd")
const EndingPrison := preload("res://scripts/cutscenes/ending_prison.gd")
const MENU_SCENE := "res://scenes/menu.tscn"
const GAME_SCENE := "res://scenes/main.tscn"


## Final cutscene B: the countdown ran out. "She came. You weren't ready. She left."
func game_over() -> void:
	await _ending_sequence(EndingBad, "GAME OVER")


## He shot everyone in the center: arrested, sentenced, a cell, the years.
func prison_ending() -> void:
	await _ending_sequence(EndingPrison, "THE END")


## Final cutscene A: Recovery reached 100 and the doctor lets you go.
func good_ending() -> void:
	await _ending_sequence(EndingGood, "THE END")


func is_ending() -> bool:
	return _ending.visible


func _ending_sequence(scene_script: GDScript, title: String) -> void:
	if _busy or in_cutscene:
		return
	_busy = true
	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, Config.LEVEL_FADE_TIME)
	await out.finished
	in_cutscene = true
	var p := CutscenePlayer.new()
	add_child(p)
	_fade.color.a = 0.0
	await p.play(scene_script, true)
	in_cutscene = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_ending_text.text = title + "\n\n\n" + Config.SUPPORT_TEXT
	_ending.visible = true
	p.queue_free()
	_busy = false


## Fresh state and the first level (from the main menu).
func new_game() -> void:
	_reset_state()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await _fade_to(1.0)
	get_tree().change_scene_to_file(GAME_SCENE)
	await get_tree().process_frame
	await get_tree().process_frame
	_fade_to(0.0)


## Back to the main menu (end card, or "Main menu" in the pause menu).
func to_menu() -> void:
	_ending.visible = false
	_panel.visible = false
	_reset_state()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU_SCENE)
	await get_tree().process_frame
	_fade.color.a = 0.0


func _reset_state() -> void:
	has_gun = false
	shots_fired = false
	killed.clear()
	Withdrawal.reset()
	Recovery.reset()
	wake_message = ""
	previous_level = ""
	current_level = Config.START_LEVEL


func _fade_to(alpha: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, Config.LEVEL_FADE_TIME)
	await tw.finished


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
	_ending_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ending_text.custom_minimum_size = Vector2(520, 0)
	_ending_text.add_theme_color_override("font_color", Color(0.85, 0.85, 0.82))
	box.add_child(_ending_text)
	var hint := Label.new()
	hint.text = "[E] Main menu"
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
	if _dialogue.visible:
		if _dialogue_options == 0 and (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
			_dialogue_pick.emit(0)
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo:
			var n: int = event.physical_keycode - KEY_1
			if n >= 0 and n < _dialogue_options:
				_dialogue_pick.emit(n)
				get_viewport().set_input_as_handled()
		return
	if _ending.visible:
		if event.is_action_pressed("interact"):
			to_menu()
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
