extends "res://scripts/cutscenes/cutscene_base.gd"
## FLASHBACK 3: Standing at the daughter's gravestone in the rain. His wife beside him.
## The teddy bear from the hospital sits at the foot of the stone.

const Audio := preload("res://scripts/audio.gd")

const STONE := Vector3(0, 0.6, -1.6)

var _wife: Node3D
var _eye := Vector3(0, 1.6, 0.25)
var _look := 0.0


func get_settings() -> Dictionary:
	return {
		"fog_mode": "exponential",
		"fog_color": Color(0.55, 0.58, 0.6),
		"fog_density": 0.06,
		"ambient_color": Color(0.75, 0.78, 0.82),
		"ambient_energy": 0.6,
		"tint": Color(0.85, 0.9, 0.95),
		"tint_strength": 0.3,
		"numb": 0.3,
		"vignette": 1.0,
	}


func build() -> void:
	duration = 18.0

	cam = Camera3D.new()
	cam.fov = 65
	cam.near = 0.05
	cam.far = 80
	add_child(cam)

	var grass := mat("grass", Color(0.85, 0.95, 0.85), 0.5)
	var stone := mat("concrete", Color(0.75, 0.76, 0.78), 1.0)
	box(Vector3(0, -0.05, -10), Vector3(60, 0.1, 50), grass, false, null, 3.0)

	# The other graves
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for row in 4:
		for col in 7:
			var x := -9.0 + col * 3.0 + rng.randf_range(-0.4, 0.4)
			var z := -5.0 - row * 3.5
			if absf(x) < 1.5 and row == 0:
				continue
			var g := box(Vector3(x, 0.4, z), Vector3(0.6, 0.8, 0.15), stone, false)
			g.rotation.z = rng.randf_range(-0.06, 0.06)
	# Bare trees
	var bark := mat("wood", Color(0.6, 0.6, 0.6), 1.0)
	for p in [Vector3(-7, 0, -3), Vector3(8, 0, -9), Vector3(-12, 0, -16)]:
		box(p + Vector3(0, 2.5, 0), Vector3(0.3, 5.0, 0.3), bark, false)
		var branch := box(p + Vector3(0.6, 4.0, 0), Vector3(0.12, 1.8, 0.12), bark, false)
		branch.rotation.z = -0.7

	# Her stone
	box(STONE + Vector3(0, -0.1, 0), Vector3(0.9, 1.0, 0.18), stone, false)
	box(Vector3(0, 0.06, -1.6), Vector3(1.1, 0.12, 0.45), stone, false)
	var ink := Color(0.22, 0.22, 0.24)
	sign_text("BELOVED DAUGHTER", STONE + Vector3(0, 0.22, 0.095), 0, 30, ink)
	sign_text("Forever seven years old", STONE + Vector3(0, 0.06, 0.095), 0, 18, ink)
	sign_text("We will always hold your hand", STONE + Vector3(0, -0.1, 0.095), 0, 14, ink)

	# The teddy bear and flowers at the foot of the stone
	var fur := mat("fabric", Color(1.4, 1.0, 0.65), 3.0, false)
	var bear := Node3D.new()
	bear.position = Vector3(-0.25, 0.12, -1.3)
	bear.rotation.y = 0.3
	add_child(bear)
	box(Vector3(0, 0.1, 0), Vector3(0.17, 0.2, 0.13), fur, false, bear)
	box(Vector3(0, 0.26, 0), Vector3(0.14, 0.13, 0.12), fur, false, bear)
	for sx in [-0.06, 0.06]:
		box(Vector3(sx, 0.34, 0), Vector3(0.04, 0.04, 0.03), fur, false, bear)
	for i in 5:
		var c: Color = [Color(0.85, 0.85, 0.8), Color(0.9, 0.6, 0.65), Color(0.9, 0.85, 0.4)][i % 3]
		box(Vector3(0.12 + i * 0.06, 0.16, -1.32 + (i % 2) * 0.05), Vector3(0.05, 0.05, 0.05), mat("plain", c, 1.0, false), false)

	# His wife, a little apart, under an umbrella
	_wife = figure(Color(0.12, 0.12, 0.14), Color(0.1, 0.1, 0.12), Color(0.85, 0.7, 0.58), Color(0.35, 0.22, 0.12))
	_wife.position = Vector3(1.5, 0, -0.5)
	_wife.rotation.y = 0.5
	add_child(_wife)
	var black := mat("plain", Color(0.06, 0.06, 0.07), 1.0, false)
	var umbrella := Node3D.new()
	umbrella.position = Vector3(1.5, 0, -0.5)
	add_child(umbrella)
	cylinder(Vector3(0.15, 2.1, 0), 0.7, 0.05, black, umbrella)
	box(Vector3(0.15, 1.6, 0), Vector3(0.02, 1.0, 0.02), black, false, umbrella)
	_wife.set_meta("umbrella", umbrella)
	_wife.get_node("arm_r").rotation.x = 1.0

	rain(Vector3(0, 7, -4), Vector3(9, 0.2, 9))
	sound(Audio.rain(), Config.CUTSCENE_RAIN_DB + 4.0)

	at(1.0, func(): say("Rain on the stone. You read the words again. And again.", 3.2))
	at(4.8, func(): say("Seven years old.", 2.4))
	at(8.4, func(): say("Your wife: \"We have to go.\"", 2.2))
	at(10.8, func(): say("You don't move.", 1.8))
	at(12.8, func(): say("Your wife: \"...I can't keep doing this alone.\"", 2.6))
	at(15.4, func(): say("You stay until it's dark.", 2.2))
	at(16.4, func(): fade(Color(0, 0, 0, 1), 1.5))


func animate(delta: float) -> void:
	# A slow push toward the stone; look at her while she speaks, back to the stone when she leaves.
	_eye = _eye.move_toward(Vector3(0, 1.55, -0.15), delta * 0.03)
	var target := 1.0 if (t > 7.6 and t < 14.4) else 0.0
	_look = move_toward(_look, target, delta * 0.7)
	look_blend(_eye, STONE, Vector3(1.5, 1.5, -0.5), smoothstep(0.0, 1.0, _look))

	if t > 13.6:   # she walks away
		var umbrella: Node3D = _wife.get_meta("umbrella")
		_wife.rotation.y = lerp_angle(_wife.rotation.y, -2.3, delta * 2.0)
		var dir := Vector3(1.0, 0, 1.0).normalized()
		_wife.position += dir * 1.1 * delta
		umbrella.position = _wife.position
		walk_pose(_wife, t * 6.0)
		_wife.get_node("arm_r").rotation.x = 1.0
