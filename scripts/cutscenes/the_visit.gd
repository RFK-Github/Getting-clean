extends "res://scripts/cutscenes/cutscene_base.gd"
## THE VISIT: plays right after the third flashback, once he knows the truth.
## His wife comes to see him. For him it has been a few weeks. For her it has been years.
## She has met someone else, and came to tell him herself.

const Audio := preload("res://scripts/audio.gd")

const ROOM := Vector3(0, 0, 0)
const NUMBER_WORDS := ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
const DOOR_LOOK := [[26.0, 29.0], [39.0, 99.0]]   # when he turns to look at the doorway

var _wife_sitting: Node3D
var _wife_standing: Node3D
var _man: Node3D
var _ring: MeshInstance3D
var _door_look := 0.0
var _leaving := false
var _walk_target := 0


func get_settings() -> Dictionary:
	return {
		"fog_mode": "exponential",
		"fog_color": Color(0.62, 0.64, 0.66),
		"fog_density": 0.02,
		"ambient_color": Color(0.85, 0.88, 0.9),
		"ambient_energy": 0.45,
		"tint": Color(0.9, 0.93, 0.97),
		"tint_strength": 0.25,
		"vignette": 0.9,
	}


func build() -> void:
	duration = 46.0
	var years: int = Config.YEAR_NOW - Config.YEAR_HE_THINKS
	var years_text: String = (NUMBER_WORDS[years] if years < NUMBER_WORDS.size() else str(years)) + (" year" if years == 1 else " years")

	cam = Camera3D.new()
	cam.fov = 65
	cam.near = 0.05
	cam.far = 80
	add_child(cam)

	visiting_room(ROOM)
	var skin := mat("plain", Config.SKIN_COLOR, 1.0, false)
	for x in [-0.18, 0.18]:   # his hands on the table
		box(ROOM + Vector3(x, 0.79, 0.3), Vector3(0.09, 0.05, 0.13), skin, false)

	# She is older than he remembers: grey in her hair.
	var coat := Color(0.3, 0.33, 0.4)
	var hair := Color(0.42, 0.36, 0.3)
	var face := Color(0.85, 0.7, 0.58)
	_wife_sitting = figure(coat, Color(0.2, 0.2, 0.24), face, hair, true)
	_wife_sitting.position = ROOM + Vector3(0, 0, -0.8)
	_wife_sitting.rotation.y = PI   # facing him
	add_child(_wife_sitting)
	_wife_standing = figure(coat, Color(0.2, 0.2, 0.24), face, hair)
	_wife_standing.visible = false
	add_child(_wife_standing)

	# The other man, waiting in the doorway behind him.
	_man = figure(Color(0.4, 0.38, 0.3), Color(0.22, 0.22, 0.25), Color(0.82, 0.66, 0.55), Color(0.15, 0.12, 0.1))
	_man.position = ROOM + Vector3(0.25, 0, 3.4)
	add_child(_man)   # faces -Z: into the room

	var torus := TorusMesh.new()
	torus.inner_radius = 0.012
	torus.outer_radius = 0.017
	torus.material = mat("plain", Color(0.9, 0.75, 0.3), 1.0, false, Color(0.3, 0.24, 0.08))
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.position = ROOM + Vector3(0.05, 0.79, -0.3)
	_ring.visible = false
	add_child(_ring)

	sound(Audio.hum(), Config.AMBIENT_HUM_DB)

	at(0.8, func(): say("They bring you to the visiting room. She's already there.", 3.0))
	at(4.0, func(): say("Your wife: \"Hi.\"", 2.0))
	at(6.2, func(): say("There's grey in her hair. There wasn't, a few weeks ago.", 3.0))
	at(9.4, func(): say("You: \"I'm doing better. A few more weeks and I can come home.\"", 3.2))
	at(12.8, func(): say("She looks at you for a long time.", 2.4))
	at(15.4, func(): say("Your wife: \"It's been %s.\"" % years_text, 2.8))
	at(18.4, func(): say("Your wife: \"I came. I wrote. Most days you didn't know who I was.\"", 3.4))
	at(22.0, func(): say("Your wife: \"I've met someone. He's kind. He's patient with me.\"", 3.4))
	at(26.0, func(): say("Someone is waiting in the doorway. He looks at the floor.", 2.8))
	at(29.4, func(): say("Your wife: \"I wanted to tell you myself. You deserved that much.\"", 3.4))
	at(33.0, func():
		_ring.visible = true
		say("She slides her ring across the table. She touches your hand, once.", 3.0))
	at(36.2, func(): say("Your wife: \"Get well. Not for me. For her.\"", 2.8))
	at(38.6, func():
		_wife_sitting.visible = false
		_wife_standing.visible = true
		_wife_standing.position = ROOM + Vector3(0.55, 0, -0.75)
		_leaving = true)
	at(41.0, func(): say("He takes her hand at the door. Neither of them looks back.", 3.2))
	at(44.2, func(): fade(Color(0, 0, 0, 1), 1.6))


func animate(delta: float) -> void:
	# Turn round to the doorway at the right moments.
	var looking := false
	for span in DOOR_LOOK:
		looking = looking or (t > span[0] and t < span[1])
	_door_look = move_toward(_door_look, 1.0 if looking else 0.0, delta * 0.8)
	var eye := ROOM + Vector3(0, 1.22, 0.8)
	var at_her := ROOM + Vector3(0, 1.1, -0.8)
	if _ring.visible and t < 36.0:
		at_her = at_her.lerp(_ring.global_position, 0.25)
	var at_door := ROOM + Vector3(0.3, 1.4, 3.4)
	look_blend(eye, at_her, at_door, smoothstep(0.0, 1.0, _door_look))

	# She looks down at the table, then up at him.
	var head: Node3D = _wife_sitting.get_node("head")
	head.rotation.x = -0.35 if (t > 12.8 and t < 15.4) or (t > 18.4 and t < 22.0) or t > 33.0 else 0.0
	# He keeps his eyes on the floor.
	_man.get_node("head").rotation.x = -0.4

	if _leaving:
		# Past his chair to the door, then out together with the other man.
		var path := [ROOM + Vector3(0.75, 0, 1.6), ROOM + Vector3(0.1, 0, 3.2), ROOM + Vector3(0.1, 0, 9.0)]
		var target: Vector3 = path[mini(_walk_target, path.size() - 1)]
		var to := target - _wife_standing.position
		if to.length() < 0.1 and _walk_target < path.size() - 1:
			_walk_target += 1
		elif to.length() > 0.05:
			_wife_standing.position += to.normalized() * minf(1.0 * delta, to.length())
			_wife_standing.rotation.y = atan2(-to.x, -to.z)
			walk_pose(_wife_standing, t * 6.0)
		if _walk_target == path.size() - 1:
			_man.rotation.y = PI   # turns and walks out with her
			_man.position += Vector3(0, 0, 1.0 * delta)
			walk_pose(_man, t * 6.0 + 1.0)
