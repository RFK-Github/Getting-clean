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
