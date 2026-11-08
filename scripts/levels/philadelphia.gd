extends "res://scripts/levels/level_base.gd"
## LEVEL 1: Downtown Philadelphia at dawn.
## Start at a bus stop, walk three blocks under the elevated train to the recovery center.
##
## Map (top view, the player walks toward -Z):
##   Main street (Market St): road x -6..6, sidewalks x ±6..±10, buildings from x ±10 outwards.
##   Elevated train on pillars above the street centre (deck at y 7).
##   Bus stop on the right sidewalk at z 0. Cross streets at z -40..-52 and -100..-112.
##   Recovery center on the right, z -122..-150, entrance at z -136.
##   Invisible walls at z 14 and z -165 (the street continues into the fog beyond them).

const Audio := preload("res://scripts/audio.gd")
const Mover := preload("res://scripts/props/mover.gd")
const FogFigure := preload("res://scripts/props/fog_figure.gd")

const STREET_HALF := 6.0         # road from -6 to 6
const FRONT := 10.0              # building fronts at x = ±10
const STREET_START := 60.0
const STREET_END := -230.0
const WALK_START := 14.0
const WALK_END := -165.0
const CROSS_STREETS := [[-40.0, -52.0], [-100.0, -112.0]]
const CENTER := [-122.0, -150.0]
const DOOR_Z := -136.0
const STOREY := 3.0
const DECK_Y := 7.0
const PILLAR_X := 4.2
const PILLAR_SPACING := 15.0

const PILL_MESSAGE := "You swallow them before you can think. The shaking stops. You hate how easy that was."

var m_asphalt: ShaderMaterial
var m_sidewalk: ShaderMaterial
var m_bricks: Array[ShaderMaterial] = []
var m_concrete: ShaderMaterial
var m_center: ShaderMaterial
var m_steel: ShaderMaterial
var m_steel_dark: ShaderMaterial
var m_shutter: ShaderMaterial
var m_glass: ShaderMaterial
var m_window_lit: ShaderMaterial
var m_shop_lit: ShaderMaterial
var m_line: ShaderMaterial
var m_white: ShaderMaterial
var m_tower: ShaderMaterial
var m_lamp: ShaderMaterial
var m_tire: ShaderMaterial
var m_wood: ShaderMaterial

var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _train_timer: float = Config.TRAIN_FIRST_DELAY
var _train_dir := -1.0
var _car_timer := 6.0
var _siren_timer: float = Config.SIREN_FIRST_DELAY
var _siren: AudioStreamPlayer3D
var _trains: Array = []
var _hint_done := false


func get_settings() -> Dictionary:
	return {
		"fog_mode": "depth",
		"fog_color": Config.PHILLY_FOG_COLOR,
		"fog_density": Config.PHILLY_FOG_MAX,
		"fog_depth_begin": Config.PHILLY_FOG_BEGIN,
		"fog_depth_end": Config.PHILLY_FOG_END,
		"fog_depth_curve": Config.PHILLY_FOG_CURVE,
		"fog_sun_scatter": Config.PHILLY_FOG_SUN_SCATTER,
		"ambient_color": Config.PHILLY_AMBIENT_COLOR,
		"ambient_energy": Config.PHILLY_AMBIENT_ENERGY,
		"tint": Config.PHILLY_TINT_COLOR,
		"tint_strength": Config.PHILLY_TINT_STRENGTH,
		"camera_far": Config.PHILLY_CAMERA_FAR,
		"flashlight_on": false,
		"hallucinations": false,
		"navigation": false,
		"withdrawal_rate": Config.PHILLY_WITHDRAWAL_RATE,
		"start_message": "Philadelphia, just before sunrise. The recovery center is three blocks down. You promised her you would go.",
	}


func build() -> void:
	_rng.seed = 1979
	_make_materials()
	_ground()
	_el_tracks()
	_buildings()
	_recovery_center()
	_towers()
	_sun()
	_streetlights()
	_parked_cars()
	_street_props()
	_bus_stop()
	_boundaries()
	_ambience()

	for p in [Vector3(-2.5, 0, -8), Vector3(2.0, 0, -18), Vector3(-1.5, 0, -66), Vector3(2.5, 0, -127)]:
		_steam(p)

	pill_bottle(Vector3(8.3, 0.12, -28.6), "street", PILL_MESSAGE)

	var figure := FogFigure.new()
	figure.position = Vector3(0.6, 0, -82)
	add_child(figure)

	_spawn_bus()
	spawn = Transform3D(Basis.IDENTITY, Vector3(7.6, 0.05, 2.2))  # under the bus shelter, facing -Z


func _process(delta: float) -> void:
	_t += delta
	var player := get_player()

	# Teach the flashlight once.
	if not _hint_done and _t > Config.FLASHLIGHT_HINT_DELAY and player != null:
		_hint_done = true
		if not player.get("flashlight").visible:
			Withdrawal.post_message("It's still dark under the tracks. Press F for your flashlight.")

	_train_timer -= delta
	if _train_timer <= 0.0:
		_train_timer = Config.TRAIN_INTERVAL
		_spawn_train(_train_dir)
		_train_dir = -_train_dir

	_car_timer -= delta
	if _car_timer <= 0.0:
		_car_timer = Config.CAR_INTERVAL
		_spawn_car()

	_siren_timer -= delta
	if _siren_timer <= 0.0:
		_siren_timer = Config.SIREN_INTERVAL
		_siren.position = Vector3(_rng.randf_range(-120, -60) * (1 if _rng.randf() < 0.5 else -1), 5, _rng.randf_range(-200, 0))
		_siren.play()

	# A passing train shakes the camera a little.
	if player != null:
		var shake := 0.0
		_trains = _trains.filter(func(t): return is_instance_valid(t))
		for tr in _trains:
			var d := absf(tr.global_position.z - player.global_position.z) - Config.TRAIN_CARS * 7.0
			if d < Config.TRAIN_SHAKE_DISTANCE:
				shake = maxf(shake, Config.TRAIN_SHAKE * (1.0 - maxf(d, 0.0) / Config.TRAIN_SHAKE_DISTANCE))
		player.call("set_shake", "train", shake)


# ------------------------------------------------------------------ Materials

func _make_materials() -> void:
	m_asphalt = mat("asphalt", Color.WHITE, 0.4)
	m_sidewalk = mat("sidewalk", Color.WHITE, 0.6)
	for c in [Color(1, 1, 1), Color(0.85, 0.8, 0.78), Color(1.1, 0.95, 0.85)]:
		m_bricks.append(mat("brick_window", c, 1.0 / STOREY))
	m_concrete = mat("concrete", Color.WHITE, 0.5)
	m_center = mat("concrete_window", Color(1.05, 1.0, 0.95), 1.0 / STOREY)
	m_steel = mat("metal", Color(0.55, 0.5, 0.45), 0.5)
	m_steel_dark = mat("metal", Color(0.3, 0.28, 0.26), 1.0)
	m_shutter = mat("shutter", Color.WHITE, 0.5)
	m_glass = mat("plain", Color(0.06, 0.07, 0.08), 1.0)
	m_window_lit = mat("plain", Color(0.9, 0.7, 0.4), 1.0, true, Color(0.75, 0.55, 0.3))
	m_shop_lit = mat("plain", Color(0.8, 0.75, 0.6), 1.0, true, Color(0.55, 0.5, 0.35))
	m_line = mat("plain", Color(0.8, 0.65, 0.2), 1.0)
	m_white = mat("plain", Color(0.75, 0.73, 0.68), 1.0)
	m_tower = mat("tower", Color.WHITE, 0.25)
	m_lamp = mat("plain", Config.STREETLIGHT_COLOR, 1.0, true, Config.STREETLIGHT_COLOR)
	m_tire = mat("plain", Color(0.08, 0.08, 0.08), 1.0)
	m_wood = mat("wood", Color.WHITE, 1.0)


# ------------------------------------------------------------------ Street

func _in_cross_street(z: float, margin := 0.0) -> bool:
	for cs in CROSS_STREETS:
		if z < cs[0] + margin and z > cs[1] - margin:
			return true
	return false


func _ground() -> void:
	# One flat collider for everything you can walk on (sidewalks are visual only).
	invisible_wall(Vector3(0, -0.5, -85), Vector3(140, 1.0, 340))

	var z := STREET_START
	while z > STREET_END:
		box(Vector3(0, -0.05, z - 5.0), Vector3(STREET_HALF * 2, 0.1, 10.0), m_asphalt, false, null, 2.0)
		if not _in_cross_street(z - 5.0):
			for side in [-1.0, 1.0]:
				box(Vector3(side * (STREET_HALF + 2.0), 0.06, z - 5.0), Vector3(4.0, 0.12, 10.0), m_sidewalk, false, null, 2.0)
		z -= 10.0

	# Dashed centre line
	z = STREET_START
	while z > STREET_END:
		box(Vector3(0, 0.005, z), Vector3(0.12, 0.01, 2.0), m_line, false)
		z -= 6.0

	# Cross streets and crosswalks
	for cs in CROSS_STREETS:
		var mid: float = (cs[0] + cs[1]) * 0.5
		var w: float = cs[0] - cs[1]
		for side in [-1.0, 1.0]:
			var x := STREET_HALF
			while x < 50.0:
				box(Vector3(side * (x + 5.0), -0.05, mid), Vector3(10.0, 0.1, w), m_asphalt, false, null, 2.0)
				x += 10.0
		for edge in [cs[0] - 1.5, cs[1] + 1.5]:
			var sx := -STREET_HALF + 0.5
			while sx < STREET_HALF:
				box(Vector3(sx, 0.006, edge), Vector3(0.5, 0.01, 2.4), m_white, false)
				sx += 1.0
		# Street signs on the near corner
		_street_sign(Vector3(FRONT - 0.8, 0, cs[0] + 0.8), "N %dTH ST" % (40 - CROSS_STREETS.find(cs)))


func _street_sign(pos: Vector3, cross_name: String) -> void:
	box(pos + Vector3(0, 1.6, 0), Vector3(0.08, 3.2, 0.08), m_steel_dark)
	var green := mat("plain", Color(0.1, 0.35, 0.2), 1.0)
	box(pos + Vector3(0, 3.0, 0), Vector3(0.04, 0.22, 1.1), green, false)
	box(pos + Vector3(0, 3.3, 0), Vector3(1.1, 0.22, 0.04), green, false)
	sign_text("MARKET ST", pos + Vector3(-0.03, 3.0, 0), -90, 20, Color(0.9, 0.9, 0.85))
	sign_text(cross_name, pos + Vector3(0, 3.3, 0.03), 0, 20, Color(0.9, 0.9, 0.85))


func _el_tracks() -> void:
	var length := STREET_START - STREET_END
	var mid := (STREET_START + STREET_END) * 0.5
	var z := STREET_START
	while z > STREET_END:
		box(Vector3(0, DECK_Y + 0.4, z - 7.5), Vector3(9.0, 0.8, 15.0), m_steel, false, null, 3.0)
		z -= 15.0
	for side in [-1.0, 1.0]:
		box(Vector3(side * 4.4, DECK_Y + 1.25, mid), Vector3(0.2, 0.9, length), m_steel, false, null, 5.0)
	for x in [-2.3, -0.8, 0.8, 2.3]:
		box(Vector3(x, DECK_Y + 0.86, mid), Vector3(0.1, 0.12, length), m_steel_dark, false, null, 8.0)

	z = STREET_START - 5.0
	while z > STREET_END:
		for side in [-1.0, 1.0]:
			box(Vector3(side * PILLAR_X, DECK_Y * 0.5, z), Vector3(0.5, DECK_Y, 0.5), m_steel_dark, true, null, 1.5)
			# diagonal brace from pillar to deck
			var brace := box(Vector3(side * (PILLAR_X - 0.7), DECK_Y - 0.9, z), Vector3(0.15, 2.2, 0.15), m_steel_dark, false)
			brace.rotation.z = side * deg_to_rad(35)
		box(Vector3(0, DECK_Y - 0.25, z), Vector3(9.4, 0.5, 0.6), m_steel_dark, false, null, 1.5)
		z -= PILLAR_SPACING


# ------------------------------------------------------------------ Buildings

func _buildings() -> void:
	var segments := [[STREET_START, CROSS_STREETS[0][0]], [CROSS_STREETS[0][1], CROSS_STREETS[1][0]],
		[CROSS_STREETS[1][1], STREET_END]]
	for side in [-1.0, 1.0]:
		for seg in segments:
			var z: float = seg[0]
			var z_end: float = seg[1]
			while z - z_end > 4.0:
				var w := minf(_rng.randf_range(9.0, 16.0), z - z_end)
				if z - w - z_end < 6.0:
					w = z - z_end  # don't leave a sliver
				var z1 := z - w
				# Keep the recovery center's lot free.
				if side > 0.0 and z1 < CENTER[0] and z > CENTER[1]:
					if z > CENTER[0]:
						_building(side, z, CENTER[0])
					z = CENTER[1]
					continue
				_building(side, z, z1)
				z = z1
	# Buildings closing off the far ends of the cross streets
	for cs in CROSS_STREETS:
		for side in [-1.0, 1.0]:
			var h := 18.0
			box(Vector3(side * 52.0, h * 0.5, (cs[0] + cs[1]) * 0.5), Vector3(8.0, h, 30.0), m_bricks[0], false, null, STOREY)


func _building(side: float, z0: float, z1: float) -> void:
	var floors := _rng.randi_range(3, 6)
	var h := floors * STOREY
	var w := z0 - z1
	var depth := 35.0
	var face_x := side * FRONT
	var brick: ShaderMaterial = m_bricks[_rng.randi() % m_bricks.size()]
	box(Vector3(side * (FRONT + depth * 0.5), h * 0.5, (z0 + z1) * 0.5), Vector3(depth, h, w - 0.1), brick, true, null, STOREY)
	# Cornice along the roof line
	box(Vector3(face_x - side * 0.15, h + 0.2, (z0 + z1) * 0.5), Vector3(0.5, 0.4, w - 0.1), m_concrete, false, null, 2.0)

	# Ground floor: shop window (some lit) or a rusty shutter.
	var shop_w := w - 1.2
	var lit := _rng.randf() < 0.3
	var front_mat := m_shop_lit if lit else (m_shutter if _rng.randf() < 0.6 else m_glass)
	box(Vector3(face_x - side * 0.03, 1.5, (z0 + z1) * 0.5), Vector3(0.06, 3.0, shop_w), front_mat, false, null, 1.5)
	if _rng.randf() < 0.4:
		var awning := mat("fabric", Color(_rng.randf_range(0.4, 1.0), 0.4, 0.35), 1.0)
		var a := box(Vector3(face_x - side * 0.7, 3.2, (z0 + z1) * 0.5), Vector3(1.4, 0.08, shop_w), awning, false)
		a.rotation.z = side * deg_to_rad(-12)

	# Lit windows: they line up with the window tiles in the "brick_window" texture.
	for f in range(1, floors):
		var k := ceili(z1 / STOREY)
		while k * STOREY + STOREY <= z0:
			if _rng.randf() < 0.12:
				box(Vector3(face_x - side * 0.02, f * STOREY + 1.595, k * STOREY + 1.5),
					Vector3(0.04, 1.69, 1.12), m_window_lit, false)
			k += 1

	if floors >= 3 and w >= 9.0 and _rng.randf() < 0.6:
		_fire_escape(side, z0, z1, floors)


## Zig-zag fire escape on the front of a building.
func _fire_escape(side: float, z0: float, z1: float, floors: int) -> void:
	var col := floori(((z0 + z1) * 0.5) / STOREY)
	var cz := col * STOREY + 1.5
	if cz - 1.8 < z1 or cz + 1.8 > z0:
		return
	var x := side * (FRONT - 0.5)
	for f in range(1, floors):
		var y := f * STOREY + 0.05
		box(Vector3(x, y, cz), Vector3(1.0, 0.06, 3.4), m_steel_dark, false)                      # platform
		box(Vector3(side * (FRONT - 1.0), y + 0.95, cz), Vector3(0.05, 0.05, 3.4), m_steel_dark, false)  # rail
		for dz in [-1.65, 1.65]:
			box(Vector3(side * (FRONT - 1.0), y + 0.5, cz + dz), Vector3(0.05, 0.95, 0.05), m_steel_dark, false)
		if f < floors - 1:
			var stair := box(Vector3(side * (FRONT - 0.5), y + STOREY * 0.5, cz), Vector3(0.6, 0.06, 3.8), m_steel_dark, false)
			stair.rotation.x = deg_to_rad(52) * (1.0 if f % 2 == 0 else -1.0)
	# Hanging ladder below the first platform
	box(Vector3(side * (FRONT - 0.8), STOREY - 1.0, cz + 1.4), Vector3(0.4, 2.0, 0.05), m_steel_dark, false)


func _recovery_center() -> void:
	var z0: float = CENTER[0]
	var z1: float = CENTER[1]
	var h := 5 * STOREY
	var mid := (z0 + z1) * 0.5
	box(Vector3(FRONT + 15.0, h * 0.5, mid), Vector3(30.0, h, z0 - z1), m_center, true, null, STOREY)

	# Entrance: lit glass doors under a canopy
	var lobby := mat("plain", Color(0.9, 0.88, 0.75), 1.0, true, Color(0.7, 0.68, 0.55))
	box(Vector3(FRONT - 0.03, 1.5, DOOR_Z), Vector3(0.06, 3.0, 6.0), lobby, false)
	box(Vector3(FRONT - 0.05, 1.25, DOOR_Z), Vector3(0.06, 2.5, 0.08), m_steel_dark, false)  # door split
	box(Vector3(FRONT - 1.4, 3.3, DOOR_Z), Vector3(2.8, 0.2, 6.5), m_concrete, false)
	for dz in [-3.0, 3.0]:
		box(Vector3(FRONT - 2.7, 1.65, DOOR_Z + dz), Vector3(0.15, 3.3, 0.15), m_steel)

	sign_text("RECOVERY CENTER", Vector3(FRONT - 0.08, 4.4, DOOR_Z), -90, 48, Color(0.95, 0.92, 0.8))
	sign_text("Open 24 hours. Walk-ins welcome.", Vector3(FRONT - 2.85, 3.05, DOOR_Z), -90, 16, Color(0.9, 0.88, 0.75))

	var l := OmniLight3D.new()
	l.position = Vector3(FRONT - 1.5, 2.9, DOOR_Z)
	l.light_color = Color(1.0, 0.95, 0.8)
	l.light_energy = 1.6
	l.omni_range = 9.0
	add_child(l)

	# Planters
	for dz in [-5.5, 5.5]:
		box(Vector3(FRONT - 0.6, 0.45, DOOR_Z + dz), Vector3(1.0, 0.7, 2.0), m_concrete)

	level_door(Vector3(FRONT - 0.4, 0, DOOR_Z), Vector3(0.8, 2.6, 3.0), "Enter the recovery center", "hospital")


func _towers() -> void:
	for i in 16:
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * _rng.randf_range(15.0, 140.0)
		var z := _rng.randf_range(-190.0, -320.0)
		var w := _rng.randf_range(18.0, 40.0)
		var h := _rng.randf_range(50.0, 160.0)
		box(Vector3(x, h * 0.5, z), Vector3(w, h, w), m_tower, false, null, 10.0)


func _sun() -> void:
	var sun := DirectionalLight3D.new()
	sun.light_color = Config.PHILLY_SUN_COLOR
	sun.light_energy = Config.PHILLY_SUN_ENERGY
	sun.rotation_degrees = Vector3(-Config.PHILLY_SUN_ELEVATION, 195.0, 0.0)  # low, ahead and to the left
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)

	# Hazy sun disc behind the towers.
	var quad := QuadMesh.new()
	quad.size = Vector2(70, 70)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = Tex.get_texture("sun")
	m.albedo_color = Config.PHILLY_SUN_DISC_COLOR
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.set("disable_fog", true)
	quad.material = m
	var disc := MeshInstance3D.new()
	disc.mesh = quad
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var dir := Vector3(-0.259, 0.0, -0.966)  # opposite of the light's travel direction
	disc.position = dir * 285.0 + Vector3(0, 285.0 * tan(deg_to_rad(Config.PHILLY_SUN_ELEVATION)), 0)
	add_child(disc)


# ------------------------------------------------------------------ Street furniture

func _streetlights() -> void:
	for side in [-1.0, 1.0]:
		var z := 50.0 if side > 0.0 else 37.0
		while z > WALK_END - 10.0:
			if not _in_cross_street(z, 1.0):
				_streetlight(side, z)
			z -= Config.STREETLIGHT_SPACING


func _streetlight(side: float, z: float) -> void:
	var x := side * 6.6
	box(Vector3(x, 3.0, z), Vector3(0.15, 6.0, 0.15), m_steel_dark)
	box(Vector3(x - side * 0.75, 6.0, z), Vector3(1.5, 0.1, 0.1), m_steel_dark, false)
	box(Vector3(x - side * 1.4, 5.92, z), Vector3(0.5, 0.14, 0.3), m_lamp, false)
	var l := OmniLight3D.new()
	l.position = Vector3(x - side * 1.4, 5.6, z)
	l.light_color = Config.STREETLIGHT_COLOR
	l.light_energy = Config.STREETLIGHT_ENERGY
	l.omni_range = Config.STREETLIGHT_RANGE
	add_child(l)


func _parked_cars() -> void:
	var colors := [Color(0.45, 0.12, 0.1), Color(0.2, 0.25, 0.35), Color(0.6, 0.6, 0.58),
		Color(0.15, 0.15, 0.16), Color(0.35, 0.33, 0.25), Color(0.25, 0.3, 0.25)]
	# [z, headlights on]; right side faces -Z, left side faces +Z
	for c in [[-16.0, false], [-31.0, false], [-58.0, true], [-73.0, false], [-90.0, false], [-118.0, false], [-160.0, false]]:
		_car(_root_at(Vector3(5.3, 0, c[0])), -1.0, colors[_rng.randi() % colors.size()], c[1], true)
	for c in [[4.0, false], [-27.0, true], [-60.0, false], [-72.0, false], [-88.0, true], [-120.0, false], [-133.0, false], [-162.0, false]]:
		_car(_root_at(Vector3(-5.3, 0, c[0])), 1.0, colors[_rng.randi() % colors.size()], c[1], true)


func _root_at(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	return n


## Builds a car inside `root`. facing: -1 = front toward -Z, +1 = front toward +Z.
func _car(root: Node3D, facing: float, color: Color, lights_on: bool, collide: bool) -> void:
	var body := Node3D.new()
	if facing > 0.0:
		body.rotation.y = PI
	root.add_child(body)
	var paint := mat("car", color, 1.0, false)
	box(Vector3(0, 0.62, 0), Vector3(1.8, 0.6, 4.4), paint, collide, body, 1.0)
	box(Vector3(0, 1.15, 0.3), Vector3(1.6, 0.5, 2.2), m_glass, false, body)
	box(Vector3(0, 1.42, 0.3), Vector3(1.62, 0.06, 2.0), paint, false, body)
	for wx in [-0.85, 0.85]:
		for wz in [-1.4, 1.4]:
			var wheel := cylinder(Vector3(wx, 0.33, wz), 0.33, 0.25, m_tire, body)
			wheel.rotation.z = PI * 0.5
	var head_mat := mat("plain", Color(1, 0.95, 0.8), 1.0, false, Color(1, 0.95, 0.8) if lights_on else Color.BLACK)
	var tail_mat := mat("plain", Color(0.6, 0.05, 0.05), 1.0, false, Color(0.7, 0.05, 0.03) if lights_on else Color.BLACK)
	for hx in [-0.6, 0.6]:
		box(Vector3(hx, 0.7, -2.21), Vector3(0.35, 0.14, 0.04), head_mat, false, body)
		box(Vector3(hx, 0.75, 2.21), Vector3(0.3, 0.12, 0.04), tail_mat, false, body)
	if lights_on:
		var spot := SpotLight3D.new()
		spot.position = Vector3(0, 0.7, -2.3)
		spot.rotation_degrees.x = -6.0
		spot.light_color = Color(1.0, 0.93, 0.78)
		spot.light_energy = Config.HEADLIGHT_ENERGY
		spot.spot_range = Config.HEADLIGHT_RANGE
		spot.spot_angle = 32.0
		body.add_child(spot)


func _street_props() -> void:
	var green := mat("metal", Color(0.2, 0.3, 0.22), 1.0)
	var red := mat("plain", Color(0.55, 0.1, 0.08), 1.0)
	var blue := mat("metal", Color(0.2, 0.25, 0.45), 1.0)
	# Trash can next to the pill bottle, and a few more
	for p in [Vector3(9.0, 0.12, -28.0), Vector3(-9.0, 0.12, -14.0), Vector3(9.0, 0.12, -64.0), Vector3(-9.0, 0.12, -96.0)]:
		cylinder(p + Vector3(0, 0.45, 0), 0.3, 0.9, green)
		invisible_wall(p + Vector3(0, 0.5, 0), Vector3(0.6, 1.0, 0.6))
	# Fire hydrants
	for p in [Vector3(6.6, 0.12, -10.0), Vector3(-6.6, 0.12, -78.0)]:
		cylinder(p + Vector3(0, 0.3, 0), 0.13, 0.6, red)
		cylinder(p + Vector3(0, 0.62, 0), 0.09, 0.08, red)
	# Mailbox
	box(Vector3(-9.2, 0.75, -36.0), Vector3(0.5, 1.2, 0.5), blue)
	# Newspaper boxes
	for p in [Vector3(9.3, 0.12, -6.0), Vector3(9.3, 0.12, -6.6)]:
		box(p + Vector3(0, 0.5, 0), Vector3(0.45, 1.0, 0.45), blue if p.z > -6.3 else red)


func _bus_stop() -> void:
	var glass := mat("plain", Color(0.15, 0.17, 0.18), 1.0)
	box(Vector3(9.0, 2.5, 1.2), Vector3(1.7, 0.08, 4.2), m_steel)               # roof
	box(Vector3(9.8, 1.3, 1.2), Vector3(0.05, 2.3, 4.0), glass)                  # back panel
	for dz in [-0.85, 3.25]:
		box(Vector3(8.2, 1.25, dz), Vector3(0.08, 2.5, 0.08), m_steel)          # posts
	box(Vector3(9.45, 0.5, 1.2), Vector3(0.45, 0.06, 2.6), m_wood)               # bench
	# Lit advert panel at the front end of the shelter
	var ad := mat("plain", Color(0.85, 0.85, 0.8), 1.0, true, Color(0.6, 0.6, 0.55))
	box(Vector3(9.0, 1.3, -0.95), Vector3(1.4, 1.9, 0.08), ad)
	sign_text("YOU ARE NOT ALONE", Vector3(9.0, 1.7, -0.89), 0, 20, Color(0.2, 0.25, 0.3))
	sign_text("Call 1-800-662-HELP", Vector3(9.0, 1.3, -0.89), 0, 14, Color(0.2, 0.25, 0.3))
	# Bus stop sign
	box(Vector3(6.9, 1.4, -1.5), Vector3(0.07, 2.8, 0.07), m_steel_dark)
	box(Vector3(6.9, 2.6, -1.5), Vector3(0.04, 0.5, 0.5), mat("plain", Color(0.2, 0.3, 0.6), 1.0), false)
	sign_text("BUS", Vector3(6.87, 2.6, -1.5), -90, 24, Color(0.95, 0.95, 0.9))
	var l := OmniLight3D.new()
	l.position = Vector3(9.0, 2.3, 1.2)
	l.light_color = Color(0.85, 0.9, 1.0)
	l.light_energy = 0.8
	l.omni_range = 5.0
	add_child(l)


func _steam(pos: Vector3) -> void:
	cylinder(pos + Vector3(0, 0.01, 0), 0.4, 0.02, m_steel_dark)
	var p := CPUParticles3D.new()
	p.position = pos + Vector3(0, 0.1, 0)
	p.amount = 18
	p.lifetime = 3.5
	p.preprocess = 3.5
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.3
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.1
	p.gravity = Vector3(0.3, 0.15, 0)
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.3
	var curve := Curve.new()
	curve.max_value = 3.0
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 2.4))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0))
	grad.set_color(1, Color(1, 1, 1, 0))
	grad.add_point(0.2, Color(1, 1, 1, 0.35))
	p.color_ramp = grad
	var quad := QuadMesh.new()
	quad.size = Vector2(1.2, 1.2)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = Tex.get_texture("puff")
	m.albedo_color = Color(0.85, 0.75, 0.65)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	quad.material = m
	p.mesh = quad
	add_child(p)


func _boundaries() -> void:
	invisible_wall(Vector3(0, 5, WALK_START + 0.5), Vector3(2 * FRONT, 10, 1))
	invisible_wall(Vector3(0, 5, WALK_END - 0.5), Vector3(2 * FRONT, 10, 1))
	for cs in CROSS_STREETS:
		for side in [-1.0, 1.0]:
			invisible_wall(Vector3(side * 30.0, 5, (cs[0] + cs[1]) * 0.5), Vector3(1, 10, 14))


func _ambience() -> void:
	var traffic := AudioStreamPlayer.new()
	traffic.stream = Audio.traffic()
	traffic.volume_db = Config.TRAFFIC_DB
	traffic.autoplay = true
	add_child(traffic)

	_siren = AudioStreamPlayer3D.new()
	_siren.stream = Audio.siren()
	_siren.volume_db = Config.SIREN_DB
	_siren.unit_size = 40.0
	_siren.max_distance = 500.0
	add_child(_siren)


# ------------------------------------------------------------------ Moving things

func _spawn_bus() -> void:
	var bus := Mover.new()
	bus.position = Vector3(3.2, 0, -5.0)
	bus.direction = -1.0
	bus.max_speed = Config.BUS_MAX_SPEED
	bus.acceleration = Config.BUS_ACCELERATION
	bus.delay = Config.BUS_DEPART_DELAY
	bus.end_z = STREET_END - 20.0
	add_child(bus)
	var paint := mat("car", Color(0.75, 0.75, 0.72), 1.0, false)
	var stripe := mat("plain", Color(0.2, 0.3, 0.6), 1.0, false)
	var windows := mat("plain", Color(0.8, 0.75, 0.55), 1.0, false, Color(0.5, 0.45, 0.3))
	box(Vector3(0, 1.7, 0), Vector3(2.6, 2.8, 12.0), paint, false, bus, 1.0)
	box(Vector3(0, 2.1, 0), Vector3(2.62, 0.9, 10.5), windows, false, bus)
	box(Vector3(0, 1.0, 0), Vector3(2.62, 0.25, 12.0), stripe, false, bus)
	for wz in [-4.0, 4.0]:
		for wx in [-1.2, 1.2]:
			var wheel := cylinder(Vector3(wx, 0.5, wz), 0.5, 0.3, m_tire, bus)
			wheel.rotation.z = PI * 0.5
	var tail := mat("plain", Color(0.7, 0.05, 0.03), 1.0, false, Color(0.9, 0.08, 0.04))
	for tx in [-1.0, 1.0]:
		box(Vector3(tx, 0.9, 6.01), Vector3(0.3, 0.3, 0.04), tail, false, bus)
	var rear_sign := mat("plain", Color(0.1, 0.1, 0.1), 1.0)
	box(Vector3(0, 2.9, 6.01), Vector3(1.4, 0.35, 0.04), rear_sign, false, bus)
	sign_text("23", Vector3(0, 2.9, 6.05), 0, 32, Color(1.0, 0.7, 0.2), bus)
	var engine := AudioStreamPlayer3D.new()
	engine.stream = Audio.rumble()
	engine.volume_db = -14.0
	engine.unit_size = 8.0
	engine.autoplay = true
	bus.add_child(engine)


func _spawn_car() -> void:
	var car := Mover.new()
	car.position = Vector3(-2.2, 0, STREET_END)
	car.direction = 1.0
	car.max_speed = Config.CAR_SPEED
	car.end_z = STREET_START
	add_child(car)
	var colors := [Color(0.3, 0.3, 0.32), Color(0.5, 0.15, 0.1), Color(0.15, 0.2, 0.3)]
	_car(car, 1.0, colors[_rng.randi() % colors.size()], true, false)
	var engine := AudioStreamPlayer3D.new()
	engine.stream = Audio.traffic()
	engine.volume_db = 0.0
	engine.unit_size = 6.0
	engine.autoplay = true
	car.add_child(engine)


func _spawn_train(dir: float) -> void:
	var train := Mover.new()
	var x := -1.5 if dir < 0.0 else 1.5
	var start := STREET_START + 90.0 if dir < 0.0 else STREET_END - 90.0
	train.position = Vector3(x, DECK_Y + 0.9, start)
	train.direction = dir
	train.max_speed = Config.TRAIN_SPEED
	train.end_z = STREET_END - 100.0 if dir < 0.0 else STREET_START + 100.0
	add_child(train)
	_trains.append(train)

	var silver := mat("metal", Color(0.75, 0.75, 0.72), 1.0)
	var lit := mat("plain", Color(0.9, 0.85, 0.65), 1.0, false, Color(0.7, 0.65, 0.45))
	var car_len := 14.0
	for i in Config.TRAIN_CARS:
		var cz := (i - (Config.TRAIN_CARS - 1) * 0.5) * (car_len + 0.6)
		box(Vector3(0, 1.6, cz), Vector3(2.9, 3.1, car_len), silver, false, train, 2.0)
		box(Vector3(0, 2.0, cz), Vector3(2.92, 0.9, car_len - 1.5), lit, false, train)
		box(Vector3(0, 0.3, cz), Vector3(2.4, 0.6, car_len - 2.0), m_steel_dark, false, train)
	var front := SpotLight3D.new()
	front.position = Vector3(0, 1.4, dir * (Config.TRAIN_CARS * (car_len + 0.6) * 0.5 + 0.1))
	front.rotation.y = 0.0 if dir < 0.0 else PI
	front.light_color = Color(1.0, 0.95, 0.85)
	front.light_energy = 2.5
	front.spot_range = 30.0
	front.spot_angle = 25.0
	train.add_child(front)

	var rumble := AudioStreamPlayer3D.new()
	rumble.stream = Audio.rumble()
	rumble.bus = Settings.LOUD_BUS
	rumble.volume_db = Config.TRAIN_RUMBLE_DB
	rumble.unit_size = 18.0
	rumble.max_distance = 260.0
	rumble.autoplay = true
	train.add_child(rumble)
