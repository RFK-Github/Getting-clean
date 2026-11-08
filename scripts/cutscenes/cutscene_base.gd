extends "res://scripts/levels/level_base.gd"
## Base for in-engine cutscenes. A cutscene builds its set in build(), sets `cam`,
## schedules things with at(time, callable) and animates in animate(delta).
## It ends after `duration` seconds (or when skipped) by emitting `finished`.
## get_settings() gives the environment and post look, like a level.

signal finished

var duration := 10.0
var t := 0.0
var cam: Camera3D

# Set by cutscene_player.gd before build()
var subtitle_label: Label
var fade_rect: ColorRect
var post_material: ShaderMaterial
var world_env: WorldEnvironment   # change fog/light mid-scene if needed

var _events: Array = []        # [time, callable, done]
var _subtitle_left := 0.0
var _done := false
var _sounds: Array[AudioStreamPlayer] = []


## Run `f` once when the timeline reaches `time` seconds.
func at(time: float, f: Callable) -> void:
	_events.append([time, f, false])


## Show a subtitle line for `seconds`.
func say(text: String, seconds := 3.0) -> void:
	subtitle_label.text = text
	_subtitle_left = seconds


## Tween the fade overlay (eyes closing, flashes, cut to black).
func fade(color: Color, seconds: float) -> void:
	if seconds <= 0.0:
		fade_rect.color = color
		return
	create_tween().tween_property(fade_rect, "color", color, seconds)


func sound(stream: AudioStream, db: float, bus := "Master", loop_play := true) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	p.bus = bus
	add_child(p)
	if loop_play:
		p.play()
	_sounds.append(p)
	return p


func stop_all_sounds() -> void:
	for p in _sounds:
		p.stop()


func skip() -> void:
	t = duration


## Override: per-frame animation. `t` is the time since the start.
func animate(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	if _done:
		return
	t += delta
	for e in _events:
		if not e[2] and t >= e[0]:
			e[2] = true
			e[1].call()
	animate(delta)
	if _subtitle_left > 0.0:
		_subtitle_left -= delta
		if _subtitle_left <= 0.0:
			subtitle_label.text = ""
	if t >= duration:
		_done = true
		subtitle_label.text = ""
		stop_all_sounds()
		finished.emit()


## Camera looking from `from` toward `target`, blended from `a` to `b` by w (0..1).
func look_blend(from: Vector3, a: Vector3, b: Vector3, w: float) -> void:
	var qa := Basis.looking_at(a - from).get_rotation_quaternion()
	var qb := Basis.looking_at(b - from).get_rotation_quaternion()
	cam.global_transform = Transform3D(Basis(qa.slerp(qb, clampf(w, 0.0, 1.0))), from)


## A placeholder person made of boxes. Parts can be animated by name:
## "torso", "head", "arm_l", "arm_r" (pivots at the shoulders), "leg_l", "leg_r" (pivots at the hips).
## Faces -Z. scale_by: 1 = adult, ~0.6 = child.
func figure(top: Color, legs: Color, skin: Color, hair: Color, sitting := false, scale_by := 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * scale_by
	var m_top := mat("fabric", top * 2.6, 2.0, false)
	var m_legs := mat("fabric", legs * 2.6, 2.0, false)
	var m_skin := mat("plain", skin, 1.0, false)
	var m_hair := mat("plain", hair, 1.0, false)
	var hip := 0.47 if sitting else 0.88
	var torso := box(Vector3(0, hip + 0.34, 0), Vector3(0.42, 0.62, 0.24), m_top, false, root)
	torso.name = "torso"
	var head := Node3D.new()
	head.name = "head"
	head.position = Vector3(0, hip + 0.68, 0)
	root.add_child(head)
	box(Vector3(0, 0.12, 0), Vector3(0.22, 0.26, 0.24), m_skin, false, head)
	box(Vector3(0, 0.27, 0.02), Vector3(0.24, 0.07, 0.26), m_hair, false, head)
	box(Vector3(0, 0.12, 0.1), Vector3(0.24, 0.24, 0.06), m_hair, false, head)   # hair at the back
	var m_face := mat("plain", Color(0.06, 0.05, 0.05), 1.0, false)
	for side in [-1.0, 1.0]:
		box(Vector3(side * 0.05, 0.14, -0.121), Vector3(0.035, 0.025, 0.01), m_face, false, head)   # eyes
	box(Vector3(0, 0.06, -0.121), Vector3(0.07, 0.012, 0.01), mat("plain", skin * Color(0.75, 0.5, 0.5), 1.0, false), false, head)   # mouth
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.name = "arm_l" if side < 0.0 else "arm_r"
		arm.position = Vector3(side * 0.27, hip + 0.6, 0)
		root.add_child(arm)
		box(Vector3(0, -0.3, 0), Vector3(0.1, 0.6, 0.12), m_top, false, arm)
		box(Vector3(0, -0.64, 0), Vector3(0.08, 0.1, 0.1), m_skin, false, arm)
		var leg := Node3D.new()
		leg.name = "leg_l" if side < 0.0 else "leg_r"
		leg.position = Vector3(side * 0.1, hip, 0)
		root.add_child(leg)
		if sitting:
			box(Vector3(0, 0, -0.22), Vector3(0.15, 0.15, 0.45), m_legs, false, leg)
			box(Vector3(0, -hip * 0.5, -0.42), Vector3(0.14, hip, 0.15), m_legs, false, leg)
		else:
			box(Vector3(0, -hip * 0.5, 0), Vector3(0.15, hip, 0.16), m_legs, false, leg)
	return root


## Walk-cycle helper for a standing figure: swing legs/arms by phase.
func walk_pose(fig: Node3D, phase: float, amount := 1.0) -> void:
	var s := sin(phase) * 0.45 * amount
	fig.get_node("leg_l").rotation.x = s
	fig.get_node("leg_r").rotation.x = -s
	fig.get_node("arm_l").rotation.x = -s * 0.6
	fig.get_node("arm_r").rotation.x = s * 0.6


## The cemetery with the daughter's stone (front face toward +Z at origin + (0, 0.6, -1.6)),
## other graves, bare trees, the teddy bear and flowers. Used by flashback 3 and the good ending.
func grave_set(origin: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = origin
	add_child(root)
	var grass := mat("grass", Color(0.85, 0.95, 0.85), 0.5)
	var stone := mat("concrete", Color(0.75, 0.76, 0.78), 1.0)
	box(Vector3(0, -0.05, -10), Vector3(60, 0.1, 50), grass, false, root, 3.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for row in 4:
		for col in 7:
			var x := -9.0 + col * 3.0 + rng.randf_range(-0.4, 0.4)
			var z := -5.0 - row * 3.5
			if absf(x) < 1.5 and row == 0:
				continue
			var g := box(Vector3(x, 0.4, z), Vector3(0.6, 0.8, 0.15), stone, false, root)
			g.rotation.z = rng.randf_range(-0.06, 0.06)
	var bark := mat("wood", Color(0.6, 0.6, 0.6), 1.0)
	for p in [Vector3(-7, 0, -3), Vector3(8, 0, -9), Vector3(-12, 0, -16)]:
		box(p + Vector3(0, 2.5, 0), Vector3(0.3, 5.0, 0.3), bark, false, root)
		var branch := box(p + Vector3(0.6, 4.0, 0), Vector3(0.12, 1.8, 0.12), bark, false, root)
		branch.rotation.z = -0.7
	# Her stone: a dark granite headstone with an arched top on a plinth set into the
	# ground, and a kerbed grave plot with gravel in front of it.
	var granite := mat("concrete", Color(0.42, 0.43, 0.46), 1.0)
	var plinth := mat("concrete", Color(0.62, 0.62, 0.6), 1.0)
	box(Vector3(0, 0.08, -1.72), Vector3(1.2, 0.2, 0.42), plinth, false, root)          # plinth, sunk 2 cm
	box(Vector3(0, 0.6, -1.74), Vector3(0.9, 0.84, 0.14), granite, false, root)         # the upright slab
	var arch := cylinder(Vector3(0, 1.02, -1.74), 0.45, 0.14, granite, root)            # arched top
	arch.rotation.x = PI / 2
	arch.scale = Vector3(1, 1, 0.45)
	(arch.mesh as CylinderMesh).radial_segments = 16
	# Kerbs and gravel: the plot in front of the stone
	box(Vector3(0, 0.03, -0.92), Vector3(0.9, 0.06, 1.2), mat("concrete", Color(0.55, 0.5, 0.45), 0.25), false, root)
	for sx in [-0.5, 0.5]:
		box(Vector3(sx, 0.06, -0.97), Vector3(0.1, 0.12, 1.3), plinth, false, root)
	box(Vector3(0, 0.06, -0.27), Vector3(1.1, 0.12, 0.1), plinth, false, root)
	# Engraved letters, small enough to sit inside the stone's face
	var face_z := -1.74 + 0.082
	var ink := Color(0.86, 0.84, 0.78)
	var born: int = Config.YEAR_HE_THINKS - 7
	sign_text("BELOVED DAUGHTER", Vector3(0, 1.0, face_z), 0, 12, ink, root)
	sign_text("%d - %d" % [born, Config.YEAR_HE_THINKS], Vector3(0, 0.87, face_z), 0, 10, ink, root)
	sign_text("Forever seven years old", Vector3(0, 0.7, face_z), 0, 9, ink, root)
	sign_text("We will always\nhold your hand", Vector3(0, 0.52, face_z), 0, 8, ink, root)
	# The teddy bear sitting against the plinth, and flowers lying on the gravel
	var fur := mat("fabric", Color(1.4, 1.0, 0.65), 3.0, false)
	var bear := Node3D.new()
	bear.position = Vector3(-0.25, 0.06, -1.38)
	bear.rotation.y = 0.3
	root.add_child(bear)
	box(Vector3(0, 0.1, 0), Vector3(0.17, 0.2, 0.13), fur, false, bear)
	box(Vector3(0, 0.26, 0), Vector3(0.14, 0.13, 0.12), fur, false, bear)
	for sx in [-0.06, 0.06]:
		box(Vector3(sx, 0.34, 0), Vector3(0.04, 0.04, 0.03), fur, false, bear)
	var stems := mat("plain", Color(0.25, 0.45, 0.2), 1.0, false)
	for i in 5:
		var c: Color = [Color(0.85, 0.85, 0.8), Color(0.9, 0.6, 0.65), Color(0.9, 0.85, 0.4)][i % 3]
		var stem := box(Vector3(0.18 + i * 0.05, 0.075, -1.2 + (i % 2) * 0.04), Vector3(0.012, 0.012, 0.3), stems, false, root)
		stem.rotation.y = 0.25
		box(Vector3(0.14 + i * 0.05, 0.09, -1.36 + (i % 2) * 0.04), Vector3(0.05, 0.04, 0.05), mat("plain", c, 1.0, false), false, root)
	return root


## The visiting room at `origin`: a small room with a table in the middle (top at y 0.77),
## two chairs (one at z -0.8 facing +Z, one at z +0.8 facing -Z), a bright window on the
## right wall and a doorway in the +Z wall. Used by both final cutscenes.
func visiting_room(origin: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = origin
	add_child(root)
	var floor_mat := mat("linoleum", Color.WHITE, 0.5)
	var wall := mat("white_wall", Color.WHITE, 0.5)
	var wood := mat("wood", Color(1.2, 1.15, 1.1), 1.0)
	var dark := mat("metal", Color(0.35, 0.35, 0.35), 1.0)
	box(Vector3(0, -0.05, 0), Vector3(6, 0.1, 6), floor_mat, false, root, 1.5)
	box(Vector3(0, 3.05, 0), Vector3(6, 0.1, 6), mat("ceiling", Color(1.3, 1.3, 1.3), 0.5), false, root, 1.5)
	box(Vector3(0, 1.5, -3), Vector3(6, 3, 0.2), wall, false, root, 1.5)
	box(Vector3(-3, 1.5, 0), Vector3(0.2, 3, 6), wall, false, root, 1.5)
	box(Vector3(3, 1.5, 0), Vector3(0.2, 3, 6), wall, false, root, 1.5)
	box(Vector3(-1.9, 1.5, 3), Vector3(2.2, 3, 0.2), wall, false, root, 1.5)   # +Z wall, doorway in the middle
	box(Vector3(1.9, 1.5, 3), Vector3(2.2, 3, 0.2), wall, false, root, 1.5)
	box(Vector3(0, 2.6, 3), Vector3(1.6, 0.8, 0.2), wall, false, root, 1.5)
	box(Vector3(2.88, 1.6, -0.5), Vector3(0.04, 1.3, 2.2), mat("plain", Color(0.95, 0.95, 0.9), 1.0, true, Color(0.85, 0.85, 0.8)), false, root)
	sign_text("VISITING ROOM", Vector3(0, 2.6, 3.11), 0, 20, Color(0.2, 0.25, 0.35), root)
	box(Vector3(0, 0.74, 0), Vector3(1.2, 0.06, 0.9), wood, false, root)
	box(Vector3(0, 0.36, 0), Vector3(0.12, 0.72, 0.12), dark, false, root)
	for z in [-0.8, 0.8]:
		box(Vector3(0, 0.45, z), Vector3(0.45, 0.06, 0.45), wood, false, root)
		box(Vector3(0, 0.75, z + signf(z) * 0.21), Vector3(0.45, 0.55, 0.05), wood, false, root)
	cylinder(Vector3(-0.3, 0.82, -0.15), 0.04, 0.1, mat("plain", Color(0.9, 0.9, 0.88), 1.0, false), root)  # paper cup
	var l := OmniLight3D.new()
	l.position = Vector3(0, 2.6, 0)
	l.light_color = Config.LAMP_COLOR
	l.light_energy = 1.0
	l.omni_range = 8
	root.add_child(l)
	return root


## Falling rain streaks over an area around `center`.
func rain(center: Vector3, extents: Vector3, amount := 500) -> void:
	var p := CPUParticles3D.new()
	p.position = center
	p.amount = amount
	p.lifetime = 0.9
	p.preprocess = 1.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = Vector3.DOWN
	p.spread = 3.0
	p.initial_velocity_min = 11.0
	p.initial_velocity_max = 13.0
	p.gravity = Vector3.ZERO
	var streak := BoxMesh.new()
	streak.size = Vector3(0.01, 0.35, 0.01)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.75, 0.8, 0.85, 0.35)
	streak.material = m
	p.mesh = streak
	add_child(p)
