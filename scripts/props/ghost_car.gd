extends Node3D
## The car. Dark grey, headlights on full. The same one in flashback 1 (the crash) and in
## the scare on the football lawn. Built from boxes; its front faces local -Z.

const Psx := preload("res://scripts/psx.gd")
const Tex := preload("res://scripts/textures.gd")

var beam_energy := 8.0


func _ready() -> void:
	var paint := Psx.material(Tex.get_texture("car"), Config.GHOST_CAR_COLOR, 1.0, false)
	var dark := Psx.material(Tex.get_texture("plain"), Color(0.08, 0.08, 0.1), 1.0, false)
	var lamp := Psx.material(Tex.get_texture("plain"), Color.WHITE, 1.0, false, Color(1, 1, 0.95))
	var tyre := Psx.material(Tex.get_texture("plain"), Color(0.05, 0.05, 0.05), 1.0, false)
	_part(Vector3(0, 0.62, 0), Vector3(1.8, 0.6, 4.4), paint)          # body
	_part(Vector3(0, 1.15, 0.3), Vector3(1.6, 0.5, 2.2), dark)         # cabin / windows
	_part(Vector3(0, 1.42, 0.3), Vector3(1.62, 0.06, 2.0), paint)      # roof
	for x in [-0.6, 0.6]:
		_part(Vector3(x, 0.7, -2.21), Vector3(0.38, 0.16, 0.04), lamp)   # headlights
	for x in [-0.85, 0.85]:
		for z in [-1.4, 1.4]:
			_part(Vector3(x, 0.33, z), Vector3(0.22, 0.66, 0.66), tyre)
	var beam := SpotLight3D.new()
	beam.position = Vector3(0, 0.7, -2.4)
	beam.light_energy = beam_energy
	beam.light_color = Color(1.0, 0.97, 0.9)
	beam.spot_range = 40.0
	beam.spot_angle = 35.0
	add_child(beam)


func _part(pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	add_child(mi)
