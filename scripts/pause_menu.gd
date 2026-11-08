extends CanvasLayer
## Pause menu (ESC) with accessibility settings: screen shake and loud-sound volume.

var _root: Control
var _vol_label: Label
var _music_label: Label


func _ready() -> void:
	layer = 3
	process_mode = Node.PROCESS_MODE_ALWAYS

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font_size = Config.UI_FONT_SIZE
	_root.theme = th
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(260, 0)
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var shake := CheckBox.new()
	shake.text = "Screen shake"
	shake.button_pressed = Settings.screen_shake
	shake.toggled.connect(Settings.set_screen_shake)
	box.add_child(shake)

	_vol_label = Label.new()
	box.add_child(_vol_label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = Settings.loud_volume * 100.0
	slider.value_changed.connect(_on_volume)
	box.add_child(slider)
	_update_vol_label()

	_music_label = Label.new()
	box.add_child(_music_label)
	var music := HSlider.new()
	music.min_value = 0
	music.max_value = 100
	music.step = 5
	music.value = Settings.music_volume * 100.0
	music.value_changed.connect(func(v):
		Settings.set_music_volume(v / 100.0)
		_music_label.text = "Music: %d%%" % int(v))
	box.add_child(music)
	_music_label.text = "Music: %d%%" % int(round(Settings.music_volume * 100.0))

	var resume := Button.new()
	resume.text = "Resume"
	resume.pressed.connect(close)
	box.add_child(resume)

	var menu := Button.new()
	menu.text = "Main menu"
	menu.pressed.connect(func():
		_root.visible = false
		Game.to_menu())
	box.add_child(menu)

	if not OS.has_feature("web"):   # browsers can't quit
		var quit := Button.new()
		quit.text = "Quit"
		quit.pressed.connect(func(): get_tree().quit())
		box.add_child(quit)

	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if Game.in_cutscene or Game.is_reading() or Game.is_ending() or Game.is_talking() or Game.inventory.is_open():
		return  # these pause the game themselves
	if event.is_action_pressed("pause"):
		if _root.visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	_root.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	_root.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_volume(value: float) -> void:
	Settings.set_loud_volume(value / 100.0)
	_update_vol_label()


func _update_vol_label() -> void:
	_vol_label.text = "Loud sounds: %d%%" % int(round(Settings.loud_volume * 100.0))
