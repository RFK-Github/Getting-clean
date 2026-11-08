extends "res://scripts/activities/activity_base.gd"
## Swimming laps. Alternate LEFT and RIGHT (A/D or the arrow keys) in rhythm with the beat.
## A stroke on the beat pushes you forward; a missed or wrong stroke makes you sink a little.

const LANE_X := 28.5
const START_Z := -20.6
const LENGTH := 19.2
const WATER_EYE := 0.28     # camera height above the water

var _t := 0.0
var _dist := 0.0
var _speed := 0.0
var _sink := 0.0
var _next_beat: float = Config.SWIM_BEAT
var _beat_used := false
var _expect := "move_left"
var _good := 0
var _strokes := 0
var _misses_in_a_row := 0

var _key_label: Label
var _pulse: ColorRect
var _progress: ColorRect
var _under: ColorRect


func setup() -> void:
	id = "swimming"
	player.set_physics_process(false)   # we move him through the water ourselves
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.reset_look()
	_place_swimmer()

	_under = rect(Color(0.1, 0.3, 0.4, 0.0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0))
	_under.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pulse = rect(Color(0.9, 0.95, 1.0, 0.0), Vector2(0.5, 0.5), Vector2(-60, -100), Vector2(120, 6))
	_key_label = label("", Vector2(0.5, 0.5), Vector2(-150, -90), Vector2(300, 30))
	_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_key_label.add_theme_font_size_override("font_size", 24)
	var bar := rect(Color(0, 0, 0, 0.6), Vector2(0.5, 0), Vector2(-150, 84), Vector2(300, 8))
	_progress = rect(Color(0.6, 0.85, 0.95), Vector2(0, 0), Vector2(0, 0), Vector2(0, 8), bar)

	help_label.text = "Alternate LEFT and RIGHT (A / D or arrow keys) on the beat."
	Withdrawal.post_message("Nurse Dale: \"Nice and steady. Find your rhythm.\"")
	_update()


func _unhandled_input(event: InputEvent) -> void:
	for action in ["move_left", "move_right"]:
		if event.is_action_pressed(action):
			_stroke(action)
			get_viewport().set_input_as_handled()


func _stroke(action: String) -> void:
	_strokes += 1
	var on_beat := not _beat_used and absf(_t - _next_beat) <= Config.SWIM_WINDOW
	if on_beat and action == _expect:
		_good += 1
		_beat_used = true
		_speed += Config.SWIM_STROKE_PUSH
		_expect = "move_right" if _expect == "move_left" else "move_left"
		_misses_in_a_row = 0
	else:
		_miss()


func _miss() -> void:
	_sink = minf(_sink + Config.SWIM_SINK_PER_MISS, 1.0)
	_speed *= 0.6
	_misses_in_a_row += 1
	if _misses_in_a_row == 3:
		Withdrawal.post_message("Nurse Dale: \"Breathe! Keep your rhythm!\"")


func tick(delta: float) -> void:
	_t += delta
	# The beat: if a beat passes without a stroke, you sink a little.
	if _t > _next_beat + Config.SWIM_WINDOW:
		if not _beat_used:
			_miss()
		_next_beat += Config.SWIM_BEAT
		_beat_used = false
	var to_beat := absf(_t - _next_beat)
	_pulse.color.a = clampf(1.0 - to_beat / Config.SWIM_WINDOW, 0.0, 1.0) * 0.9

	_speed *= exp(-Config.SWIM_DRAG * delta)
	_dist += _speed * delta
	_sink = maxf(0.0, _sink - delta * 0.25)
	_under.color.a = _sink * 0.55
	_place_swimmer()
	_update()

	if _dist >= Config.SWIM_DISTANCE:
		var accuracy := float(_good) / maxf(1.0, float(_strokes))
		var well := accuracy >= Config.SWIM_GOOD_ACCURACY
		Withdrawal.post_message("Nurse Dale: \"%s\"" % ("Good to see you here. Really." if well else "Two lengths. That counts. Well done."))
		finish(well)
	elif _t > Config.SWIM_TIME_LIMIT:
		Withdrawal.post_message("You hold on to the edge, out of breath. Nurse Dale: \"That's enough for today.\"")
		finish(false)


## Lane position: down the pool and back. Facing the way he swims, bobbing with each stroke.
func _place_swimmer() -> void:
	var lap := int(_dist / LENGTH)
	var along := fmod(_dist, LENGTH)
	var z := START_Z - along if lap % 2 == 0 else START_Z - LENGTH + along
	player.rotation.y = 0.0 if lap % 2 == 0 else PI
	var eye_y := WATER_EYE - _sink * 0.35 + sin(_t * TAU / Config.SWIM_BEAT) * 0.04
	player.global_position = Vector3(LANE_X, eye_y - Config.PLAYER_HEIGHT, z)


func _update() -> void:
	_key_label.text = "<  LEFT" if _expect == "move_left" else "RIGHT  >"
	_progress.size.x = 300.0 * clampf(_dist / Config.SWIM_DISTANCE, 0.0, 1.0)
	title_label.text = "SWIMMING   %d / %d m   %d s" % [int(_dist), int(Config.SWIM_DISTANCE), int(maxf(0.0, Config.SWIM_TIME_LIMIT - _t))]


func cleanup() -> void:
	player.set_physics_process(true)
	player.global_position = Vector3(LANE_X, 0.05, -18.6)
	player.rotation = Vector3.ZERO
