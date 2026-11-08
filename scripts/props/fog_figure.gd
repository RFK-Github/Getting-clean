extends Node3D
## A still figure that faces the player and flickers away when he comes close. One-shot.
## child = false: a tall dark figure in a coat (the street, the fog).
## child = true:  a small girl in a yellow dress - the daughter. She laughs when you come within
##                 earshot; a music box plays as she goes.

const Psx := preload("res://scripts/psx.gd")
const Tex := preload("res://scripts/textures.gd")
const Audio := preload("res://scripts/audio.gd")

var child := false
var vanish_distance: float = Config.FIGURE_VANISH_DISTANCE
var lifetime := -1.0          # > 0: she's gone after this many seconds even if never approached

var _body: Node3D
var _sound: AudioStreamPlayer3D
var _laugh: AudioStreamPlayer3D
var _laughed := false
var _vanish_time := -1.0
var _age := 0.0


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	if child:
		_build_girl()
	else:
		_build_figure()
	_sound = AudioStreamPlayer3D.new()
	if child:
		_sound.stream = Audio.music_box()
		_sound.volume_db = -6.0
		_sound.unit_size = 6.0
	else:
		_sound.stream = Audio.sting()
		_sound.bus = Settings.LOUD_BUS
		_sound.volume_db = Config.STING_DB
		_sound.unit_size = 20.0
	_sound.position.y = 1.0
	add_child(_sound)
	if child:
		# The same laughter as the daughter in the car.
		_laugh = AudioStreamPlayer3D.new()
		_laugh.stream = Audio.child_laugh()
		_laugh.volume_db = Config.GIRL_LAUGH_DB
		_laugh.unit_size = 8.0
		_laugh.position.y = 1.0
		add_child(_laugh)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	_age += delta
	if _vanish_time < 0.0:
		var to := player.global_position - global_position
		to.y = 0.0
		if to.length() > 0.1:
			rotation.y = atan2(-to.x, -to.z)  # front (-Z) faces the player
		if child and not _laughed and to.length() < Config.GIRL_LAUGH_DISTANCE:
			_laughed = true
			_laugh.play()
		if to.length() < vanish_distance or (lifetime > 0.0 and _age > lifetime):
			_vanish_time = 0.0
			if to.length() < vanish_distance:
				_sound.play()
	else:
		_vanish_time += delta
		_body.visible = _vanish_time < 0.4 and randf() > 0.5
		if _vanish_time > 4.0:
			queue_free()


func _build_figure() -> void:
	var dark := Psx.material(Tex.get_texture("fabric"), Color(0.12, 0.1, 0.09), 2.0, false)
	_part(Vector3(0, 1.15, 0), Vector3(0.46, 0.8, 0.26), dark)           # coat
	_part(Vector3(0, 0.62, 0), Vector3(0.5, 0.3, 0.28), dark)            # coat hem
	_part(Vector3(0, 1.72, 0), Vector3(0.24, 0.3, 0.26), dark)           # head
	_part(Vector3(-0.29, 1.08, 0), Vector3(0.1, 0.75, 0.12), dark)       # arms hanging
	_part(Vector3(0.29, 1.08, 0), Vector3(0.1, 0.75, 0.12), dark)
	_part(Vector3(-0.1, 0.24, 0), Vector3(0.13, 0.48, 0.14), dark)       # legs
	_part(Vector3(0.1, 0.24, 0), Vector3(0.13, 0.48, 0.14), dark)


## About 1.1 m tall. Yellow dress, dark hair in two bunches, white socks. Arms at her sides.
func _build_girl() -> void:
	var dress := Psx.material(Tex.get_texture("fabric"), Config.GIRL_DRESS_COLOR * 2.2, 3.0, false)
	var skin := Psx.material(Tex.get_texture("plain"), Color(0.86, 0.7, 0.6), 1.0, false)
	var hair := Psx.material(Tex.get_texture("plain"), Color(0.3, 0.2, 0.12), 1.0, false)
	var socks := Psx.material(Tex.get_texture("plain"), Color(0.9, 0.9, 0.88), 1.0, false)
	var eyes := Psx.material(Tex.get_texture("plain"), Color(0.05, 0.05, 0.05), 1.0, false)
	_part(Vector3(0, 0.72, 0), Vector3(0.28, 0.32, 0.18), dress)         # top of the dress
	_part(Vector3(0, 0.46, 0), Vector3(0.36, 0.22, 0.24), dress)         # skirt
	_part(Vector3(-0.07, 0.18, 0), Vector3(0.08, 0.34, 0.08), socks)     # legs
	_part(Vector3(0.07, 0.18, 0), Vector3(0.08, 0.34, 0.08), socks)
	_part(Vector3(-0.19, 0.66, 0), Vector3(0.06, 0.34, 0.07), skin)      # arms
	_part(Vector3(0.19, 0.66, 0), Vector3(0.06, 0.34, 0.07), skin)
	_part(Vector3(0, 1.0, 0), Vector3(0.2, 0.22, 0.19), skin)            # head
	_part(Vector3(0, 1.12, 0.02), Vector3(0.22, 0.06, 0.21), hair)
	_part(Vector3(0, 1.02, 0.08), Vector3(0.22, 0.2, 0.06), hair)        # hair at the back
	_part(Vector3(-0.13, 1.06, 0.02), Vector3(0.06, 0.08, 0.06), hair)   # bunches
	_part(Vector3(0.13, 1.06, 0.02), Vector3(0.06, 0.08, 0.06), hair)
	_part(Vector3(-0.045, 1.01, -0.096), Vector3(0.03, 0.02, 0.01), eyes)
	_part(Vector3(0.045, 1.01, -0.096), Vector3(0.03, 0.02, 0.01), eyes)


func _part(pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	_body.add_child(mi)
