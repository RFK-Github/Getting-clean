extends "res://scripts/cutscenes/cutscene_base.gd"
## FLASHBACK 2: Lying on a Philadelphia sidewalk at night, deep in addiction.
## The camera lies on its side at pavement level. People step past. A train goes over.
## No drug use is shown - only the aftermath (an empty pill bottle on its side).

const Audio := preload("res://scripts/audio.gd")

const EYE := Vector3(0, 0.18, 0)

var _walker: Node3D
var _couple: Array[Node3D] = []
var _train: Node3D
var _police: OmniLight3D


func get_settings() -> Dictionary:
	return {
		"fog_mode": "exponential",
		"fog_color": Color(0.05, 0.06, 0.09),
		"fog_density": 0.06,
		"ambient_color": Color(0.45, 0.5, 0.7),
		"ambient_energy": 0.3,
		"tint": Color(0.75, 0.85, 1.0),
		"tint_strength": 0.3,
		"vignette": 1.2,
	}


func build() -> void:
	duration = 16.0

	cam = Camera3D.new()
	cam.fov = 75
	cam.near = 0.02
	cam.far = 80
	cam.position = EYE
	cam.rotation = Vector3(deg_to_rad(4), deg_to_rad(-10), deg_to_rad(78))  # head on the pavement
	add_child(cam)

	var sidewalk := mat("sidewalk", Color(0.8, 0.85, 1.0), 0.6)
	var asphalt := mat("asphalt", Color(0.8, 0.85, 1.0), 0.4)
	var brick := mat("brick_window", Color(0.7, 0.7, 0.8), 1.0 / 3.0)
	var steel := mat("metal", Color(0.3, 0.3, 0.32), 1.0)
	box(Vector3(0, -0.06, 0), Vector3(40, 0.12, 6), sidewalk, false, null, 2.0)
	box(Vector3(0, -0.2, -9), Vector3(40, 0.1, 12), asphalt, false, null, 2.0)
	box(Vector3(0, 6, 3.5), Vector3(40, 12, 1), brick, false, null, 3.0)          # wall behind him
	box(Vector3(0, 9, -24), Vector3(60, 18, 2), brick, false, null, 3.0)          # across the street
	for x in [-15.0, 0.0, 15.0]:
		box(Vector3(x, 3.5, -8), Vector3(0.5, 7.0, 0.5), steel, false)             # El pillars
	box(Vector3(0, 7.4, -8), Vector3(80, 0.8, 8), steel, false, null, 5.0)         # El deck

	# What's next to him: trash bags, cardboard, an empty pill bottle on its side.
	var black := mat("plain", Color(0.06, 0.06, 0.07), 1.0, false)
	box(Vector3(-1.0, 0.25, 0.8), Vector3(0.7, 0.5, 0.6), black, false)
	box(Vector3(-1.5, 0.2, 0.2), Vector3(0.6, 0.4, 0.5), black, false)
	box(Vector3(0.6, 0.01, 0.4), Vector3(1.4, 0.02, 0.9), mat("wood", Color(1.2, 1.0, 0.8), 1.0, false), false)  # cardboard
	var bottle := cylinder(Vector3(0.3, 0.045, -0.5), 0.045, 0.12, mat("plain", Color(0.75, 0.42, 0.1), 1.0, false))
	bottle.rotation = Vector3(0, 0.6, PI * 0.5)
	cylinder(Vector3(0.48, 0.015, -0.62), 0.048, 0.03, mat("plain", Color(0.85, 0.85, 0.8), 1.0, false))
	box(Vector3(0.12, 0.03, -0.28), Vector3(0.09, 0.05, 0.12), mat("plain", Config.SKIN_COLOR * 0.85, 1.0, false), false)  # his own hand

	var lamp := OmniLight3D.new()
	lamp.position = Vector3(4, 5, -2)
	lamp.light_color = Config.STREETLIGHT_COLOR
	lamp.light_energy = 1.5
	lamp.omni_range = 14
	add_child(lamp)
	_police = OmniLight3D.new()
	_police.position = Vector3(-18, 2.5, -14)
	_police.light_energy = 2.0
	_police.omni_range = 18
	add_child(_police)

	_walker = figure(Color(0.25, 0.25, 0.3), Color(0.15, 0.15, 0.18), Color(0.6, 0.45, 0.35), Color(0.1, 0.1, 0.1))
	_walker.position = Vector3(-9, 0, -1.6)
	_walker.rotation.y = -PI * 0.5
	add_child(_walker)
	for i in 2:
		var f := figure(Color(0.4, 0.3, 0.25) if i == 0 else Color(0.2, 0.25, 0.35), Color(0.2, 0.2, 0.22),
			Color(0.85, 0.7, 0.6), Color(0.3, 0.2, 0.12))
		f.position = Vector3(9 + i * 0.8, 0, -1.9 - i * 0.5)
		f.rotation.y = PI * 0.5
		add_child(f)
		_couple.append(f)

	_train = Node3D.new()
	_train.position = Vector3(-90, 8.9, -8)
	add_child(_train)
	box(Vector3(0, 0, 0), Vector3(58, 3.0, 2.9), mat("metal", Color(0.6, 0.6, 0.62), 1.0), false, _train, 4.0)
	box(Vector3(0, 0.4, 0), Vector3(56, 0.9, 2.92), mat("plain", Color(0.9, 0.85, 0.6), 1.0, false, Color(0.7, 0.65, 0.4)), false, _train)

	rain(Vector3(0, 7, -3), Vector3(10, 0.2, 7))
	sound(Audio.rain(), Config.CUTSCENE_RAIN_DB)
	sound(Audio.heartbeat(), -14.0)

	fade(Color(0, 0, 0, 1), 0.0)
	at(0.3, func(): fade(Color(0, 0, 0, 0), 1.8))     # eyes open slowly
	at(1.0, func(): say("You don't know how long you've been lying here.", 2.8))
	at(4.2, func(): say("Someone steps over your legs without slowing down.", 2.8))
	at(6.0, func(): sound(Audio.rumble(), Config.CUTSCENE_TRAIN_DB, Settings.LOUD_BUS))
	at(7.6, func(): say("Woman: \"Is he breathing?\"", 2.0))
	at(9.8, func(): say("Man: \"Leave him. They're all like this round here.\"", 2.4))
	at(12.4, func(): say("You think of her. Then you try very hard not to.", 2.8))
	at(13.2, func(): fade(Color(0, 0, 0, 0.85), 0.3))  # blink
	at(13.6, func(): fade(Color(0, 0, 0, 0.0), 0.3))
	at(14.0, func(): fade(Color(0, 0, 0, 1), 1.6))     # eyes close


func animate(delta: float) -> void:
	_police.light_color = Color(0.9, 0.1, 0.1) if fmod(t, 0.8) < 0.4 else Color(0.1, 0.2, 0.95)

	# One passer-by, not slowing down.
	if t > 2.8 and t < 9.0:
		_walker.position.x += 1.5 * delta
		walk_pose(_walker, t * 7.0)

	# A couple stops, looks down, walks on.
	for i in _couple.size():
		var f := _couple[i]
		if t > 5.5 and t < 8.0:
			f.position.x = move_toward(f.position.x, 1.4 + i * 0.7, 1.4 * delta)
			walk_pose(f, t * 7.0)
		elif t >= 8.0 and t < 11.5:
			walk_pose(f, 0.0, 0.0)
			f.get_node("head").rotation.x = -0.5   # looking down at him
		elif t >= 11.5:
			f.position.x -= 1.5 * delta   # walk on past
			walk_pose(f, t * 7.0)
			f.get_node("head").rotation.x = 0.0

	# The train overhead.
	if t > 5.8:
		_train.position.x += 22.0 * delta
	var shake := 0.0
	if Settings.screen_shake and t > 6.5 and t < 9.5:
		shake = 0.004
	cam.position = EYE + Vector3(randf_range(-shake, shake), randf_range(-shake, shake), 0)
