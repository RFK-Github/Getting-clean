extends CharacterBody3D
## Non-hostile NPC: doctor, nurse, patient or therapist.
## Walks back and forth between waypoints, or stands / sits / lies still.
## Interact (E) to hear a line. Placeholder boxes unless assets/characters/<role>.glb exists
## (then its AnimationPlayer is driven with "idle" / "walk" / "sit").

const Psx := preload("res://scripts/psx.gd")
const Tex := preload("res://scripts/textures.gd")

const OUTFITS := {
	"doctor": {"top": Color(0.92, 0.92, 0.9), "legs": Color(0.25, 0.27, 0.32), "long_coat": true},
	"nurse": {"top": Color(0.45, 0.62, 0.72), "legs": Color(0.45, 0.62, 0.72), "long_coat": false},
	"patient": {"top": Color(0.62, 0.72, 0.64), "legs": Color(0.55, 0.57, 0.6), "long_coat": true},
	"therapist": {"top": Color(0.48, 0.36, 0.28), "legs": Color(0.22, 0.22, 0.26), "long_coat": false},
}
const SKIN_TONES := [Color(0.85, 0.68, 0.55), Color(0.62, 0.45, 0.33), Color(0.42, 0.3, 0.22), Color(0.9, 0.75, 0.62)]

var role := "patient"
var display_name := ""            # shown before their line, defaults to the role
var pose := "stand"               # "stand", "sit" or "lie"
var waypoints: Array[Vector3] = []   # world positions; empty = stays put
var lines: Array[String] = ["..."]
var facing := 0.0                 # yaw in radians when standing still
var prompt := "Talk"

var _index := 0
var _step := 1
var _wait := 0.0
var _line := 0
var _phase := 0.0
var _visual: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _anim: AnimationPlayer


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
	var line: String = lines[_line % lines.size()]
	_line += 1
	Withdrawal.post_message("%s: \"%s\"" % [display_name, line])
	_wait = maxf(_wait, 2.0)  # stop for a moment when spoken to
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
	if _leg_l == null or pose != "stand":
		return
	if moving:
		_phase += delta * 7.0
	else:
		_phase = lerpf(_phase, roundf(_phase / PI) * PI, clampf(delta * 5.0, 0.0, 1.0))
	_leg_l.rotation.x = sin(_phase) * 0.45
	_leg_r.rotation.x = -sin(_phase) * 0.45


# ------------------------------------------------------------------ Visuals

func _build_placeholder() -> void:
	var outfit: Dictionary = OUTFITS.get(role, OUTFITS["patient"])
	var skin_color: Color = SKIN_TONES[absi(hash(name + role)) % SKIN_TONES.size()]
	var skin := Psx.material(Tex.get_texture("plain"), skin_color, 1.0, false)
	var top := Psx.material(Tex.get_texture("fabric"), outfit["top"] * 2.6, 2.0, false)
	var legs := Psx.material(Tex.get_texture("fabric"), outfit["legs"] * 2.6, 2.0, false)
	var hair := Psx.material(Tex.get_texture("plain"), Color(0.15, 0.12, 0.1), 1.0, false)
	var shoes := Psx.material(Tex.get_texture("plain"), Color(0.12, 0.12, 0.12), 1.0, false)

	_visual = Node3D.new()
	add_child(_visual)
	var sitting := pose == "sit"
	var hip_y := 0.47 if sitting else 0.88

	_part(_visual, Vector3(0, hip_y + 0.34, 0), Vector3(0.42, 0.62, 0.24), top)          # torso
	if outfit["long_coat"] and not sitting:
		_part(_visual, Vector3(0, hip_y - 0.15, 0), Vector3(0.44, 0.35, 0.26), top)     # coat / gown skirt
	_part(_visual, Vector3(0, hip_y + 0.8, 0), Vector3(0.22, 0.26, 0.24), skin)          # head
	_part(_visual, Vector3(0, hip_y + 0.95, 0.02), Vector3(0.24, 0.07, 0.26), hair)
	for side in [-1.0, 1.0]:
		_part(_visual, Vector3(side * 0.27, hip_y + 0.3, 0), Vector3(0.1, 0.6, 0.12), top)  # arm
		_part(_visual, Vector3(side * 0.27, hip_y - 0.04, 0), Vector3(0.08, 0.1, 0.1), skin)  # hand

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


func _leg(hip: Vector3, legs: Material, shoes: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = hip
	_visual.add_child(pivot)
	_part(pivot, Vector3(0, -hip.y * 0.5, 0), Vector3(0.15, hip.y, 0.16), legs)
	_part(pivot, Vector3(0, -hip.y + 0.04, -0.06), Vector3(0.14, 0.08, 0.27), shoes)
	return pivot


func _part(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)


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
