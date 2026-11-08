extends Node3D
## Shared building blocks for levels built from boxes in code.
## A level overrides build() and get_settings(), and sets `spawn`.

const Psx := preload("res://scripts/psx.gd")
const Tex := preload("res://scripts/textures.gd")
const Pickup := preload("res://scripts/pickup.gd")

## Where the player starts (and wakes up, in the hospital).
var spawn := Transform3D.IDENTITY


func build() -> void:
	pass


## Environment and rules for this level, read by main.gd. Keys (all optional):
## fog_mode ("exponential" | "depth"), fog_color, fog_density, fog_depth_begin, fog_depth_end,
## fog_depth_curve, fog_sun_scatter, ambient_color, ambient_energy, tint, tint_strength,
## camera_far, flashlight_on, hallucinations, navigation, withdrawal_rate, start_message
func get_settings() -> Dictionary:
	return {}


func mat(texture: String, color := Color.WHITE, uv_scale := Config.TEXTURE_SCALE,
		world_uv := true, emission := Color.BLACK) -> ShaderMaterial:
	return Psx.material(Tex.get_texture(texture), color, uv_scale, world_uv, emission)


## A box. With collide=true it becomes a StaticBody3D (walls, furniture).
## subdiv: metres per subdivision (smaller = more vertex jitter detail, more triangles).
func box(center: Vector3, size: Vector3, material: Material, collide := true, parent: Node3D = null,
		subdiv := 0.75) -> Node3D:
	if parent == null:
		parent = self
	var mesh := BoxMesh.new()
	mesh.size = size
	# Subdivide large faces so vertex jitter and affine warping look right.
	mesh.subdivide_width = clampi(int(size.x / subdiv), 0, 40)
	mesh.subdivide_height = clampi(int(size.y / subdiv), 0, 40)
	mesh.subdivide_depth = clampi(int(size.z / subdiv), 0, 40)
	mesh.material = material
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if not collide:
		mi.position = center
		parent.add_child(mi)
		return mi
	var body := StaticBody3D.new()
	body.position = center
	parent.add_child(body)
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	return body


## Invisible wall that keeps the player inside the level.
func invisible_wall(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = center
	add_child(body)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)


func cylinder(pos: Vector3, radius: float, height: float, material: Material, parent: Node3D = null) -> MeshInstance3D:
	if parent == null:
		parent = self
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 8
	c.rings = 1
	c.material = material
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position = pos
	parent.add_child(mi)
	return mi


func sign_text(text: String, pos: Vector3, rot_y: float, font_size := 24,
		color := Color(0.75, 0.8, 0.65), parent: Node3D = null) -> Label3D:
	if parent == null:
		parent = self
	var l := Label3D.new()
	l.text = text
	l.font_size = font_size
	l.pixel_size = 0.006
	l.outline_size = 0
	l.modulate = color
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	l.position = pos
	l.rotation_degrees.y = rot_y
	parent.add_child(l)
	return l


func pill_bottle(pos: Vector3, message: String) -> Node3D:
	var p := Pickup.new()
	p.kind = "pill"
	p.prompt = "Pill bottle"
	p.message = message
	p.position = pos
	var amber := mat("plain", Color(0.75, 0.42, 0.1), 1.0, false, Color(0.08, 0.04, 0.0))
	var white := mat("plain", Color(0.9, 0.9, 0.85), 1.0, false)
	cylinder(Vector3(0, 0.06, 0), 0.045, 0.12, amber, p)
	cylinder(Vector3(0, 0.135, 0), 0.048, 0.03, white, p)
	add_child(p)
	return p


## A door the player can use (E) to go to another level.
func level_door(pos: Vector3, size: Vector3, prompt: String, target_level: String) -> void:
	var p := Pickup.new()
	p.kind = "door"
	p.prompt = prompt
	p.target_level = target_level
	p.shape_size = size
	p.position = pos
	add_child(p)


func get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D
