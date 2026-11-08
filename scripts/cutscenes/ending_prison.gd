extends "res://scripts/cutscenes/cutscene_base.gd"
## ENDING: he shot everyone in the recovery center. The police take him; then a cell,
## and the years go by on the wall. She never visits.

const Audio := preload("res://scripts/audio.gd")

const LOBBY := Vector3(0, 0, 0)
const CELL := Vector3(200, 0, 0)

var _police: Array[OmniLight3D] = []
var _officers: Array[Node3D] = []
var _marks: Array[Node3D] = []
var _sun: DirectionalLight3D
var _in_cell := false


func get_settings() -> Dictionary:
	return {
		"fog_mode": "exponential",
		"fog_color": Color(0.05, 0.05, 0.07),
		"fog_density": 0.05,
		"ambient_color": Color(0.6, 0.62, 0.7),
		"ambient_energy": 0.25,
		"tint": Color(0.8, 0.85, 1.0),
		"tint_strength": 0.4,
		"numb": 0.2,
		"vignette": 1.1,
	}


func build() -> void:
	duration = 36.0
	cam = Camera3D.new()
	cam.fov = 65
	cam.near = 0.05
	cam.far = 60
	add_child(cam)
	_build_lobby()
	_build_cell()
	sound(Audio.siren(), -6.0, "Master", true)

	at(0.8, func(): say("They find you sitting on the floor of the lobby. You don't fight.", 3.4))
	at(4.6, func(): say("Police: \"Hands where we can see them. Slowly.\"", 3.0))
	at(8.0, func(): fade(Color(0, 0, 0, 1), 0.8))
	at(9.0, func():
		stop_all_sounds()
		say("Guilty. On every count.", 3.0))
	at(12.2, func():
		_in_cell = true
		world_env.environment.fog_density = 0.02
		fade(Color(0, 0, 0, 0), 1.5))
	at(13.6, func(): say("Life. No parole.", 2.6))
	at(17.0, func(): say("The days stop having names.", 2.8))
	at(21.0, func(): say("Nobody visits. Not her. Not anyone.", 3.0))
	at(25.0, func(): say("You think about the girl in the yellow dress. You stop thinking about anything.", 3.6))
	at(29.5, func(): say("You stop counting.", 2.6))
	at(33.0, func(): fade(Color(0, 0, 0, 1), 2.5))


func animate(delta: float) -> void:
	if not _in_cell:
		for i in _police.size():
			_police[i].light_energy = 2.5 if fmod(t * 2.0 + i * 0.5, 1.0) < 0.5 else 0.2
		for o in _officers:
			if o.position.z < LOBBY.z - 2.0:
				o.position.z += 0.9 * delta
				walk_pose(o, t * 6.0)
			else:
				walk_pose(o, 0.0, 0.0)
		# On his knees in the middle of the lobby, looking up at the door.
		look_blend(LOBBY + Vector3(0, 0.95, 0), LOBBY + Vector3(0, 1.3, -6), LOBBY + Vector3(0, 1.3, -6), 0.0)
		return
	# The cell: sun crosses the wall again and again; the marks pile up.
	var years := (t - 12.2) / (33.0 - 12.2)
	_sun.rotation.y = deg_to_rad(-40.0 + fmod((t - 12.2) * 90.0, 80.0))
	_sun.light_energy = 0.6 + 0.3 * sin(t * 4.0)
	var shown := int(pow(clampf(years, 0.0, 1.0), 1.5) * _marks.size())
	for i in _marks.size():
		_marks[i].visible = i < shown
	var eye := CELL + Vector3(0.8, 1.05, 1.0)
	look_blend(eye, CELL + Vector3(-1.1, 1.2, 0.0), CELL + Vector3(-1.1, 1.2, 0.0), 0.0)


func _build_lobby() -> void:
	var floor_mat := mat("linoleum", Color(0.7, 0.7, 0.75), 0.5)
	var wall := mat("white_wall", Color(0.6, 0.6, 0.65), 0.5)
	box(LOBBY + Vector3(0, -0.05, -5), Vector3(16, 0.1, 14), floor_mat, false, null, 2.0)
	box(LOBBY + Vector3(0, 1.5, -12), Vector3(16, 3, 0.2), wall, false, null, 2.0)
	box(LOBBY + Vector3(-8, 1.5, -5), Vector3(0.2, 3, 14), wall, false, null, 2.0)
	box(LOBBY + Vector3(8, 1.5, -5), Vector3(0.2, 3, 14), wall, false, null, 2.0)
	box(LOBBY + Vector3(0, 3.05, -5), Vector3(16, 0.1, 14), mat("ceiling", Color.WHITE, 0.5), false, null, 2.0)
	box(LOBBY + Vector3(0, 1.1, -11.85), Vector3(3.0, 2.2, 0.1), mat("plain", Color(0.15, 0.17, 0.2), 1.0, true, Color(0.08, 0.1, 0.15)), false)
	for i in 3:
		var l := OmniLight3D.new()
		l.position = LOBBY + Vector3(-1.5 + i * 1.5, 2.2, -11.0)
		l.light_color = Color(0.9, 0.1, 0.1) if i % 2 == 0 else Color(0.1, 0.25, 1.0)
		l.omni_range = 14.0
		add_child(l)
		_police.append(l)
	for x in [-1.2, 0.0, 1.2]:
		var o := figure(Color(0.08, 0.1, 0.2), Color(0.06, 0.07, 0.12), Color(0.7, 0.55, 0.45), Color(0.05, 0.05, 0.05))
		o.position = LOBBY + Vector3(x, 0, -10.5 + absf(x) * 0.6)
		o.rotation.y = PI   # facing him
		o.get_node("arm_l").rotation.x = 1.3   # arms out, holding something
		o.get_node("arm_r").rotation.x = 1.3
		add_child(o)
		_officers.append(o)


func _build_cell() -> void:
	var concrete := mat("concrete", Color(0.75, 0.75, 0.78), 0.8)
	var steel := mat("metal", Color(0.35, 0.36, 0.38), 1.0)
	box(CELL + Vector3(0, -0.05, 0), Vector3(3.0, 0.1, 4.0), concrete, false, null, 1.0)
	box(CELL + Vector3(0, 2.75, 0), Vector3(3.0, 0.1, 4.0), concrete, false, null, 1.0)
	box(CELL + Vector3(-1.5, 1.35, 0), Vector3(0.2, 2.7, 4.0), concrete, false, null, 1.0)
	box(CELL + Vector3(1.5, 1.35, 0), Vector3(0.2, 2.7, 4.0), concrete, false, null, 1.0)
	box(CELL + Vector3(0, 1.35, -2.0), Vector3(3.0, 2.7, 0.2), concrete, false, null, 1.0)
	for i in 12:   # bars
		box(CELL + Vector3(-1.4 + i * 0.25, 1.35, 2.0), Vector3(0.04, 2.7, 0.04), steel, false)
	box(CELL + Vector3(0.9, 0.35, 0.6), Vector3(0.8, 0.12, 1.9), steel, false)          # bunk
	box(CELL + Vector3(0.9, 0.45, 0.6), Vector3(0.75, 0.1, 1.85), mat("fabric", Color(0.7, 0.7, 0.72), 2.0, false), false)
	box(CELL + Vector3(-1.1, 0.25, -1.5), Vector3(0.4, 0.5, 0.45), steel, false)       # toilet
	box(CELL + Vector3(0, 2.2, -1.89), Vector3(0.5, 0.3, 0.04), mat("plain", Color(0.9, 0.9, 0.8), 1.0, true, Color(0.8, 0.8, 0.7)), false)   # small high window
	# Tally marks scratched into the wall: groups of four strokes and one across.
	var scratch := mat("plain", Color(0.18, 0.18, 0.2), 1.0, false)
	for i in 300:
		var group := i / 5
		var col := group % 14
		var row := group / 14
		var gx := -1.0 + col * 0.14   # along the wall (z)
		var gy := 2.1 - row * 0.12
		var m: Node3D
		if i % 5 == 4:
			m = box(CELL + Vector3(-1.395, gy, gx + 0.04), Vector3(0.004, 0.012, 0.12), scratch, false)
			m.rotation.x = 0.6
		else:
			m = box(CELL + Vector3(-1.395, gy, gx + (i % 5) * 0.025), Vector3(0.004, 0.08, 0.008), scratch, false)
		m.visible = false
		_marks.append(m)
	_sun = DirectionalLight3D.new()
	_sun.light_color = Color(1.0, 0.95, 0.85)
	_sun.rotation_degrees = Vector3(-35, -40, 0)
	_sun.light_energy = 0.0
	add_child(_sun)
