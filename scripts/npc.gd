extends CharacterBody3D
## Non-hostile NPC: doctor, nurse, patient or therapist.
## Walks back and forth between waypoints, or stands / sits / lies still.
## Interact (E) to hear a line. Placeholder boxes (with faces, breathing, blinking, looking
## at the player, talking) unless assets/characters/<role>.glb exists
## (then its AnimationPlayer is driven with "idle" / "walk" / "sit").

const Psx := preload("res://scripts/psx.gd")
const Tex := preload("res://scripts/textures.gd")
const Dialogues := preload("res://scripts/dialogues.gd")

const OUTFITS := {
	"doctor": {"top": Color(0.92, 0.92, 0.9), "legs": Color(0.25, 0.27, 0.32), "long_coat": true},
	"nurse": {"top": Color(0.45, 0.62, 0.72), "legs": Color(0.45, 0.62, 0.72), "long_coat": false},
	"patient": {"top": Color(0.62, 0.72, 0.64), "legs": Color(0.55, 0.57, 0.6), "long_coat": true},
	"therapist": {"top": Color(0.48, 0.36, 0.28), "legs": Color(0.22, 0.22, 0.26), "long_coat": false},
}
const SKIN_TONES := [Color(0.85, 0.68, 0.55), Color(0.62, 0.45, 0.33), Color(0.42, 0.3, 0.22), Color(0.9, 0.75, 0.62)]
const HAIR_COLORS := [Color(0.08, 0.06, 0.05), Color(0.3, 0.2, 0.12), Color(0.55, 0.42, 0.25), Color(0.6, 0.58, 0.55), Color(0.15, 0.1, 0.08)]

var role := "patient"
var display_name := ""            # shown before their line, defaults to the role
var pose := "stand"               # "stand", "sit" or "lie"
var waypoints: Array[Vector3] = []   # world positions; empty = stays put
var lines: Array[String] = ["..."]
var hint_lines: Array[String] = []   # "welcome back" lines: mixed in from Config.HINT_LINES_FROM_DAY
var facing := 0.0                 # yaw in radians when standing still
var prompt := "Talk"
var dialogue_id := ""            # "doctor", "nurse" or "group": a real conversation (scripts/dialogues.gd)

var _index := 0
var _step := 1
var _wait := 0.0
var _line := 0
var _phase := 0.0
var _visual: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _anim: AnimationPlayer
var _torso: MeshInstance3D
var _head: Node3D
var _head_y := 0.0
var _eyes: Array[MeshInstance3D] = []
var _mouth: MeshInstance3D
var _arm_l: Node3D
var _arm_r: Node3D
var _seed := 0.0
var _time := 0.0
var _blink := 3.0
var _talk := 0.0
var _look_change := 0.0
var _idle_look := Vector2.ZERO


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1 | 2
	rotation.y = facing
	if display_name == "":
		display_name = role.capitalize()

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.75
	cs.shape = cap
	cs.position.y = 0.875
	if pose == "lie":
		cs.rotation.x = PI * 0.5
		cs.position = Vector3(0, 0.75, 0)
	add_child(cs)

	if pose != "stand":
		waypoints.clear()

	var path: String = Config.NPC_MODEL_DIR + role + ".glb"
	if ResourceLoader.exists(path):
		_load_model(path)
	else:
		_build_placeholder()


func interact() -> void:
	if dialogue_id != "":
		_face_player()
		_talk = 1.5
		_wait = maxf(_wait, 2.0)
		await Dialogues.run(dialogue_id)
		return
	var pool := lines.duplicate()
	if Recovery.day() >= Config.HINT_LINES_FROM_DAY:
		pool.append_array(hint_lines)
	var line: String = pool[_line % pool.size()]
	_line += 1
	_talk = 2.5
	Withdrawal.post_message("%s: \"%s\"" % [display_name, line])
	_wait = maxf(_wait, 2.0)  # stop for a moment when spoken to
	_face_player()


func _face_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null and pose == "stand":
		var to := player.global_position - global_position
		rotation.y = atan2(-to.x, -to.z)


func _physics_process(delta: float) -> void:
	var moving := false
	if not waypoints.is_empty():
		if _wait > 0.0:
			_wait -= delta
		else:
			var to := waypoints[_index] - global_position
			to.y = 0.0
			if to.length() < 0.15:
				_wait = Config.NPC_WAIT_TIME
				if waypoints.size() > 1:
					if _index + _step < 0 or _index + _step >= waypoints.size():
						_step = -_step
					_index += _step
			else:
				var dir := to.normalized()
				velocity = dir * Config.NPC_WALK_SPEED
				move_and_slide()
				rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(delta * 6.0, 0.0, 1.0))
				moving = true
	_animate(delta, moving)


func _animate(delta: float, moving: bool) -> void:
	if _anim != null:
		var wanted := "walk" if moving else ("sit" if pose == "sit" else "idle")
		if _anim.has_animation(wanted) and _anim.current_animation != wanted:
			_anim.play(wanted, 0.2)
		return
	if _head != null:
		_animate_placeholder(delta, moving)


# ------------------------------------------------------------------ Visuals

## Boxes, but with a face: eyes (that blink), brows, nose, mouth (that moves when they talk),
## a hairstyle, maybe glasses or a beard. Arms and legs swing on pivots.
func _build_placeholder() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(display_name + role + str(position.snapped(Vector3.ONE)))
	_seed = rng.randf() * TAU
	var outfit: Dictionary = OUTFITS.get(role, OUTFITS["patient"])
	var skin_color: Color = SKIN_TONES[rng.randi() % SKIN_TONES.size()]
	var hair_color: Color = HAIR_COLORS[rng.randi() % HAIR_COLORS.size()]
	var skin := Psx.material(Tex.get_texture("plain"), skin_color, 1.0, false)
	var skin_dark := Psx.material(Tex.get_texture("plain"), skin_color * 0.8, 1.0, false)
	var top := Psx.material(Tex.get_texture("fabric"), outfit["top"] * 2.6, 2.0, false)
	var legs := Psx.material(Tex.get_texture("fabric"), outfit["legs"] * 2.6, 2.0, false)
	var hair := Psx.material(Tex.get_texture("plain"), hair_color, 1.0, false)
	var shoes := Psx.material(Tex.get_texture("plain"), Color(0.12, 0.12, 0.12), 1.0, false)
	var dark := Psx.material(Tex.get_texture("plain"), Color(0.05, 0.05, 0.06), 1.0, false)
	var lips := Psx.material(Tex.get_texture("plain"), skin_color * Color(0.75, 0.5, 0.5), 1.0, false)

	_visual = Node3D.new()
	add_child(_visual)
	var sitting := pose == "sit"
	var hip_y := 0.47 if sitting else 0.88

	_torso = _part(_visual, Vector3(0, hip_y + 0.34, 0), Vector3(0.42, 0.62, 0.24), top)
	if outfit["long_coat"] and not sitting:
		_part(_visual, Vector3(0, hip_y - 0.15, 0), Vector3(0.44, 0.35, 0.26), top)     # coat / gown skirt
	_part(_visual, Vector3(0, hip_y + 0.66, 0), Vector3(0.1, 0.06, 0.1), skin)          # neck

	# Head on a pivot at the neck, so it can look around.
	_head = Node3D.new()
	_head.position = Vector3(0, hip_y + 0.68, 0)
	_head_y = _head.position.y
	_visual.add_child(_head)
	_part(_head, Vector3(0, 0.13, 0), Vector3(0.22, 0.26, 0.24), skin)
	for side in [-1.0, 1.0]:
		_eyes.append(_part(_head, Vector3(side * 0.05, 0.15, -0.121), Vector3(0.035, 0.025, 0.01), dark))
		_part(_head, Vector3(side * 0.05, 0.18, -0.121), Vector3(0.05, 0.012, 0.01), hair)   # brow
		_part(_head, Vector3(side * 0.112, 0.13, 0), Vector3(0.02, 0.05, 0.04), skin_dark)     # ear
	_part(_head, Vector3(0, 0.115, -0.13), Vector3(0.03, 0.045, 0.02), skin_dark)              # nose
	_mouth = _part(_head, Vector3(0, 0.065, -0.121), Vector3(0.07, 0.012, 0.01), lips)
	match rng.randi() % 4:
		0:   # short
			_part(_head, Vector3(0, 0.27, 0.02), Vector3(0.24, 0.06, 0.26), hair)
			_part(_head, Vector3(0, 0.19, 0.11), Vector3(0.24, 0.14, 0.04), hair)
		1:   # long
			_part(_head, Vector3(0, 0.27, 0.02), Vector3(0.24, 0.07, 0.26), hair)
			_part(_head, Vector3(0, 0.08, 0.11), Vector3(0.25, 0.34, 0.05), hair)
			for side in [-1.0, 1.0]:
				_part(_head, Vector3(side * 0.12, 0.12, 0.03), Vector3(0.03, 0.24, 0.18), hair)
		2:   # very short / balding
			_part(_head, Vector3(0, 0.2, 0.08), Vector3(0.23, 0.1, 0.1), hair)
		3:   # bun
			_part(_head, Vector3(0, 0.27, 0.02), Vector3(0.24, 0.06, 0.26), hair)
			_part(_head, Vector3(0, 0.28, 0.13), Vector3(0.1, 0.1, 0.08), hair)
	if role == "doctor" or rng.randf() < 0.2:   # glasses
		for side in [-1.0, 1.0]:
			_part(_head, Vector3(side * 0.05, 0.15, -0.128), Vector3(0.06, 0.008, 0.008), dark)
			_part(_head, Vector3(side * 0.05, 0.13, -0.128), Vector3(0.06, 0.008, 0.008), dark)
		_part(_head, Vector3(0, 0.15, -0.128), Vector3(0.03, 0.006, 0.006), dark)
	if role == "patient" and rng.randf() < 0.35:   # stubble or beard
		_part(_head, Vector3(0, 0.04, -0.105), Vector3(0.2, 0.08, 0.04), hair)

	# Arms on shoulder pivots
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.27, hip_y + 0.6, 0)
		_visual.add_child(arm)
		_part(arm, Vector3(0, -0.3, 0), Vector3(0.1, 0.6, 0.12), top)
		_part(arm, Vector3(0, -0.64, 0), Vector3(0.08, 0.1, 0.1), skin)
		if side < 0.0:
			_arm_l = arm
		else:
			_arm_r = arm
	if sitting:   # hands resting in the lap
		_arm_l.rotation.x = 0.7
		_arm_r.rotation.x = 0.7

	if sitting:
		for side in [-1.0, 1.0]:
			_part(_visual, Vector3(side * 0.1, hip_y, -0.22), Vector3(0.15, 0.15, 0.45), legs)   # thigh
			_part(_visual, Vector3(side * 0.1, hip_y * 0.5, -0.42), Vector3(0.14, hip_y, 0.15), legs)  # shin
			_part(_visual, Vector3(side * 0.1, 0.04, -0.48), Vector3(0.13, 0.08, 0.25), shoes)
	else:
		_leg_l = _leg(Vector3(-0.1, hip_y, 0), legs, shoes)
		_leg_r = _leg(Vector3(0.1, hip_y, 0), legs, shoes)

	if pose == "lie":
		# Lying on a bed, face up, head toward local +Z, centred on the node.
		_visual.rotation.x = PI * 0.5
		_visual.position = Vector3(0, 0.72, -0.85)


## Breathing, blinking, glancing around, watching the player, talking, walking.
func _animate_placeholder(delta: float, moving: bool) -> void:
	_time += delta
	# Breathing
	_torso.scale.y = 1.0 + sin(_time * 1.6 + _seed) * 0.02
	_head.position.y = _head_y + sin(_time * 1.6 + _seed) * 0.004

	# Blinking
	_blink -= delta
	if _blink <= 0.0:
		_blink = randf_range(2.0, 5.0)
	var closed := _blink < 0.12
	for e in _eyes:
		e.scale.y = 0.15 if closed else 1.0

	# Where to look: at the player when he's close and in front, otherwise around the room.
	var look := Vector2(_idle_look)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null and pose != "lie":
		var to := player.global_position - global_position
		var local := global_transform.basis.inverse() * to
		var dist := Vector2(to.x, to.z).length()
		if dist < Config.NPC_LOOK_DISTANCE and local.z < 0.5:
			look = Vector2(clampf(atan2(-local.x, -local.z), -1.1, 1.1), clampf(atan2(to.y + 0.2, dist) * 0.5, -0.4, 0.3))
	_look_change -= delta
	if _look_change <= 0.0:
		_look_change = randf_range(2.5, 6.0)
		_idle_look = Vector2(randf_range(-0.6, 0.6), randf_range(-0.15, 0.1))
	_head.rotation.y = lerp_angle(_head.rotation.y, look.x, clampf(delta * 4.0, 0.0, 1.0))
	_head.rotation.x = lerpf(_head.rotation.x, -look.y, clampf(delta * 4.0, 0.0, 1.0))

	# Talking: mouth moves, one hand gestures.
	_talk = maxf(0.0, _talk - delta)
	_mouth.scale.y = 1.0 + (absf(sin(_time * 14.0)) * 3.0 if _talk > 0.0 else 0.0)

	if pose == "sit":
		_arm_r.rotation.x = 0.7 + (sin(_time * 3.0) * 0.4 - 0.5 if _talk > 0.0 else 0.0)
		return
	if pose == "lie":
		return

	# Walking: legs and arms swing; standing: a slow shift of weight.
	if moving:
		_phase += delta * 7.0
	else:
		_phase = lerpf(_phase, roundf(_phase / PI) * PI, clampf(delta * 5.0, 0.0, 1.0))
	var swing := sin(_phase) * 0.45
	_leg_l.rotation.x = swing
	_leg_r.rotation.x = -swing
	_arm_l.rotation.x = -swing * 0.7
	_arm_r.rotation.x = swing * 0.7 + (-0.9 + sin(_time * 3.0) * 0.3 if _talk > 0.0 and not moving else 0.0)
	_visual.rotation.z = 0.0 if moving else sin(_time * 0.5 + _seed) * 0.015


func _leg(hip: Vector3, legs: Material, shoes: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = hip
	_visual.add_child(pivot)
	_part(pivot, Vector3(0, -hip.y * 0.5, 0), Vector3(0.15, hip.y, 0.16), legs)
	_part(pivot, Vector3(0, -hip.y + 0.04, -0.06), Vector3(0.14, 0.08, 0.27), shoes)
	return pivot


func _part(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi


func _load_model(path: String) -> void:
	var scene := load(path) as PackedScene
	if scene == null:
		_build_placeholder()
		return
	_visual = scene.instantiate() as Node3D
	_visual.rotation.y = PI  # Mixamo faces +Z, Godot forward is -Z
	add_child(_visual)
	var players := _visual.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0]
