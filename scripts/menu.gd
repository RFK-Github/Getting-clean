extends "res://scripts/levels/level_base.gd"
## Main menu: a dim hospital corridor in the background (camera slowly creeping forward,
## one flickering light), the title, New game / Settings / Quit, and a content note.

var _cam: Camera3D
var _lamp: OmniLight3D
var _main: VBoxContainer
var _settings: VBoxContainer
var _vol_label: Label


func get_settings() -> Dictionary:
	return {
		"fog_mode": "exponential",
		"fog_color": Color(0.04, 0.05, 0.04),
		"fog_density": Config.MENU_FOG_DENSITY,
		"ambient_color": Color(0.6, 0.7, 0.6),
		"ambient_energy": 0.15,
		"tint": Config.HOSPITAL_TINT_COLOR,
		"tint_strength": 0.5,
		"vignette": 1.0,
	}


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var s := get_settings()
	add_child(make_environment(s))
	_build_corridor()
	_build_post(s)
	_build_ui()


func _process(delta: float) -> void:
	_cam.position.z -= Config.MENU_CAMERA_DRIFT * delta
	if _cam.position.z < -20.0:
		_cam.position.z = 0.0
	_lamp.light_energy = randf_range(0.0, 0.3) if randf() < 0.05 else lerpf(_lamp.light_energy, 0.9, 0.2)


func _build_corridor() -> void:
	var floor_mat := mat("linoleum", Color.WHITE, 0.5)
	var wall := mat("white_wall", Color.WHITE, 0.5)
	box(Vector3(0, -0.05, -15), Vector3(4, 0.1, 40), floor_mat, false, null, 1.5)
	box(Vector3(0, 3.05, -15), Vector3(4, 0.1, 40), mat("ceiling", Color(1.2, 1.2, 1.2), 0.5), false, null, 1.5)
	for x in [-2.0, 2.0]:
		box(Vector3(x, 1.5, -15), Vector3(0.2, 3, 40), wall, false, null, 1.5)
	var door := mat("door", Color(1.6, 1.7, 1.75), 0.8)
	for i in 6:
		box(Vector3(-1.88 if i % 2 == 0 else 1.88, 1.05, -4.0 - i * 5.0), Vector3(0.06, 2.1, 1.0), door, false)
	var lamp_mat := mat("plain", Config.LAMP_COLOR, 1.0, true, Config.LAMP_COLOR)
	for z in [-6.0, -16.0, -26.0]:
		box(Vector3(0, 2.97, z), Vector3(1.2, 0.05, 0.3), lamp_mat, false)
	_lamp = OmniLight3D.new()
	_lamp.position = Vector3(0, 2.6, -10)
	_lamp.light_color = Config.LAMP_COLOR
	_lamp.omni_range = 10
	add_child(_lamp)
	var far := OmniLight3D.new()
	far.position = Vector3(0, 2.6, -24)
	far.light_color = Config.LAMP_COLOR
	far.light_energy = 0.6
	far.omni_range = 10
	add_child(far)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 1.6, 0)
	_cam.fov = 70
	add_child(_cam)
	_cam.make_current()


func _build_post(s: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = make_post_material(s)
	layer.add_child(rect)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font_size = Config.UI_FONT_SIZE
	root.theme = th
	layer.add_child(root)

	var title := Label.new()
	title.text = Config.GAME_TITLE.to_upper()
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.85, 0.9, 0.8))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-200, 70)
	title.size = Vector2(400, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	_main = VBoxContainer.new()
	_main.set_anchors_preset(Control.PRESET_CENTER)
	_main.position = Vector2(-110, -30)
	_main.custom_minimum_size = Vector2(220, 0)
	_main.add_theme_constant_override("separation", 10)
	root.add_child(_main)
	_button(_main, "New game", func(): Game.new_game())
	_button(_main, "Settings", func(): _show_settings(true))
	_button(_main, "Credits", func(): Game.show_text("CREDITS", Config.CREDITS))
	if not OS.has_feature("web"):
		_button(_main, "Quit", func(): get_tree().quit())

	_settings = VBoxContainer.new()
	_settings.set_anchors_preset(Control.PRESET_CENTER)
	_settings.position = Vector2(-130, -40)
	_settings.custom_minimum_size = Vector2(260, 0)
	_settings.add_theme_constant_override("separation", 10)
	_settings.visible = false
	root.add_child(_settings)
	var shake := CheckBox.new()
	shake.text = "Screen shake"
	shake.button_pressed = Settings.screen_shake
	shake.toggled.connect(Settings.set_screen_shake)
	_settings.add_child(shake)
	_vol_label = Label.new()
	_settings.add_child(_vol_label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = Settings.loud_volume * 100.0
	slider.value_changed.connect(func(v):
		Settings.set_loud_volume(v / 100.0)
		_update_vol_label())
	_settings.add_child(slider)
	_update_vol_label()
	var music_label := Label.new()
	music_label.text = "Music: %d%%" % int(round(Settings.music_volume * 100.0))
	_settings.add_child(music_label)
	var music := HSlider.new()
	music.min_value = 0
	music.max_value = 100
	music.step = 5
	music.value = Settings.music_volume * 100.0
	music.value_changed.connect(func(v):
		Settings.set_music_volume(v / 100.0)
		music_label.text = "Music: %d%%" % int(v))
	_settings.add_child(music)
	_button(_settings, "Back", func(): _show_settings(false))

	var note := Label.new()
	note.text = Config.CONTENT_NOTE + "\n" + Config.SUPPORT_TEXT.split("\n")[1]
	note.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	note.offset_top = -64
	note.offset_bottom = -16
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE_SMALL)
	note.add_theme_color_override("font_color", Color(0.6, 0.62, 0.58))
	root.add_child(note)


func _button(parent: Control, text: String, on_press: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(on_press)
	parent.add_child(b)


func _show_settings(on: bool) -> void:
	_settings.visible = on
	_main.visible = not on


func _update_vol_label() -> void:
	_vol_label.text = "Loud sounds: %d%%" % int(round(Settings.loud_volume * 100.0))
