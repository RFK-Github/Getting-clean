extends Node
## Player settings (saved to user://settings.cfg), input map and display setup.

signal changed

const PATH := "user://settings.cfg"
const LOUD_BUS := "Loud"

var screen_shake := true
var loud_volume := 1.0  # 0..1 for loud sounds


func _ready() -> void:
	_setup_display()
	_setup_input()
	_setup_audio_bus()
	load_settings()
	apply()


func set_screen_shake(value: bool) -> void:
	screen_shake = value
	save_settings()
	changed.emit()


func set_loud_volume(value: float) -> void:
	loud_volume = clampf(value, 0.0, 1.0)
	apply()
	save_settings()
	changed.emit()


func apply() -> void:
	var i := AudioServer.get_bus_index(LOUD_BUS)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(loud_volume, 0.0001)))
	AudioServer.set_bus_mute(i, loud_volume <= 0.001)


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	screen_shake = cf.get_value("accessibility", "screen_shake", true)
	loud_volume = cf.get_value("accessibility", "loud_volume", 1.0)


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("accessibility", "screen_shake", screen_shake)
	cf.set_value("accessibility", "loud_volume", loud_volume)
	cf.save(PATH)


## Internal resolution comes from Config; the window scales it up (stretch mode "viewport").
func _setup_display() -> void:
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = Config.INTERNAL_RESOLUTION
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web") \
			and win.mode == Window.MODE_WINDOWED:
		win.size = Config.WINDOW_SIZE
		win.move_to_center()


## 0..1: muffles all sound with a low-pass filter on the Master bus (under the influence).
func set_muffle(amount: float) -> void:
	var on := amount > 0.01
	if AudioServer.is_bus_effect_enabled(0, 0) != on:
		AudioServer.set_bus_effect_enabled(0, 0, on)
	if on:
		var lp := AudioServer.get_bus_effect(0, 0) as AudioEffectLowPassFilter
		lp.cutoff_hz = lerpf(20000.0, Config.INFLUENCE_MUFFLE_HZ, clampf(amount / Config.INFLUENCE_NUMB, 0.0, 1.0))


func _setup_audio_bus() -> void:
	if AudioServer.get_bus_effect_count(0) == 0:
		AudioServer.add_bus_effect(0, AudioEffectLowPassFilter.new())
		AudioServer.set_bus_effect_enabled(0, 0, false)
	if AudioServer.get_bus_index(LOUD_BUS) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, LOUD_BUS)
	AudioServer.set_bus_send(i, "Master")


func _setup_input() -> void:
	_bind("move_forward", [KEY_W, KEY_UP])
	_bind("move_back", [KEY_S, KEY_DOWN])
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("sprint", [KEY_SHIFT])
	_bind("flashlight", [KEY_F])
	_bind("interact", [KEY_E])
	_bind("pause", [KEY_ESCAPE])


func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
