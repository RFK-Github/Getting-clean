extends "res://scripts/activities/activity_base.gd"
## Penalty kicks on the lawn against a patient goalkeeper.
## Aim with the mouse (the marker on the goal), hold the left mouse button to choose power.

const SPOT := Vector3(-31.5, 0.11, -68.0)
const GOAL_X := -42.5
const GOAL_Z := -68.0
const HALF_W := 3.66
const BAR := 2.44

var _ball: MeshInstance3D
var _marker: MeshInstance3D
var _keeper: Node3D
var _keeper_home := Vector3.ZERO
var _kick := 0
var _goals := 0
var _state := "ready"     # ready, charging, flight, result
var _t := 0.0
var _charge := 0.0
var _power := 0.0
var _aim := Vector2(0.0, 1.0)   # x = along the goal (z offset), y = height
var _dive := 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _outcome := ""

var _power_fill: ColorRect
var _car: Node3D
var _car_done := false
var _flash: ColorRect
var _car_sounds: Array[AudioStreamPlayer] = []
const Audio := preload("res://scripts/audio.gd")


func setup() -> void:
	id = "football"
	player.global_position = Vector3(SPOT.x + 1.2, 0.05, SPOT.z)
	player.rotation = Vector3(0, PI * 0.5, 0)   # face -X, toward the goal
	player.reset_look()
	player.head.rotation.x = 0.0
	_ball = ball_mesh(0.11, Color(0.9, 0.9, 0.88))
	_ball.global_position = SPOT
	_marker = ball_mesh(0.08, Color(1.0, 0.3, 0.2))
	_keeper = level.find_child("Goalie", true, false) as Node3D
	if _keeper:
		_keeper_home = _keeper.global_position

	var bg := rect(Color(0, 0, 0, 0.6), Vector2(1, 0.5), Vector2(-60, -100), Vector2(18, 200))
	rect(Color(0.3, 0.6, 0.3, 0.8), Vector2(0, 0), Vector2(0, 200 * (1.0 - Config.PENALTY_POWER_MAX)),
		Vector2(18, 200 * (Config.PENALTY_POWER_MAX - Config.PENALTY_POWER_MIN)), bg)
	_power_fill = rect(Color(0.9, 0.85, 0.7), Vector2(0, 0), Vector2(4, 196), Vector2(10, 0), bg)

	help_label.text = "Move the MOUSE to aim at the goal. Hold LEFT MOUSE for power, release to shoot."
	comment("Finally, someone to play with. Go on then.")
	_update_title()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (_state == "ready" or _state == "charging"):
		_aim.x += event.screen_relative.x * Config.PENALTY_AIM_MOUSE
		_aim.y -= event.screen_relative.y * Config.PENALTY_AIM_MOUSE
		_aim = Vector2(clampf(_aim.x, -HALF_W - 1.0, HALF_W + 1.0), clampf(_aim.y, 0.1, BAR + 1.0))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _state == "ready":
			_state = "charging"
			_charge = 0.0
		elif not event.pressed and _state == "charging":
			_shoot()


func tick(delta: float) -> void:
	_t += delta
	# Withdrawal makes the aim tremble a little.
	var shake := Withdrawal.meter / Config.METER_MAX * 0.15
	var aim := _aim + Vector2(sin(_t * 9.0), cos(_t * 7.0)) * shake
	# Seen from the spot, the goal's "left" is +Z.
	_marker.global_position = Vector3(GOAL_X + 0.05, aim.y, GOAL_Z - aim.x)

	match _state:
		"ready", "charging":
			if _state == "charging":
				_charge += delta
				_power = pingpong01(_charge / Config.PENALTY_CHARGE_TIME)
			_power_fill.position.y = 196 - _power * 192
			_power_fill.size.y = _power * 192
		"flight":
			var s := clampf(_t / 0.55, 0.0, 1.0)
			_ball.global_position = _from.lerp(_to, s)
			if _keeper:   # the keeper dives
				var k := clampf(_t / 0.35, 0.0, 1.0)
				_keeper.global_position = _keeper_home + Vector3(0, 0, -_dive * k)
				_keeper.rotation.z = signf(_dive) * 1.1 * k
			if s >= 1.0:
				_state = "result"
				_t = 0.0
				_from = _ball.global_position
		"car":
			_tick_car(delta)
		"after_car":
			_flash.color.a = maxf(0.0, _flash.color.a - delta * 1.5)
			player.set_shake("scare", 0.0)
			if _t > 2.5:
				_ball.global_position = SPOT
				_state = "ready"
				_power = 0.0
		"result":
			var drift := Vector3(-1.2, 0, 0) if _outcome == "goal" else Vector3(2.5, 0, randf_range(-0.5, 0.5))
			_ball.global_position = _from + drift * minf(_t, 0.5)
			_ball.global_position.y = maxf(_from.y - 4.0 * _t * _t, 0.11)
			if _t > 1.5:
				if _keeper:
					_keeper.global_position = _keeper_home
					_keeper.rotation.z = 0.0
				if _kick == Config.FOOTBALL_CAR_KICK and not _car_done:
					_start_car()
					return
				if _kick >= Config.PENALTIES:
					comment("Okay, okay. You've played before." if _goals >= Config.PENALTY_GOOD else "Ha! Come back tomorrow, I'll go easy.")
					finish(_goals >= Config.PENALTY_GOOD)
				else:
					_ball.global_position = SPOT
					_state = "ready"
					_power = 0.0


func _shoot() -> void:
	_kick += 1
	_dive = [-2.2, 0.0, 2.2][randi() % 3]
	var aim := _aim
	if _power > Config.PENALTY_POWER_MAX:
		aim.y += 1.5   # skied it
	var target := Vector3(GOAL_X - 0.3, aim.y, GOAL_Z - aim.x)
	var on_target := absf(aim.x) < HALF_W and aim.y < BAR
	var saved := _power < Config.PENALTY_POWER_MIN or (absf(aim.x - _dive) < Config.KEEPER_REACH and aim.y < 2.0)
	if not on_target:
		_outcome = "miss"
		comment("Over the bar!" if aim.y >= BAR else "Way wide, man.")
	elif saved:
		_outcome = "save"
		target = Vector3(GOAL_X + 0.6, clampf(aim.y, 0.3, 1.5), GOAL_Z - _dive)
		comment("Not today!" if _power >= Config.PENALTY_POWER_MIN else "That was a pass, not a shot.")
	else:
		_outcome = "goal"
		_goals += 1
		comment(["Ah! Good one.", "Top corner. Unfair.", "Okay, that was nice."][randi() % 3])
	_from = SPOT
	_to = target
	_state = "flight"
	_t = 0.0
	_update_title()


func _update_title() -> void:
	title_label.text = "PENALTIES   kick %d/%d   goals %d" % [mini(_kick + (1 if _state == "ready" else 0), Config.PENALTIES), Config.PENALTIES, _goals]


func cleanup() -> void:
	for n in [_ball, _marker]:
		if is_instance_valid(n):
			n.queue_free()
	if _car != null and is_instance_valid(_car):
		_car.queue_free()
	player.set_shake("scare", 0.0)
	if _keeper:
		_keeper.global_position = _keeper_home
		_keeper.rotation.z = 0.0


# ------------------------------------------------------------------ The car

## Headlights behind the goal. A car comes straight through the net at him - and is gone.
func _start_car() -> void:
	_car_done = true
	_state = "car"
	_t = 0.0
	_flash = rect(Color(1, 1, 0.95, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0))
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_car = Node3D.new()
	_car.position = Vector3(GOAL_X - 14.0, 0, GOAL_Z)
	_car.rotation.y = -PI * 0.5   # front (-Z) toward +X, at him
	level.add_child(_car)
	var paint := Psx.material(Tex.get_texture("car"), Color(0.3, 0.32, 0.36), 1.0, false)
	var dark := Psx.material(Tex.get_texture("plain"), Color(0.08, 0.08, 0.1), 1.0, false)
	var lamp := Psx.material(Tex.get_texture("plain"), Color.WHITE, 1.0, false, Color(1, 1, 0.95))
	_car_part(Vector3(0, 0.62, 0), Vector3(1.8, 0.6, 4.4), paint)
	_car_part(Vector3(0, 1.15, 0.3), Vector3(1.6, 0.5, 2.2), dark)
	for x in [-0.6, 0.6]:
		_car_part(Vector3(x, 0.7, -2.21), Vector3(0.38, 0.16, 0.04), lamp)
	var beam := SpotLight3D.new()
	beam.position = Vector3(0, 0.7, -2.4)
	beam.light_energy = 8.0
	beam.spot_range = 40.0
	beam.spot_angle = 35.0
	_car.add_child(beam)
	for s in [Audio.horn(), Audio.scream()]:
		var p := AudioStreamPlayer.new()
		p.stream = s
		p.bus = Settings.LOUD_BUS
		p.volume_db = Config.CUTSCENE_SCREAM_DB
		add_child(p)
		p.play()
		_car_sounds.append(p)


func _tick_car(delta: float) -> void:
	_car.position.x += Config.FOOTBALL_CAR_SPEED * delta
	var dist := player.global_position.x - _car.position.x
	player.set_shake("scare", clampf(1.0 - dist / 20.0, 0.0, 1.0) * 0.05)
	_flash.color.a = clampf(1.0 - (dist - 2.6) / 6.0, 0.0, 1.0) * 0.9
	if dist < 2.8:   # gone, right before it hits him
		_car.queue_free()
		_car = null
		for p in _car_sounds:
			p.stop()
		_flash.color.a = 1.0
		_state = "after_car"
		_t = 0.0
		Withdrawal.post_message("Nothing. There's nothing there.")
		get_tree().create_timer(1.6, false).timeout.connect(func(): comment("...You okay, man? You went white."))


func _car_part(pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	_car.add_child(mi)
