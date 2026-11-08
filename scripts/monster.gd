extends CharacterBody3D
## Simple hallucination monster: a tall, dark figure that chases the player.

signal caught

const Psx := preload("res://scripts/psx.gd")
const Tex := preload("res://scripts/textures.gd")

var target: Node3D
var speed := 2.0

var _agent: NavigationAgent3D
var _body: Node3D
var _t := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1  # walks through the player; catching is measured by distance

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.9
	cs.shape = cap
	cs.position.y = 0.95
	add_child(cs)

	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.5
	_agent.target_desired_distance = 0.3
	_agent.radius = 0.35
	_agent.height = 1.9
	add_child(_agent)

	_body = Node3D.new()
	add_child(_body)
	var skin := Psx.material(Tex.get_texture("wall"), Color(0.07, 0.07, 0.05), 2.0)
	var eye := Psx.material(Tex.get_texture("plain"), Color(1, 1, 0.8), 1.0, true, Color(1.0, 0.95, 0.7))
	_part(_body, Vector3(0, 1.15, 0), Vector3(0.42, 1.1, 0.22), skin)
	var head := _part(_body, Vector3(0, 1.95, -0.04), Vector3(0.28, 0.36, 0.28), skin, Vector3(0, 0, 14))
	_part(head, Vector3(-0.07, 0.03, -0.145), Vector3(0.05, 0.03, 0.02), eye)
	_part(head, Vector3(0.07, 0.03, -0.145), Vector3(0.05, 0.03, 0.02), eye)
	_part(_body, Vector3(-0.32, 1.0, -0.12), Vector3(0.08, 1.4, 0.08), skin, Vector3(-20, 0, 6))
	_part(_body, Vector3(0.32, 1.0, -0.12), Vector3(0.08, 1.4, 0.08), skin, Vector3(-20, 0, -6))
	_part(_body, Vector3(-0.11, 0.3, 0), Vector3(0.11, 0.6, 0.11), skin)
	_part(_body, Vector3(0.11, 0.3, 0), Vector3(0.11, 0.6, 0.11), skin)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	_t += delta
	_agent.target_position = target.global_position
	var dir := _agent.get_next_path_position() - global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		dir = target.global_position - global_position
		dir.y = 0.0
	dir = dir.normalized()
	velocity = dir * speed
	move_and_slide()
	global_position.y = 0.02

	if dir.length_squared() > 0.001:
		look_at(global_position + dir, Vector3.UP)
	# Jerky, restless movement
	_body.position = Vector3(randf_range(-0.03, 0.03), absf(sin(_t * 11.0)) * 0.05, 0)

	var flat := target.global_position - global_position
	flat.y = 0.0
	if flat.length() < Config.MONSTER_CATCH_DISTANCE:
		caught.emit()


func _part(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi
