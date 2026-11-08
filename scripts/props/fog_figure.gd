extends Node3D
## A still figure standing in the fog. It turns to face the player, and when the player
## comes within Config.FIGURE_VANISH_DISTANCE it flickers and is gone. One-shot hallucination.

const Psx := preload("res://scripts/psx.gd")
const Tex := preload("res://scripts/textures.gd")
const Audio := preload("res://scripts/audio.gd")

var _body: Node3D
var _sting: AudioStreamPlayer3D
var _vanish_time := -1.0


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var dark := Psx.material(Tex.get_texture("fabric"), Color(0.12, 0.1, 0.09), 2.0, false)
	_part(Vector3(0, 1.15, 0), Vector3(0.46, 0.8, 0.26), dark)           # coat
	_part(Vector3(0, 0.62, 0), Vector3(0.5, 0.3, 0.28), dark)            # coat hem
	_part(Vector3(0, 1.72, 0), Vector3(0.24, 0.3, 0.26), dark)           # head
	_part(Vector3(-0.29, 1.08, 0), Vector3(0.1, 0.75, 0.12), dark)       # arms hanging
	_part(Vector3(0.29, 1.08, 0), Vector3(0.1, 0.75, 0.12), dark)
	_part(Vector3(-0.1, 0.24, 0), Vector3(0.13, 0.48, 0.14), dark)       # legs
	_part(Vector3(0.1, 0.24, 0), Vector3(0.13, 0.48, 0.14), dark)

	_sting = AudioStreamPlayer3D.new()
	_sting.stream = Audio.sting()
	_sting.bus = Settings.LOUD_BUS
	_sting.volume_db = Config.STING_DB
	_sting.unit_size = 20.0
	_sting.position.y = 1.5
	add_child(_sting)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	if _vanish_time < 0.0:
		var to := player.global_position - global_position
		to.y = 0.0
		if to.length() > 0.1:
			rotation.y = atan2(-to.x, -to.z)  # front (-Z) faces the player
		if to.length() < Config.FIGURE_VANISH_DISTANCE:
			_vanish_time = 0.0
			_sting.play()
	else:
		_vanish_time += delta
		_body.visible = _vanish_time < 0.4 and randf() > 0.5
		if _vanish_time > 2.0:
			queue_free()


func _part(pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	_body.add_child(mi)
