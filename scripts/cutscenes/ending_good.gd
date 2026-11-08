extends "res://scripts/cutscenes/cutscene_base.gd"
## FINAL CUTSCENE A (good ending): his wife visits - but only to say goodbye. She has met
## someone else. Then he stands alone at his daughter's grave, clean.

const Audio := preload("res://scripts/audio.gd")

const ROOM := Vector3(0, 0, 0)
const GRAVE := Vector3(200, 0, 0)

var _wife_sitting: Node3D
var _wife_standing: Node3D
var _ring: MeshInstance3D
var _sun: DirectionalLight3D
var _at_grave := false


func get_settings() -> Dictionary:
	return {
		"fog_mode": "exponential",
		"fog_color": Color(0.7, 0.72, 0.7),
		"fog_density": 0.02,
		"ambient_color": Color(0.9, 0.92, 0.88),
		"ambient_energy": 0.5,
		"tint": Color(0.95, 0.97, 0.9),
		"tint_strength": 0.2,
		"vignette": 0.8,
	}


func build() -> void:
	duration = 40.0
	var years := Config.YEAR_NOW - Config.YEAR_HE_THINKS

	cam = Camera3D.new()
	cam.fov = 65
	cam.near = 0.05
	cam.far = 80
	add_child(cam)

	visiting_room(ROOM)
	# His hands on the table
	var skin := mat("plain", Config.SKIN_COLOR, 1.0, false)
	for x in [-0.18, 0.18]:
		box(ROOM + Vector3(x, 0.79, 0.3), Vector3(0.09, 0.05, 0.13), skin, false)

	var coat := Color(0.45, 0.4, 0.38)
	_wife_sitting = figure(coat, Color(0.2, 0.22, 0.3), Color(0.85, 0.7, 0.58), Color(0.35, 0.22, 0.12), true)
	_wife_sitting.position = ROOM + Vector3(0, 0, -0.8)
	_wife_sitting.rotation.y = PI   # facing him
	add_child(_wife_sitting)
	_wife_standing = figure(coat, Color(0.2, 0.22, 0.3), Color(0.85, 0.7, 0.58), Color(0.35, 0.22, 0.12))
	_wife_standing.visible = false
	add_child(_wife_standing)

	var torus := TorusMesh.new()
	torus.inner_radius = 0.012
	torus.outer_radius = 0.017
	torus.material = mat("plain", Color(0.9, 0.75, 0.3), 1.0, false, Color(0.3, 0.24, 0.08))
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.position = ROOM + Vector3(0.05, 0.79, -0.3)
	_ring.visible = false
	add_child(_ring)

	grave_set(GRAVE)
	_sun = DirectionalLight3D.new()
	_sun.light_color = Color(1.0, 0.9, 0.7)
	_sun.light_energy = 0.0
	_sun.rotation_degrees = Vector3(-25, 150, 0)
	add_child(_sun)

	sound(Audio.hum(), Config.AMBIENT_HUM_DB)

	at(0.8, func(): say("She's already sitting when they bring you in.", 3.0))
	at(4.0, func(): say("Your wife: \"You look... clean. You really do.\"", 3.0))
	at(7.2, func(): say("Your wife: \"I'm glad. I need you to know that I'm glad.\"", 3.0))
	at(10.4, func(): say("She turns her cup in her hands. She doesn't drink.", 2.8))
	at(13.4, func(): say("Your wife: \"It's been %d years. I waited. For a long time, I waited.\"" % years, 3.4))
	at(17.0, func(): say("Your wife: \"I've met someone. He's kind. He's patient with me.\"", 3.2))
	at(20.4, func(): say("Your wife: \"I didn't come to take you home. I came to say goodbye. Properly, this time.\"", 3.6))
	at(23.4, func():
		_ring.visible = true
		say("She slides her ring across the table. Then she touches your hand, once.", 2.6))
	at(25.0, func():
		_wife_sitting.visible = false
		_wife_standing.visible = true
		_wife_standing.position = ROOM + Vector3(0.6, 0, -0.9)
		_wife_standing.rotation.y = atan2(-1.0, -1.0))   # facing the door (+X, +Z)
	at(26.5, func(): fade(Color(0, 0, 0, 1), 1.0))
	at(27.6, func():
		stop_all_sounds()
		_at_grave = true
		var env := world_env.environment
		env.fog_light_color = Color(0.8, 0.78, 0.7)
		env.background_color = Color(0.8, 0.78, 0.7)
		fade(Color(0, 0, 0, 0), 1.6))
	at(28.6, func(): say("Every week, you come here. Clean.", 3.0))
	at(32.0, func(): say("Forever seven years old.", 2.6))
	at(35.0, func(): say("You don't run from it any more. You stay. You hold on.", 3.2))
	at(38.2, func(): fade(Color(0, 0, 0, 1), 1.6))


func animate(delta: float) -> void:
	if not _at_grave:
		var eye := ROOM + Vector3(0, 1.22, 0.8)
		look_blend(eye, ROOM + Vector3(0, 1.1, -0.8), _ring.global_position, 0.25 if t > 23.4 and t < 25.0 else 0.0)
		# She looks down, then up at him.
		var head: Node3D = _wife_sitting.get_node("head")
		head.rotation.x = -0.35 if (t > 10.0 and t < 13.4) or t > 20.4 else 0.0
		if _wife_standing.visible:   # she walks out through the door
			_wife_standing.position += Vector3(1.0, 0, 1.0).normalized() * 1.0 * delta
			walk_pose(_wife_standing, t * 6.0)
	else:
		# The sun breaks through while he stands at her stone.
		_sun.light_energy = minf(_sun.light_energy + delta * 0.15, 0.9)
		var eye := GRAVE + Vector3(0, 1.6, 0.4 - (t - 27.6) * 0.02)
		look_blend(eye, GRAVE + Vector3(0, 0.6, -1.6), GRAVE + Vector3(0, 0.6, -1.6), 0.0)
