extends "res://scripts/cutscenes/cutscene_base.gd"
## FINAL CUTSCENE B (game over): visiting day. She waits in the visiting room. He isn't
## there - he wasn't ready. A nurse shakes her head. She leaves.
## "She came. You weren't ready. She left."

const Audio := preload("res://scripts/audio.gd")

var _wife_sitting: Node3D
var _wife_standing: Node3D
var _nurse: Node3D


func get_settings() -> Dictionary:
	return {
		"fog_mode": "exponential",
		"fog_color": Color(0.5, 0.53, 0.5),
		"fog_density": 0.03,
		"ambient_color": Color(0.8, 0.85, 0.8),
		"ambient_energy": 0.45,
		"tint": Color(0.85, 0.95, 0.85),
		"tint_strength": 0.3,
		"numb": 0.3,
		"vignette": 1.1,
	}


func build() -> void:
	duration = 19.0

	cam = Camera3D.new()
	cam.fov = 60
	cam.near = 0.05
	cam.far = 60
	add_child(cam)
	# Out in the corridor, looking in through the doorway.
	var hall_floor := mat("linoleum", Color.WHITE, 0.5)
	box(Vector3(0, -0.05, 5), Vector3(8, 0.1, 4), hall_floor, false)
	visiting_room(Vector3.ZERO)

	var coat := Color(0.45, 0.4, 0.38)
	_wife_sitting = figure(coat, Color(0.2, 0.22, 0.3), Color(0.85, 0.7, 0.58), Color(0.35, 0.22, 0.12), true)
	_wife_sitting.position = Vector3(0, 0, -0.8)
	_wife_sitting.rotation.y = PI
	add_child(_wife_sitting)
	_wife_standing = figure(coat, Color(0.2, 0.22, 0.3), Color(0.85, 0.7, 0.58), Color(0.35, 0.22, 0.12))
	_wife_standing.visible = false
	add_child(_wife_standing)
	_nurse = figure(Color(0.45, 0.62, 0.72), Color(0.45, 0.62, 0.72), Color(0.62, 0.45, 0.33), Color(0.1, 0.08, 0.06))
	_nurse.position = Vector3(-1.8, 0, 4.5)
	_nurse.rotation.y = 0.0
	_nurse.visible = false
	add_child(_nurse)

	sound(Audio.hum(), Config.AMBIENT_HUM_DB)
	sound(Audio.heartbeat(), -16.0)

	at(1.0, func(): say("Visiting day.", 2.2))
	at(3.4, func(): _wife_sitting.get_node("arm_l").rotation.x = 1.4)   # checks her watch
	at(4.4, func(): _wife_sitting.get_node("arm_l").rotation.x = 0.0)
	at(5.0, func(): say("She came.", 3.0))
	at(7.6, func(): _nurse.visible = true)
	at(10.2, func(): say("You weren't ready.", 3.0))
	at(12.6, func():
		_wife_sitting.visible = false
		_wife_standing.visible = true
		_wife_standing.position = Vector3(0.5, 0, -0.8)
		_wife_standing.rotation.y = PI * 0.75
		box(Vector3(0.1, 0.775, -0.1), Vector3(0.22, 0.01, 0.12), mat("plain", Color(0.92, 0.9, 0.84), 1.0, false), false))  # she leaves a letter
	at(14.6, func(): say("She left.", 3.2))
	at(17.4, func(): fade(Color(0, 0, 0, 1), 1.4))


func animate(delta: float) -> void:
	look_blend(Vector3(0.2, 1.6, 5.5), Vector3(0, 1.0, -0.8), Vector3(0, 1.0, -0.8), 0.0)
	# The nurse comes to the doorway and shakes her head.
	if _nurse.visible and t < 12.0:
		_nurse.position = _nurse.position.move_toward(Vector3(-0.6, 0, 3.4), 1.2 * delta)
		if _nurse.position.distance_to(Vector3(-0.6, 0, 3.4)) > 0.05:
			walk_pose(_nurse, t * 6.0)
		else:
			walk_pose(_nurse, 0.0, 0.0)
			_nurse.get_node("head").rotation.y = sin(t * 6.0) * 0.35
	# She walks out past the camera, toward the corridor.
	if _wife_standing.visible:
		_wife_standing.position = _wife_standing.position.move_toward(Vector3(2.5, 0, 6.0), 1.0 * delta)
		walk_pose(_wife_standing, t * 6.0)
		var to := Vector3(2.5, 0, 6.0) - _wife_standing.position
		if to.length() > 0.1:
			_wife_standing.rotation.y = lerp_angle(_wife_standing.rotation.y, atan2(-to.x, -to.z), delta * 4.0)
