extends Node3D
## Shared building blocks for levels built from boxes in code.
## A level overrides build() and get_settings(), and sets `spawn`.

const Psx := preload("res://scripts/psx.gd")
const Tex := preload("res://scripts/textures.gd")
const Pickup := preload("res://scripts/pickup.gd")
const POST_SHADER := preload("res://shaders/post.gdshader")

## Where the player starts this time.
var spawn := Transform3D.IDENTITY
## Where the player wakes up after being caught (the hospital bed). Defaults to spawn.
var bed_spawn := Transform3D.IDENTITY


func build() -> void:
	pass


## Environment and rules for this level, read by main.gd. Keys (all optional):
## fog_mode ("exponential" | "depth"), fog_color, fog_density, fog_depth_begin, fog_depth_end,
## fog_depth_curve, fog_sun_scatter, ambient_color, ambient_energy, tint, tint_strength,
## camera_far, flashlight_on, hallucinations, episodes, navigation, withdrawal_rate, start_message
func get_settings() -> Dictionary:
	return {}


## WorldEnvironment (background, ambient light, fog) from a get_settings() dictionary.
func make_environment(s: Dictionary) -> WorldEnvironment:
	var fog_color: Color = s.get("fog_color", Color.BLACK)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = fog_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = s.get("ambient_color", Color.WHITE)
	env.ambient_light_energy = s.get("ambient_energy", 0.2)
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = fog_color
	env.fog_sun_scatter = s.get("fog_sun_scatter", 0.0)
	if s.get("fog_mode", "exponential") == "depth":
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_density = s.get("fog_density", 1.0)
		env.fog_depth_begin = s.get("fog_depth_begin", 0.0)
		env.fog_depth_end = s.get("fog_depth_end", 100.0)
		env.fog_depth_curve = s.get("fog_depth_curve", 1.0)
	else:
		env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		env.fog_density = s.get("fog_density", 0.1)
	var we := WorldEnvironment.new()
	we.environment = env
	return we


## Post-processing material (shaders/post.gdshader) from a get_settings() dictionary.
func make_post_material(s: Dictionary) -> ShaderMaterial:
	var tint: Color = s.get("tint", Color.WHITE)
	var m := ShaderMaterial.new()
	m.shader = POST_SHADER
	m.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	m.set_shader_parameter("tint_strength", s.get("tint_strength", 0.0))
	m.set_shader_parameter("color_depth", Config.COLOR_DEPTH)
	m.set_shader_parameter("dither_strength", Config.DITHER_STRENGTH)
	m.set_shader_parameter("vignette", s.get("vignette", Config.VIGNETTE))
	m.set_shader_parameter("numb", s.get("numb", 0.0))
	return m


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


## A pill bottle. id must be unique; once taken it never comes back. message "" = default lines.
func pill_bottle(pos: Vector3, id: String, message := "") -> Node3D:
	if id in Withdrawal.taken_pills:
		return null
	var p := Pickup.new()
	p.kind = "pill"
	p.item_id = id
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
