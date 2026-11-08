extends "res://scripts/cutscenes/cutscene_base.gd"
## FLASHBACK 1: Driving at sunset. He looks back at his daughter in the back seat and they
## laugh together. Not watching the road, he drifts over the centre line toward an oncoming
## car. His wife screams; he swerves, misses it - and goes off the road into a tree.
## The car stands still at the origin facing -Z; the world (road, trees) moves past it,
## and slides sideways as the car drifts toward the edge.

const Audio := preload("res://scripts/audio.gd")
const GhostCar := preload("res://scripts/props/ghost_car.gd")

const EYE := Vector3(-0.38, 1.3, 0.05)     # driver's seat (left)
const RANGE := 210.0                        # moving scenery wraps over this length
const TURN_BACK := 8.6                      # he turns back to the road: headlights, right ahead
const LOOK_OUT := 9.0                       # she screams, he swerves
const IMPACT := 10.3                        # they hit the tree
const DRIFT_LEFT := 1.4                     # drifting over the centre line while he looks back (m)
const DRIFT := 2.6                          # where the swerve ends: off the road on the right (m)
const PASS_TIME := 9.6                      # the other car passes them here (just missed)
const BONNET_FRONT := -2.35

var _world: Node3D                          # road + trees: moved sideways for the drift
var _moving: Array[Node3D] = []
var _tree: Node3D                           # the one they hit
var _oncoming: Node3D                       # the car he swerves to avoid
var _wife: Node3D
var _girl: Node3D
var _bonnet: Node3D
var _glass: Node3D
var _cracks: Array[Node3D] = []
var _look_back := 0.0
var _crashed := false
var _jolt := 0.0


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
	duration = 13.5

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
	_world = Node3D.new()
	add_child(_world)
	_build_road()

	sound(Audio.traffic(), Config.CUTSCENE_ENGINE_DB)

	at(0.6, func(): say("Daughter: \"Daddy! Do the funny voice again!\"", 2.2))
	at(3.2, func():
		say("You do the voice. She laughs so hard she can't breathe.", 2.6)
		sound(Audio.child_laugh(), -4.0, "Master", true).pitch_scale = Config.CHILD_VOICE_PITCH)
	at(4.9, func(): sound(Audio.child_laugh(), -6.0, "Master", true).pitch_scale = Config.CHILD_VOICE_PITCH * 1.05)
	at(6.0, func():
		say("Daughter: \"Again! Again!\"", 1.8)
		sound(Audio.child_laugh(), -4.0, "Master", true).pitch_scale = Config.CHILD_VOICE_PITCH * 1.1)
	at(TURN_BACK + 0.1, func(): sound(Audio.horn(), Config.CUTSCENE_SCREAM_DB, Settings.LOUD_BUS, true))   # the other car
	at(7.5, func(): say("You're laughing too. You haven't looked at the road in a while.", 1.1))
	at(LOOK_OUT, func():
		say("Your wife: \"LOOK OUT!\"", 1.0)
		sound(Audio.scream(), Config.CUTSCENE_SCREAM_DB, Settings.LOUD_BUS, true))
	at(LOOK_OUT + 0.35, func(): sound(Audio.child_scream(), Config.CUTSCENE_SCREAM_DB, Settings.LOUD_BUS, true))
	at(IMPACT, func():
		_crash()
		sound(Audio.crash(), Config.CUTSCENE_SCREAM_DB + 2.0, Settings.LOUD_BUS, true))
	at(IMPACT + 0.55, func(): fade(Color(0, 0, 0, 1), 0.15))
	at(IMPACT + 0.75, func():
		stop_all_sounds()
		subtitle_label.text = ""
		sound(Audio.tinnitus(), Config.TINNITUS_DB - 4.0, Settings.LOUD_BUS, true))   # ringing in the dark


func animate(delta: float) -> void:
	if not _crashed:
		# The world passes the car (the tree they hit doesn't wrap around).
		var step := Config.FLASHBACK_DRIVE_SPEED * delta
		for n in _moving:
			n.position.z += step
			if n.position.z > 20.0:
				n.position.z -= RANGE
		_tree.position.z += step
		# While he looks back the car drifts left, over the centre line. Then he swerves right,
		# past the other car and off the road. (The world moves the opposite way.)
		if t < LOOK_OUT:
			_world.position.x = smoothstep(4.5, LOOK_OUT, t) * DRIFT_LEFT
		else:
			_world.position.x = lerpf(DRIFT_LEFT, -DRIFT, smoothstep(LOOK_OUT, IMPACT - 0.1, t))
		_oncoming.position.z = (t - PASS_TIME) * (Config.FLASHBACK_DRIVE_SPEED + Config.FLASHBACK_ONCOMING_SPEED)

	# Camera: forward, then over the right shoulder at her, then snapped back to the road.
	var target := 1.0 if (t > 2.4 and t < TURN_BACK) else 0.0
	_look_back = move_toward(_look_back, target, delta * (4.0 if t >= TURN_BACK else 1.0))
	var w := smoothstep(0.0, 1.0, _look_back)
	var eye := EYE.lerp(EYE + Vector3(0.24, 0.06, 0.1), w)
	var look_ahead := eye + Vector3(0, -0.05, -1)
	if t > LOOK_OUT and not _crashed:
		look_ahead += Vector3(0.45 * sin(clampf((t - LOOK_OUT) / (IMPACT - LOOK_OUT), 0.0, 1.0) * PI), 0, 0)   # yanking the wheel right
	# The crash: thrown forward into the belt, then back; the world tilts.
	if _crashed:
		_jolt += delta
		var k := exp(-_jolt * 5.0)
		eye += Vector3(0, -0.12 * k, -0.35 * sin(minf(_jolt * 14.0, PI)) )
		var s := 0.06 * k * (1.0 if Settings.screen_shake else 0.3)
		eye += Vector3(randf_range(-s, s), randf_range(-s, s), 0)
	look_blend(eye, look_ahead, Vector3(0.0, 1.12, 1.05), w)
	if _crashed:
		cam.rotation.z = lerpf(cam.rotation.z, 0.22, clampf(delta * 12.0, 0.0, 1.0))

	# She laughs: head bobs and arms flap.
	if t > 3.0 and t < TURN_BACK:
		_girl.get_node("head").rotation.x = sin(t * 13.0) * 0.18
		_girl.get_node("arm_l").rotation.x = 1.6 + sin(t * 9.0) * 0.4
		_girl.get_node("arm_r").rotation.x = 1.6 + sin(t * 9.0 + 1.0) * 0.4
	# The wife smiles over at you, then looks forward and throws her arms up.
	var wife_head := _wife.get_node("head")
	if t < TURN_BACK - 0.2:
		wife_head.rotation.y = lerpf(wife_head.rotation.y, 0.7 if t > 4.0 else 0.0, delta * 3.0)
	else:
		wife_head.rotation.y = 0.0
		_wife.get_node("arm_l").rotation.x = lerpf(_wife.get_node("arm_l").rotation.x, 2.4, delta * 10.0)
		_wife.get_node("arm_r").rotation.x = lerpf(_wife.get_node("arm_r").rotation.x, 2.4, delta * 10.0)


## The moment of impact: everything stops, the bonnet buckles, the windscreen cracks,
## everyone is thrown forward.
func _crash() -> void:
	_crashed = true
	_tree.position.z = BONNET_FRONT - 0.35
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_bonnet, "rotation:x", 0.35, 0.08)
	tw.tween_property(_bonnet, "position:y", 0.98, 0.08)
	tw.tween_property(_bonnet, "scale:z", 0.6, 0.08)
	for c in _cracks:
		c.visible = true
	for f in [_wife, _girl]:
		tw.tween_property(f, "position:z", f.position.z - 0.18, 0.06)
		tw.tween_property(f.get_node("head"), "rotation:x", -0.7, 0.06)


func _build_car() -> void:
	var interior := mat("fabric", Color(0.5, 0.45, 0.4), 2.0, false)
	var dash := mat("plain", Color(0.15, 0.14, 0.14), 1.0, false)
	var body := mat("car", Color(0.45, 0.12, 0.1), 1.0, false)
	box(Vector3(0, 0.05, 0.4), Vector3(1.6, 0.1, 2.8), dash, false)               # floor
	box(Vector3(0, 0.95, -0.85), Vector3(1.6, 0.35, 0.5), dash, false)            # dashboard
	_bonnet = Node3D.new()
	_bonnet.position = Vector3(0, 0.85, -1.1)                                      # hinged at the windscreen
	add_child(_bonnet)
	box(Vector3(0, 0, -0.65), Vector3(1.6, 0.12, 1.3), body, false, _bonnet)       # bonnet
	box(Vector3(0, 1.62, 0.3), Vector3(1.6, 0.06, 2.1), interior, false)          # roof
	for x in [-0.78, 0.78]:
		box(Vector3(x, 0.75, 0.3), Vector3(0.06, 0.55, 2.5), body, false)        # doors
	# Windscreen frame: two pillars leaning back from the dashboard to the roof, and a top bar.
	var bottom := Vector3(0, 1.1, -1.08)
	var top := Vector3(0, 1.6, -0.74)
	var mid := (bottom + top) * 0.5
	var lean := atan2(top.z - bottom.z, top.y - bottom.y)
	var length := bottom.distance_to(top)
	for x in [-0.77, 0.77]:
		var pillar := box(Vector3(x, mid.y, mid.z), Vector3(0.06, length, 0.06), body, false)
		pillar.rotation.x = lean
	box(Vector3(0, top.y, top.z), Vector3(1.6, 0.06, 0.08), body, false)
	# The glass (faint), and the cracks that appear on impact
	_glass = Node3D.new()
	_glass.position = mid
	_glass.rotation.x = lean
	add_child(_glass)
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.albedo_color = Color(0.8, 0.85, 0.9, 0.06)
	box(Vector3.ZERO, Vector3(1.5, length, 0.01), glass, false, _glass)
	var crack := mat("plain", Color(0.85, 0.86, 0.84), 1.0, false, Color(0.2, 0.2, 0.2))
	var centre := Vector3(-0.3, 0.05, 0.0)
	for i in 9:
		var a := TAU * i / 9.0 + 0.3
		var crack_len := randf_range(0.18, 0.4)
		var c := box(centre + Vector3(cos(a), sin(a), 0) * crack_len * 0.5, Vector3(crack_len, 0.004, 0.008), crack, false, _glass)
		c.rotation.z = a
		c.visible = false
		_cracks.append(c)
	for r in [0.08, 0.16]:
		for i in 6:
			var a := TAU * i / 6.0
			var c := box(centre + Vector3(cos(a), sin(a), 0) * r, Vector3(r * 0.9, 0.004, 0.008), crack, false, _glass)
			c.rotation.z = a + PI * 0.5
			c.visible = false
			_cracks.append(c)

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
	box(Vector3(0, -0.05, -100), Vector3(9, 0.1, 260), asphalt, false, _world, 4.0)
	box(Vector3(0, -0.1, -100), Vector3(80, 0.05, 260), mat("grass", Color(1.1, 0.9, 0.6), 0.3), false, _world, 8.0)
	var paint := mat("plain", Color(0.9, 0.85, 0.6), 1.0)
	box(Vector3(1.9, 0.005, -100), Vector3(0.12, 0.01, 260), paint, false, _world, 8.0)   # edge line
	var trunk := mat("wood", Color.WHITE, 1.0)
	var leaves := mat("grass", Color(1.0, 0.9, 0.55), 1.0)
	var z := 15.0
	var i := 0
	while z > 15.0 - RANGE:
		i += 1
		_moving.append(box(Vector3(-1.4, 0.005, z), Vector3(0.12, 0.01, 2.5), paint, false, _world))  # centre dashes
		if i % 2 == 0:   # a pair of trees every 12 m
			for side in [-1.0, 1.0]:
				var tree := _tree_node(trunk, leaves, 0.35)
				tree.position = Vector3(side * randf_range(6.0, 12.0), 0, z + randf_range(-3, 3))
				_moving.append(tree)
		z -= 6.0

	# The other car, in the oncoming lane. It passes them just as he swerves.
	_oncoming = GhostCar.new()
	_oncoming.rotation.y = PI   # front toward +Z, toward them
	_oncoming.position = Vector3(-2.9, 0, -PASS_TIME * (Config.FLASHBACK_DRIVE_SPEED + Config.FLASHBACK_ONCOMING_SPEED))
	_world.add_child(_oncoming)

	# The tree: a thick old one right by the edge. They reach it exactly at the impact.
	_tree = _tree_node(trunk, leaves, 0.7)
	_tree.position = Vector3(DRIFT, 0, BONNET_FRONT - 0.35 - Config.FLASHBACK_DRIVE_SPEED * IMPACT)

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


func _tree_node(trunk: Material, leaves: Material, thickness: float) -> Node3D:
	var tree := Node3D.new()
	_world.add_child(tree)
	box(Vector3(0, 1.5, 0), Vector3(thickness, 3.0, thickness), trunk, false, tree)
	box(Vector3(0, 3.8, 0), Vector3(2.8, 2.4, 2.8), leaves, false, tree)
	return tree
