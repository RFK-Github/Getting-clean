extends "res://scripts/cutscenes/cutscene_base.gd"
## FLASHBACK 1: Driving at sunset. He looks back at his daughter in the back seat and they
## laugh together. His wife suddenly screams. Cut to black.
## The car stands still at the origin facing -Z; the road and the world move past it.

const Audio := preload("res://scripts/audio.gd")

const EYE := Vector3(-0.38, 1.3, 0.05)     # driver's seat (left)
const RANGE := 210.0                        # moving scenery wraps over this length

var _moving: Array[Node3D] = []
var _wife: Node3D
var _girl: Node3D
var _oncoming: Node3D
var _look_back := 0.0


func get_settings() -> Dictionary:
	return {
		"fog_mode": "exponential",
		"fog_color": Color(0.78, 0.55, 0.38),
		"fog_density": 0.018,
		"ambient_color": Color(1.0, 0.85, 0.7),
		"ambient_energy": 0.55,
		"tint": Color(1.0, 0.85, 0.65),
		"tint_strength": 0.3,
		"vignette": 1.0,
	}


func build() -> void:
	duration = 12.5

	cam = Camera3D.new()
	cam.fov = 70
	cam.near = 0.05
	cam.far = 250
	add_child(cam)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.75, 0.5)
	sun.light_energy = 0.9
	sun.rotation_degrees = Vector3(-8, 170, 0)   # low sun ahead of the car
	add_child(sun)

	_build_car()
	_build_road()

	var paint := mat("car", Color(0.3, 0.32, 0.36), 1.0, false)
	_oncoming = Node3D.new()
	_oncoming.position = Vector3(-2.6, 0, -200)
	add_child(_oncoming)
	box(Vector3(0, 0.6, 0), Vector3(1.9, 0.7, 4.6), paint, false, _oncoming)
	var lamp := mat("plain", Color.WHITE, 1.0, false, Color(1.0, 1.0, 0.95))
	for x in [-0.6, 0.6]:
		box(Vector3(x, 0.65, 2.31), Vector3(0.4, 0.18, 0.04), lamp, false, _oncoming)
	var beam := SpotLight3D.new()
	beam.position = Vector3(0, 0.7, 2.4)
	beam.rotation_degrees.y = 180
	beam.light_energy = 6.0
	beam.spot_range = 40.0
	beam.spot_angle = 35.0
	_oncoming.add_child(beam)

	sound(Audio.traffic(), Config.CUTSCENE_ENGINE_DB)

	at(0.6, func(): say("Daughter: \"Daddy! Do the funny voice again!\"", 2.2))
	at(3.2, func(): say("You do the voice. She laughs so hard she can't breathe.", 2.6))
	at(6.0, func(): say("Daughter: \"Again! Again!\"", 1.8))
	at(7.9, func(): say("You're laughing too. You haven't looked at the road in a while.", 1.6))
	at(9.4, func():
		say("Your wife: \"LOOK OUT!\"", 1.2)
		sound(Audio.scream(), Config.CUTSCENE_SCREAM_DB, Settings.LOUD_BUS)
		sound(Audio.horn(), Config.CUTSCENE_SCREAM_DB, Settings.LOUD_BUS))
	at(10.15, func(): fade(Color(1, 1, 0.95, 1), 0.2))
	at(10.4, func():
		stop_all_sounds()
		subtitle_label.text = ""
		fade(Color(0, 0, 0, 1), 0.0))


func animate(delta: float) -> void:
	# The world passes the car.
	for n in _moving:
		n.position.z += Config.FLASHBACK_DRIVE_SPEED * delta
		if n.position.z > 20.0:
			n.position.z -= RANGE

	# The other car: far away in its lane, then suddenly in ours.
	if t > 8.6:
		_oncoming.position.z += (Config.FLASHBACK_DRIVE_SPEED + Config.FLASHBACK_ONCOMING_SPEED) * delta
		if t > 9.2:
			_oncoming.position.x = move_toward(_oncoming.position.x, 0.0, delta * 4.0)
	else:
		_oncoming.position.z = -200.0

	# Camera: forward, then over the right shoulder at her, then snapped back to the road.
	var target := 0.0
	if t > 2.4 and t < 9.4:
		target = 1.0
	_look_back = move_toward(_look_back, target, delta * (5.0 if t >= 9.4 else 1.0))
	var w := smoothstep(0.0, 1.0, _look_back)
	# Turning round he leans toward the middle, so he can see her between the seats.
	var eye := EYE.lerp(EYE + Vector3(0.24, 0.06, 0.1), w)
	look_blend(eye, eye + Vector3(0, -0.05, -1), Vector3(0.0, 1.12, 1.05), w)

	# She laughs: head bobs and arms flap.
	if t > 3.0 and t < 9.4:
		_girl.get_node("head").rotation.x = sin(t * 13.0) * 0.18
		_girl.get_node("arm_l").rotation.x = 1.6 + sin(t * 9.0) * 0.4
		_girl.get_node("arm_r").rotation.x = 1.6 + sin(t * 9.0 + 1.0) * 0.4
	# The wife smiles over at you, then looks forward and throws her arms up.
	var wife_head := _wife.get_node("head")
	if t < 9.3:
		wife_head.rotation.y = lerpf(wife_head.rotation.y, 0.7 if t > 4.0 else 0.0, delta * 3.0)
	else:
		wife_head.rotation.y = 0.0
		_wife.get_node("arm_l").rotation.x = lerpf(_wife.get_node("arm_l").rotation.x, 2.4, delta * 10.0)
		_wife.get_node("arm_r").rotation.x = lerpf(_wife.get_node("arm_r").rotation.x, 2.4, delta * 10.0)


func _build_car() -> void:
	var interior := mat("fabric", Color(0.5, 0.45, 0.4), 2.0, false)
	var dash := mat("plain", Color(0.15, 0.14, 0.14), 1.0, false)
	var body := mat("car", Color(0.45, 0.12, 0.1), 1.0, false)
	box(Vector3(0, 0.05, 0.4), Vector3(1.6, 0.1, 2.8), dash, false)               # floor
	box(Vector3(0, 0.95, -0.85), Vector3(1.6, 0.35, 0.5), dash, false)            # dashboard
	box(Vector3(0, 0.85, -1.7), Vector3(1.6, 0.12, 1.3), body, false)             # bonnet
	box(Vector3(0, 1.62, 0.3), Vector3(1.6, 0.06, 2.1), interior, false)          # roof
	for x in [-0.78, 0.78]:
		box(Vector3(x, 0.75, 0.3), Vector3(0.06, 0.55, 2.5), body, false)        # doors
		var pillar := box(Vector3(x, 1.3, -0.82), Vector3(0.06, 0.65, 0.06), body, false)
		pillar.rotation.x = deg_to_rad(-30)
	for x in [-0.38, 0.38]:
		box(Vector3(x, 0.4, 0.15), Vector3(0.5, 0.4, 0.5), interior, false)      # front seats
		box(Vector3(x, 0.85, 0.42), Vector3(0.5, 0.55, 0.12), interior, false)   # low backs: she can be seen
	box(Vector3(0, 0.4, 1.05), Vector3(1.4, 0.4, 0.5), interior, false)          # back bench
	box(Vector3(0, 0.95, 1.32), Vector3(1.4, 0.75, 0.12), interior, false)
	box(Vector3(0.0, 0.68, 1.02), Vector3(0.42, 0.15, 0.4), mat("plain", Color(0.7, 0.3, 0.4), 1.0, false), false)  # booster seat

	# Steering wheel and his hands on it
	var wheel := TorusMesh.new()
	wheel.inner_radius = 0.16
	wheel.outer_radius = 0.19
	wheel.rings = 12
	wheel.ring_segments = 4
	wheel.material = dash
	var wheel_mi := MeshInstance3D.new()
	wheel_mi.mesh = wheel
	wheel_mi.position = Vector3(-0.38, 1.05, -0.55)
	wheel_mi.rotation_degrees.x = 60
	add_child(wheel_mi)
	var skin := mat("plain", Config.SKIN_COLOR, 1.0, false)
	var sleeve := mat("fabric", Config.JACKET_COLOR * 2.5, 2.0, false)
	for x in [-0.55, -0.21]:
		box(Vector3(x, 1.08, -0.52), Vector3(0.08, 0.06, 0.11), skin, false)
		var arm := box(Vector3(x * 0.9, 1.0, -0.3), Vector3(0.09, 0.09, 0.42), sleeve, false)
		arm.rotation.x = deg_to_rad(-15)

	_wife = figure(Color(0.55, 0.35, 0.4), Color(0.2, 0.22, 0.3), Color(0.85, 0.7, 0.58), Color(0.35, 0.22, 0.12), true)
	_wife.position = Vector3(0.38, 0.13, 0.15)
	add_child(_wife)
	_girl = figure(Color(0.95, 0.75, 0.3), Color(0.3, 0.4, 0.7), Color(0.88, 0.72, 0.6), Color(0.45, 0.3, 0.15), true, 0.6)
	_girl.position = Vector3(0.0, 0.47, 1.05)   # middle of the back seat
	add_child(_girl)


func _build_road() -> void:
	var asphalt := mat("asphalt", Color.WHITE, 0.4)
	box(Vector3(0, -0.05, -100), Vector3(9, 0.1, 260), asphalt, false, null, 4.0)
	box(Vector3(0, -0.1, -100), Vector3(80, 0.05, 260), mat("grass", Color(1.1, 0.9, 0.6), 0.3), false, null, 8.0)
	var paint := mat("plain", Color(0.9, 0.85, 0.6), 1.0)
	box(Vector3(1.9, 0.005, -100), Vector3(0.12, 0.01, 260), paint, false, null, 8.0)   # edge line
	var trunk := mat("wood", Color.WHITE, 1.0)
	var leaves := mat("grass", Color(1.0, 0.9, 0.55), 1.0)
	var z := 15.0
	var i := 0
	while z > 15.0 - RANGE:
		i += 1
		_moving.append(box(Vector3(-1.4, 0.005, z), Vector3(0.12, 0.01, 2.5), paint, false))  # centre dashes
		if i % 2 == 0:   # a pair of trees every 12 m
			for side in [-1.0, 1.0]:
				var tree := Node3D.new()
				tree.position = Vector3(side * randf_range(6.0, 12.0), 0, z + randf_range(-3, 3))
				add_child(tree)
				box(Vector3(0, 1.5, 0), Vector3(0.35, 3.0, 0.35), trunk, false, tree)
				box(Vector3(0, 3.8, 0), Vector3(2.8, 2.4, 2.8), leaves, false, tree)
				_moving.append(tree)
		z -= 6.0

	# Low sun ahead, behind the haze
	var quad := QuadMesh.new()
	quad.size = Vector2(40, 40)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = Tex.get_texture("sun")
	m.albedo_color = Color(1.0, 0.8, 0.5, 0.6)
	m.set("disable_fog", true)
	quad.material = m
	var disc := MeshInstance3D.new()
	disc.mesh = quad
	disc.position = Vector3(25, 14, -220)
	add_child(disc)
