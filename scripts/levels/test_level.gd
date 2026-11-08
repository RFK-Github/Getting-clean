extends "res://scripts/levels/level_base.gd"
## TEMPORARY test level (milestone 1). Stands in for the hospital until build step 3.
## Builds a corridor and three rooms (dormitory, common room, office) from simple boxes.
##
## Map (top view, -Z is "forward" down the corridor):
##   Corridor:    x -1.5..1.5,  z 2..-24  (locked visiting-room door at the end)
##   Dormitory:   x -7.5..-1.5, z -1..-8  (left, door at z -4.5)
##   Common room: x 1.5..9.5,   z -9..-17 (right, door at z -13)
##   Office:      x -6.5..-1.5, z -15..-22 (left, door at z -18.5)


const H := 3.0        # ceiling height
const T := 0.2        # wall thickness
const DOOR_H := 2.1
const PILL_MESSAGE := "You swallow the pills. The shaking fades. But your body remembers."
const Audio := preload("res://scripts/audio.gd")

var _flicker: Array[OmniLight3D] = []
var m_wall: ShaderMaterial
var m_tiles: ShaderMaterial
var m_ceiling: ShaderMaterial
var m_wood: ShaderMaterial
var m_carpet: ShaderMaterial
var m_metal: ShaderMaterial
var m_fabric: ShaderMaterial
var m_sheet: ShaderMaterial
var m_door: ShaderMaterial
var m_dark: ShaderMaterial


func build() -> void:
	_make_materials()
	_build_corridor()
	_build_dorm()
	_build_common_room()
	_build_office()

	var hum := AudioStreamPlayer.new()
	hum.stream = Audio.hum()
	hum.volume_db = Config.AMBIENT_HUM_DB
	hum.autoplay = true
	add_child(hum)


func get_settings() -> Dictionary:
	return {
		"fog_mode": "exponential",
		"fog_color": Config.HOSPITAL_FOG_COLOR,
		"fog_density": Config.HOSPITAL_FOG_DENSITY,
		"ambient_color": Config.HOSPITAL_AMBIENT_COLOR,
		"ambient_energy": Config.HOSPITAL_AMBIENT_ENERGY,
		"tint": Config.HOSPITAL_TINT_COLOR,
		"tint_strength": Config.HOSPITAL_TINT_STRENGTH,
		"camera_far": Config.HOSPITAL_CAMERA_FAR,
		"flashlight_on": true,
		"hallucinations": true,
		"navigation": true,
		"withdrawal_rate": 1.0,
		"start_message": "A nurse walks you to your bed without a word. The door clicks shut.",
	}


func _process(_delta: float) -> void:
	for l in _flicker:
		if randf() < Config.LAMP_FLICKER_CHANCE:
			l.light_energy = randf_range(0.0, Config.LAMP_ENERGY * 0.3)
		else:
			l.light_energy = lerpf(l.light_energy, Config.LAMP_ENERGY, 0.2)


func _make_materials() -> void:
	m_wall = Psx.material(Tex.get_texture("wall"))
	m_tiles = Psx.material(Tex.get_texture("tiles"))
	m_ceiling = Psx.material(Tex.get_texture("ceiling"))
	m_wood = Psx.material(Tex.get_texture("wood"), Color.WHITE, 1.0)
	m_carpet = Psx.material(Tex.get_texture("carpet"))
	m_metal = Psx.material(Tex.get_texture("metal"), Color.WHITE, 1.0)
	m_fabric = Psx.material(Tex.get_texture("fabric"), Color.WHITE, 1.5)
	m_sheet = Psx.material(Tex.get_texture("fabric"), Color(1.6, 1.6, 1.4), 1.5)
	m_door = Psx.material(Tex.get_texture("door"), Color.WHITE, 0.8)
	m_dark = Psx.material(Tex.get_texture("metal"), Color(0.25, 0.25, 0.25), 1.0)


# ------------------ Rooms

func _build_corridor() -> void:
	box(Vector3(0, -0.1, -11), Vector3(3, 0.2, 26), m_tiles)
	box(Vector3(0, H + 0.1, -11), Vector3(3, 0.2, 26), m_ceiling, false)
	_wall(true, -1.5, -24, 2, [[-4.5, 1.3], [-18.5, 1.3]])
	_wall(true, 1.5, -24, 2, [[-13.0, 1.6]])
	_wall(false, 2, -1.5, 1.5, [])
	_wall(false, -24, -1.5, 1.5, [])

	# Bench
	box(Vector3(1.2, 0.22, -6), Vector3(0.4, 0.44, 1.4), m_dark)

	lamp(Vector3(0, 0, 0))
	lamp(Vector3(0, 0, -7.5), true)
	lamp(Vector3(0, 0, -15))
	lamp(Vector3(0, 0, -22))

	sign_text("DORMITORY", Vector3(-1.39, 2.4, -4.5), 90)
	sign_text("COMMON ROOM", Vector3(1.39, 2.4, -13), -90)
	sign_text("OFFICE", Vector3(-1.39, 2.4, -18.5), 90)
	sign_text("VISITING ROOM", Vector3(0, 2.4, -23.82), 0)

	# Locked door to the visiting room
	box(Vector3(0, DOOR_H * 0.5, -23.86), Vector3(1.2, DOOR_H, 0.06), m_door)
	var lock := Pickup.new()
	lock.kind = "locked"
	lock.prompt = "Visiting room door"
	lock.message = "Locked. Not yet. Not until you are ready."
	lock.shape_size = Vector3(1.2, 2.0, 0.3)
	lock.position = Vector3(0, 0, -23.7)
	add_child(lock)


func _build_dorm() -> void:
	box(Vector3(-4.5, -0.1, -4.5), Vector3(6, 0.2, 7), m_tiles)
	box(Vector3(-4.5, H + 0.1, -4.5), Vector3(6, 0.2, 7), m_ceiling, false)
	_wall(true, -7.5, -8, -1, [])
	_wall(false, -1, -7.5, -1.5, [])
	_wall(false, -8, -7.5, -1.5, [])

	for z in [-2.2, -4.5, -6.8]:
		bed(Vector3(-6.4, 0, z))
	# Lockers
	box(Vector3(-3.0, 0.9, -1.35), Vector3(0.55, 1.8, 0.5), m_metal)
	box(Vector3(-3.6, 0.9, -1.35), Vector3(0.55, 1.8, 0.5), m_metal)
	# Nightstand by the last bed
	box(Vector3(-7.15, 0.25, -7.65), Vector3(0.45, 0.5, 0.45), m_wood)

	lamp(Vector3(-4.5, 0, -4.5), false, Config.DORM_LAMP_ENERGY)

	pill_bottle(Vector3(-7.1, 0.5, -7.6), PILL_MESSAGE)

	# The player starts by their bed, facing the door.
	var pos := Vector3(-5.0, 0.05, -2.2)
	var dir := Vector3(-1.5, 0, -4.5) - pos
	spawn = Transform3D(Basis(Vector3.UP, atan2(-dir.x, -dir.z)), pos)


func _build_common_room() -> void:
	box(Vector3(5.5, -0.1, -13), Vector3(8, 0.2, 8), m_carpet)
	box(Vector3(5.5, H + 0.1, -13), Vector3(8, 0.2, 8), m_ceiling, false)
	_wall(true, 9.5, -17, -9, [])
	_wall(false, -9, 1.5, 9.5, [])
	_wall(false, -17, 1.5, 9.5, [])

	table(Vector3(5.5, 0, -13), Vector2(2.0, 1.2))
	for p in [Vector3(4.9, 0, -14.0), Vector3(6.1, 0, -14.0)]:
		chair(p, 1.0)
	for p in [Vector3(4.9, 0, -12.0), Vector3(6.1, 0, -12.0)]:
		chair(p, -1.0)
	# Sofa
	box(Vector3(8.95, 0.25, -13), Vector3(0.8, 0.5, 2.4), m_fabric)
	box(Vector3(9.3, 0.65, -13), Vector3(0.15, 0.8, 2.4), m_fabric)
	# TV
	box(Vector3(5.5, 0.3, -16.6), Vector3(1.2, 0.6, 0.5), m_wood)
	box(Vector3(5.5, 0.9, -16.6), Vector3(0.8, 0.6, 0.4), m_dark)
	box(Vector3(5.5, 0.9, -16.39), Vector3(0.65, 0.45, 0.02),
		Psx.material(Tex.get_texture("plain"), Color(0.1, 0.15, 0.12), 1.0, true, Color(0.06, 0.1, 0.08)), false)

	lamp(Vector3(5.5, 0, -13), false, 0.5)

	drawing(Vector3(5.1, 0.78, -12.8))


func _build_office() -> void:
	box(Vector3(-4, -0.1, -18.5), Vector3(5, 0.2, 7), m_wood)
	box(Vector3(-4, H + 0.1, -18.5), Vector3(5, 0.2, 7), m_ceiling, false)
	_wall(true, -6.5, -22, -15, [])
	_wall(false, -15, -6.5, -1.5, [])
	_wall(false, -22, -6.5, -1.5, [])

	# Desk
	box(Vector3(-4.2, 0.74, -21.1), Vector3(1.8, 0.08, 0.8), m_wood)
	box(Vector3(-3.55, 0.35, -21.1), Vector3(0.5, 0.7, 0.75), m_wood)
	box(Vector3(-5.05, 0.35, -21.1), Vector3(0.06, 0.7, 0.75), m_wood)
	chair(Vector3(-4.3, 0, -20.3), -1.0)
	# Filing cabinets
	box(Vector3(-6.15, 0.65, -16.0), Vector3(0.5, 1.3, 0.6), m_metal)
	box(Vector3(-6.15, 0.65, -16.7), Vector3(0.5, 1.3, 0.6), m_metal)
	# Papers
	box(Vector3(-4.6, 0.785, -21.0), Vector3(0.3, 0.01, 0.22),
		Psx.material(Tex.get_texture("plain"), Color(0.8, 0.8, 0.72), 1.0), false)

	# Desk lamp (only light in the office)
	box(Vector3(-4.9, 0.9, -21.25), Vector3(0.12, 0.25, 0.12), m_dark, false)
	var l := OmniLight3D.new()
	l.position = Vector3(-4.9, 1.15, -21.1)
	l.light_color = Color(1.0, 0.85, 0.55)
	l.light_energy = 0.7
	l.omni_range = 3.0
	add_child(l)

	pill_bottle(Vector3(-3.7, 0.78, -20.95), PILL_MESSAGE)


# ------------------ Building blocks

## Wall along Z (along_z) at x=fixed, or along X at z=fixed. gaps = [[center, width], ...]
func _wall(along_z: bool, fixed: float, a: float, b: float, gaps: Array) -> void:
	var lo := minf(a, b) - T * 0.5
	var hi := maxf(a, b) + T * 0.5
	var sorted := gaps.duplicate()
	sorted.sort_custom(func(p, q): return p[0] < q[0])
	var cursor := lo
	for g in sorted:
		var g0: float = g[0] - g[1] * 0.5
		var g1: float = g[0] + g[1] * 0.5
		_wall_piece(along_z, fixed, cursor, g0, 0.0, H)
		_wall_piece(along_z, fixed, g0, g1, DOOR_H, H)
		cursor = g1
	_wall_piece(along_z, fixed, cursor, hi, 0.0, H)


func _wall_piece(along_z: bool, fixed: float, a: float, b: float, y0: float, y1: float) -> void:
	if b - a < 0.01:
		return
	var mid := (a + b) * 0.5
	var y := (y0 + y1) * 0.5
	if along_z:
		box(Vector3(fixed, y, mid), Vector3(T, y1 - y0, b - a), m_wall)
	else:
		box(Vector3(mid, y, fixed), Vector3(b - a, y1 - y0, T), m_wall)


func lamp(pos: Vector3, flicker := false, energy := Config.LAMP_ENERGY) -> void:
	box(Vector3(pos.x, H - 0.03, pos.z), Vector3(0.7, 0.05, 0.25),
		Psx.material(Tex.get_texture("plain"), Config.LAMP_COLOR, 1.0, true, Config.LAMP_COLOR * 0.8), false)
	var l := OmniLight3D.new()
	l.position = Vector3(pos.x, H - 0.4, pos.z)
	l.light_color = Config.LAMP_COLOR
	l.light_energy = energy
	l.omni_range = Config.LAMP_RANGE
	add_child(l)
	if flicker:
		_flicker.append(l)



func bed(pos: Vector3) -> void:
	box(pos + Vector3(0, 0.2, 0), Vector3(2.0, 0.4, 0.9), m_metal)
	box(pos + Vector3(0.05, 0.46, 0), Vector3(1.9, 0.12, 0.85), m_sheet, false)
	box(pos + Vector3(-0.75, 0.56, 0), Vector3(0.35, 0.1, 0.6), m_sheet, false)


func table(pos: Vector3, size: Vector2) -> void:
	box(pos + Vector3(0, 0.74, 0), Vector3(size.x, 0.08, size.y), m_wood)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			box(pos + Vector3(sx * (size.x * 0.5 - 0.1), 0.35, sz * (size.y * 0.5 - 0.1)),
				Vector3(0.08, 0.7, 0.08), m_wood, false)


## facing: 1 = backrest towards -Z, -1 = backrest towards +Z
func chair(pos: Vector3, facing: float) -> void:
	box(pos + Vector3(0, 0.45, 0), Vector3(0.45, 0.06, 0.45), m_wood)
	box(pos + Vector3(0, 0.22, 0), Vector3(0.4, 0.44, 0.4), m_dark, false)
	box(pos + Vector3(0, 0.75, facing * 0.2), Vector3(0.45, 0.55, 0.05), m_wood, false)



func drawing(pos: Vector3) -> void:
	var p := Pickup.new()
	p.kind = "item"
	p.item_id = "drawing"
	p.prompt = "A drawing"
	p.message = "A child's drawing. Two figures holding hands. Something about it hurts, and you don't know why."
	p.position = pos
	p.rotation_degrees.y = 12
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.32, 0.23)
	plane.material = Psx.material(Tex.get_texture("drawing"), Color.WHITE, 1.0, false, Color(0.06, 0.06, 0.05))
	mi.mesh = plane
	mi.position.y = 0.006
	p.add_child(mi)
	add_child(p)

