extends "res://scripts/activities/activity_base.gd"
## Free throws in the courtyard. Hold the left mouse button to charge, release at the
## right moment. The aim wobbles - more with withdrawal; move the mouse to steady it.

const SPOT := Vector3(0, 0.05, -69.2)
const RIM := Vector3(0, 3.05, -74.5)

var _ball: MeshInstance3D
var _shot := 0
var _made := 0
var _state := "ready"     # ready, charging, flight, result
var _t := 0.0
var _charge := 0.0
var _power := 0.0
var _aim := 0.0           # -1..1, 0 = straight at the rim
var _steady := 0.0        # the player's correction with the mouse
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _in := false

var _power_fill: ColorRect
var _aim_dot: ColorRect


func setup() -> void:
	id = "basketball"
	player.global_position = SPOT
	player.rotation = Vector3.ZERO
	player.reset_look()
	player.head.rotation.x = 0.15
	_ball = ball_mesh(0.12, Color(0.85, 0.4, 0.12))

	# Power bar (right) with the window that goes in
	var bg := rect(Color(0, 0, 0, 0.6), Vector2(1, 0.5), Vector2(-60, -100), Vector2(18, 200))
	var lo := 1.0 - Config.SHOT_SWEET_MAX
	rect(Color(0.3, 0.6, 0.3, 0.8), Vector2(0, 0), Vector2(0, 200 * lo), Vector2(18, 200 * (Config.SHOT_SWEET_MAX - Config.SHOT_SWEET_MIN)), bg)
	_power_fill = rect(Color(0.9, 0.85, 0.7), Vector2(0, 0), Vector2(4, 196), Vector2(10, 0), bg)
	# Aim bar (under the crosshair) with the window that goes in
	var aim_bg := rect(Color(0, 0, 0, 0.6), Vector2(0.5, 0.5), Vector2(-120, 60), Vector2(240, 10))
	rect(Color(0.3, 0.6, 0.3, 0.8), Vector2(0, 0), Vector2(120 - 120 * Config.AIM_TOLERANCE, 0), Vector2(240 * Config.AIM_TOLERANCE, 10), aim_bg)
	_aim_dot = rect(Color(0.95, 0.9, 0.7), Vector2(0, 0), Vector2(117, -3), Vector2(6, 16), aim_bg)

	help_label.text = "Hold LEFT MOUSE to charge, release to shoot. Move the mouse to steady your aim."
	comment("Look who showed up. Let's see that shot.")
	_update_title()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_steady -= event.screen_relative.x * Config.AIM_MOUSE
		_steady = clampf(_steady, -1.0, 1.0)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _state == "ready":
			_state = "charging"
			_charge = 0.0
		elif not event.pressed and _state == "charging":
			_shoot()


func tick(delta: float) -> void:
	_t += delta
	# The aim drifts by itself; withdrawal makes it worse.
	var a := Config.AIM_DRIFT_BASE + Withdrawal.meter / Config.METER_MAX * Config.AIM_DRIFT_WITHDRAWAL
	var drift := sin(_t * 1.9) * a + sin(_t * 3.7) * a * 0.5 + randf_range(-0.02, 0.02) * a
	_aim = clampf(drift + _steady, -1.0, 1.0)
	_aim_dot.position.x = 117 + _aim * 117

	match _state:
		"ready", "charging":
			if _state == "charging":
				_charge += delta
				_power = pingpong01(_charge / Config.SHOT_CHARGE_TIME)
			_power_fill.position.y = 196 - _power * 192
			_power_fill.size.y = _power * 192
			_ball.global_position = player.camera.global_position - player.camera.global_basis.z * 0.5 \
				+ player.camera.global_basis.x * 0.12 - Vector3(0, 0.25, 0)
		"flight":
			var s := clampf(_t / 0.95, 0.0, 1.0)
			_ball.global_position = _from.lerp(_to, s) + Vector3(0, 2.0 * 4.0 * s * (1.0 - s), 0)
			if s >= 1.0:
				_state = "result"
				_t = 0.0
				_from = _ball.global_position
		"result":
			# Through the net, or off the rim onto the court.
			var fall := Vector3(0, -3.0 * _t, 0) if _in else Vector3(_aim * 1.5, 0.5 - 6.0 * _t, 1.5) * _t
			_ball.global_position = _from + fall
			_ball.global_position.y = maxf(_ball.global_position.y, 0.12)
			if _t > 1.3:
				if _shot >= Config.BASKETBALL_SHOTS:
					comment("Not bad. Same time tomorrow?" if _made >= Config.BASKETBALL_GOOD else "Rough day. You showed up, though.")
					finish(_made >= Config.BASKETBALL_GOOD)
				else:
					_state = "ready"
					_power = 0.0


func _shoot() -> void:
	_shot += 1
	var good_power := _power >= Config.SHOT_SWEET_MIN and _power <= Config.SHOT_SWEET_MAX
	_in = good_power and absf(_aim) <= Config.AIM_TOLERANCE
	_from = _ball.global_position
	_to = RIM
	if not _in:
		var depth := (0.7 - _power) * 1.6   # short (+) or long (-)
		_to = RIM + Vector3(_aim * 1.0, 0, clampf(depth, -0.6, 1.4))
	else:
		_made += 1
	_state = "flight"
	_t = 0.0
	if _in:
		comment(["Nice shot!", "Swish.", "Again, again!"][randi() % 3])
	elif not good_power:
		comment("Too soft." if _power < Config.SHOT_SWEET_MIN else "Too hard, man.")
	else:
		comment("Unlucky. Steady your hands.")
	_update_title()


func _update_title() -> void:
	title_label.text = "FREE THROWS   shot %d/%d   made %d" % [mini(_shot + (1 if _state != "result" else 0), Config.BASKETBALL_SHOTS), Config.BASKETBALL_SHOTS, _made]


func cleanup() -> void:
	if is_instance_valid(_ball):
		_ball.queue_free()
