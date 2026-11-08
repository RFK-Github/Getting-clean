extends "res://scripts/levels/level_base.gd"
## LEVEL 2: The recovery center.
##
## Map (top view, -Z is north; every room is a rectangle with its walls on the inside):
##   Lobby + exit        x  -8..8,   z -12..0    (exit doors on the south wall, doctor beside them)
##   Main hall (N-S)     x  -2..2,   z -52..-12  (schedule board on the east wall)
##   Group therapy       x -14..-2,  z -28..-12  (door at z -18)
##   Doctor's office     x   2..10,  z -28..-12  (door at z -18)
##   West hall (rooms)   x -32..-2,  z -32..-28  (rooms 10-12 south, 13-15 north)
##   Room 11             x -26..-20, z -28..-20  (another patient)
##   Room 12 (player)    x -20..-14, z -28..-20  (bed, mirror, clipboard)
##   East hall           x   2..20,  z -32..-28
##   Nurses' station     x  10..18,  z -28..-22
##   Common room         x   2..18,  z -46..-32
##   Pool                x  20..40,  z -46..-14
##   Courtyard (outdoor) x -12..12,  z -76..-52  (basketball hoop)
##   Lawn (outdoor)      x -44..-12, z -84..-52  (football goal)

const Npc := preload("res://scripts/npc.gd")
const Mirror := preload("res://scripts/props/mirror.gd")
const Audio := preload("res://scripts/audio.gd")

const H := 3.0          # ceiling height
const T := 0.2          # wall thickness
const DOOR_H := 2.2
const OUT_H := 4.0      # outdoor wall height

var m_floor: ShaderMaterial
var m_wall: ShaderMaterial
var m_ceiling: ShaderMaterial
var m_metal: ShaderMaterial
var m_dark: ShaderMaterial
var m_wood: ShaderMaterial
var m_fabric: ShaderMaterial
var m_sheet: ShaderMaterial
var m_white: ShaderMaterial
var m_window: ShaderMaterial
var m_lamp: ShaderMaterial
var m_concrete: ShaderMaterial
var m_door: ShaderMaterial
var m_sign: ShaderMaterial
var m_green: ShaderMaterial

var _flicker: Array[OmniLight3D] = []
var _lobby_spawn := Transform3D.IDENTITY
var _fakes: Array[Node3D] = []
var _push_window := 0.0   # time left to press E again at the exit and push past the doctor

## The five personal items: where the real one is, and where fake copies appear under the influence.
const ITEMS := [
	{"id": "drawing", "prompt": "A child's drawing", "pos": Vector3(-6.28, 0.485, -18.62), "rot": 20.0,
		"fakes": [Vector3(6.0, 0.775, -41.0), Vector3(-7.3, 0.485, -5.0)],
		"message": "A child's drawing. A big figure and a small one, holding hands under a yellow sun. Your chest tightens. You don't know why."},
	{"id": "photo", "prompt": "A photo", "pos": Vector3(7.5, 0.78, -14.7), "rot": -15.0,
		"fakes": [Vector3(13.0, 1.15, -27.0), Vector3(-24.9, 0.63, -22.0)],
		"message": "A creased photo. You, your wife, and a little girl on your shoulders, laughing. You look at the girl for a long time."},
	{"id": "teddy", "prompt": "A teddy bear", "pos": Vector3(11.4, 0.48, -60.3), "rot": -90.0,
		"fakes": [Vector3(-41.0, 0.0, -62.0), Vector3(-31.2, 0.0, -29.3)],
		"message": "A worn teddy bear with one button eye. You've held it before. Smaller hands used to hold it too."},
	{"id": "bracelet", "prompt": "A bracelet", "pos": Vector3(21.2, 0.0, -43.5), "rot": 0.0,
		"fakes": [Vector3(-1.2, 0.0, -48.0), Vector3(4.2, 1.15, -7.6)],
		"message": "Plastic beads on elastic. The letters spell D-A-D. It's far too small for your wrist."},
	{"id": "ring", "prompt": "A ring", "pos": Vector3(-14.45, 0.93, -24.25), "rot": 0.0,
		"fakes": [Vector3(-17.95, 0.6, -20.55), Vector3(6.0, 0.775, -36.0)],
		"message": "Your wedding ring. You don't remember taking it off. You put it back on. It still fits."},
]

## The wife's letters. They get shorter and colder.
const LETTERS := [
	{"id": "letter_1", "pos": Vector3(-17.95, 0.6, -20.55),
		"text": "My love,\n\nThe house is so quiet. Some nights I still set the table for three, and then I just sit there.\n\nI'm not angry. I just need you to come back to me. Get well. I'll be here.\n\nAll my love,\nC."},
	{"id": "letter_2", "pos": Vector3(5.6, 1.15, -7.4),
		"text": "Hi,\n\nThe doctor says you have good days and bad days. I came once, but they said you didn't know who I was.\n\nPlease get better.\n\nC."},
	{"id": "letter_3", "pos": Vector3(9.6, 1.31, -20.0),
		"text": "I don't know if you read these. Write back if you can.\n\nC."},
	{"id": "letter_4", "pos": Vector3(6.3, 0.775, -41.2),
		"text": "I need to tell you something when I visit. Please be clean.\n\nC."},
]


func get_settings() -> Dictionary:
	var arrived := Game.previous_level == "philadelphia"
	var start := "You wake up in your room. The lights hum. " + Recovery.days_text()
	if arrived:
		start = "The nurse at reception hands you a wristband. \"Room 12. West hall. Try to get some rest.\" " + Recovery.days_text()
	elif Game.wake_message != "":
		start = Game.wake_message
	return {
		"fog_mode": "exponential",
		"fog_color": Config.HOSPITAL_FOG_COLOR,
		"fog_density": Config.HOSPITAL_FOG_DENSITY,
		"ambient_color": Config.HOSPITAL_AMBIENT_COLOR,
		"ambient_energy": Config.HOSPITAL_AMBIENT_ENERGY,
		"tint": Config.HOSPITAL_TINT_COLOR,
		"tint_strength": Config.HOSPITAL_TINT_STRENGTH,
		"camera_far": Config.HOSPITAL_CAMERA_FAR,
		"flashlight_on": false,
		"hallucinations": true,
		"episodes": true,
		"navigation": true,
		"withdrawal_rate": Config.HOSPITAL_WITHDRAWAL_RATE,
		"start_message": start,
	}


func build() -> void:
	_make_materials()
	# One flat collider under the whole building and grounds.
	invisible_wall(Vector3(0, -0.5, -40), Vector3(100, 1, 100))

	_lobby()
	_main_hall()
	_therapy_room()
	_office()
	_west_hall()
	_room_11()
	_room_12()
	_east_hall()
	_nurses_station()
	_common_room()
	_pool()
	_courtyard()
	_lawn()
	_hidden_pills()
	_items_and_letters()

	var hum := AudioStreamPlayer.new()
	hum.stream = Audio.hum()
	hum.volume_db = Config.AMBIENT_HUM_DB
	hum.autoplay = true
	add_child(hum)

	spawn = _lobby_spawn if Game.previous_level == "philadelphia" else bed_spawn
	Game.wake_message = ""


func _process(delta: float) -> void:
	for l in _flicker:
		if randf() < Config.LAMP_FLICKER_CHANCE:
			l.light_energy = randf_range(0.0, Config.LAMP_ENERGY * 0.3)
		else:
			l.light_energy = lerpf(l.light_energy, Config.LAMP_ENERGY, 0.2)

	_push_window = maxf(0.0, _push_window - delta)

	# Under the influence, fake copies of the missing items appear. They go when it wears off.
	_fakes = _fakes.filter(func(n): return is_instance_valid(n))
	if Withdrawal.is_influenced() and _fakes.is_empty():
		_spawn_fakes()
	elif not Withdrawal.is_influenced() and not _fakes.is_empty():
		for n in _fakes:
			n.queue_free()
		_fakes.clear()


# ------------------------------------------------------------------ Items, letters, exit

func _items_and_letters() -> void:
	for it in ITEMS:
		if it["id"] in Withdrawal.taken_pickups:
			continue
		var p := _item_pickup(it, "item")
		p.message = it["message"]
	for l in LETTERS:
		if l["id"] in Withdrawal.taken_pickups:
			continue
		var p := Pickup.new()
		p.kind = "letter"
		p.item_id = l["id"]
		p.prompt = "A letter"
		p.title = "A LETTER FROM YOUR WIFE"
		p.message = l["text"]
		p.shape_size = Vector3(0.4, 0.25, 0.4)
		p.position = l["pos"]
		p.rotation.y = randf_range(-0.4, 0.4)
		var envelope := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(0.22, 0.12)
		plane.material = mat("plain", Color(0.92, 0.9, 0.84), 1.0, false, Color(0.08, 0.08, 0.07))
		envelope.mesh = plane
		envelope.position.y = 0.005
		p.add_child(envelope)
		add_child(p)


func _spawn_fakes() -> void:
	for it in ITEMS:
		if it["id"] in Withdrawal.found_items:
			continue
		var spots: Array = it["fakes"]
		for i in mini(Config.FAKE_COPIES_PER_ITEM, spots.size()):
			var fake_item: Dictionary = it.duplicate()
			fake_item["pos"] = spots[i]
			_fakes.append(_item_pickup(fake_item, "fake"))


func _item_pickup(it: Dictionary, kind: String) -> Pickup:
	var p := Pickup.new()
	p.kind = kind
	p.item_id = it["id"]
	p.prompt = it["prompt"]
	p.position = it["pos"]
	p.rotation_degrees.y = it["rot"]
	p.shape_size = Vector3(0.45, 0.35, 0.45)
	p.add_child(_item_visual(it["id"]))
	add_child(p)
	return p


func _item_visual(id: String) -> Node3D:
	var root := Node3D.new()
	var glint := Color(0.08, 0.07, 0.05)   # a faint glow so they can be found
	match id:
		"drawing", "photo":
			var plane := PlaneMesh.new()
			plane.size = Vector2(0.3, 0.21) if id == "drawing" else Vector2(0.1, 0.125)
			plane.material = mat(id, Color.WHITE, 1.0, false, glint)
			var mi := MeshInstance3D.new()
			mi.mesh = plane
			mi.position.y = 0.006
			root.add_child(mi)
		"teddy":
			var fur := mat("fabric", Color(1.6, 1.1, 0.7), 3.0, false, glint)
			box(Vector3(0, 0.1, 0), Vector3(0.17, 0.2, 0.13), fur, false, root)
			box(Vector3(0, 0.26, 0), Vector3(0.14, 0.13, 0.12), fur, false, root)
			for sx in [-0.06, 0.06]:
				box(Vector3(sx, 0.34, 0), Vector3(0.04, 0.04, 0.03), fur, false, root)       # ears
				box(Vector3(sx * 1.7, 0.13, -0.02), Vector3(0.05, 0.12, 0.05), fur, false, root)  # arms
			box(Vector3(0.03, 0.28, -0.061), Vector3(0.02, 0.02, 0.01), m_dark, false, root)  # one button eye
		"bracelet", "ring":
			var torus := TorusMesh.new()
			if id == "bracelet":
				torus.inner_radius = 0.03
				torus.outer_radius = 0.04
				torus.material = mat("plain", Color(0.9, 0.5, 0.7), 1.0, false, glint)
			else:
				torus.inner_radius = 0.009
				torus.outer_radius = 0.013
				torus.material = mat("plain", Color(0.9, 0.75, 0.3), 1.0, false, Color(0.35, 0.28, 0.1))
			torus.rings = 10
			torus.ring_segments = 4
			var mi := MeshInstance3D.new()
			mi.mesh = torus
			mi.position.y = 0.01
			root.add_child(mi)
			if id == "bracelet":
				for i in 6:
					var a := TAU * i / 6.0
					var bead_color: Color = [Color(0.9, 0.9, 0.2), Color(0.3, 0.6, 0.9), Color(0.9, 0.3, 0.3)][i % 3]
					box(Vector3(cos(a) * 0.035, 0.012, sin(a) * 0.035), Vector3(0.014, 0.014, 0.014),
						mat("plain", bead_color, 1.0, false, glint), false, root)
	return root


## The exit door: the doctor decides. Press E again within a few seconds to push past him.
func _on_exit() -> void:
	if Recovery.recovery >= Config.RECOVERY_MAX:
		Withdrawal.post_message("Dr. Reyes: \"You're ready.\"")
		Game.good_ending()
		return
	if _push_window > 0.0:
		_push_window = 0.0
		Recovery.next_day("forced")
		return
	var line := "You're not ready." if Recovery.recovery < Config.EXIT_CLOSER_THRESHOLD \
		else "Not yet. You're getting closer."
	Withdrawal.post_message("Dr. Reyes: \"%s\"     (E again: push past him)" % line)
	_push_window = Config.FORCE_EXIT_WINDOW


func _make_materials() -> void:
	m_floor = mat("linoleum", Color.WHITE, 0.5)
	m_wall = mat("white_wall", Color.WHITE, 0.5)
	m_ceiling = mat("ceiling", Color(1.3, 1.3, 1.3), 0.5)
	m_metal = mat("metal", Color(1.3, 1.3, 1.3), 1.0)
	m_dark = mat("metal", Color(0.35, 0.35, 0.35), 1.0)
	m_wood = mat("wood", Color(1.2, 1.15, 1.1), 1.0)
	m_fabric = mat("fabric", Color(1.2, 1.4, 1.3), 1.5)
	m_sheet = mat("plain", Color(0.88, 0.9, 0.88), 1.0)
	m_white = mat("plain", Color(0.85, 0.86, 0.84), 1.0)
	m_window = mat("plain", Color(0.85, 0.9, 0.88), 1.0, true, Color(0.7, 0.75, 0.72))
	m_lamp = mat("plain", Config.LAMP_COLOR, 1.0, true, Config.LAMP_COLOR)
	m_concrete = mat("concrete", Color.WHITE, 0.5)
	m_door = mat("door", Color(1.6, 1.7, 1.75), 0.8)
	m_sign = mat("plain", Color(0.15, 0.25, 0.45), 1.0)
	m_green = mat("plain", Color(0.1, 0.45, 0.2), 1.0, true, Color(0.05, 0.3, 0.1))


# ------------------------------------------------------------------ Rooms

func _lobby() -> void:
	room(-8, 8, -12, 0, m_floor, {"s": [[0.0, 3.0]], "n": [[0.0, 3.0]]})
	lamp(Vector3(-4, 0, -6))
	lamp(Vector3(4, 0, -6))

	# Exit doors (closed) with daylight behind them
	var daylight := mat("plain", Color(0.9, 0.93, 0.9), 1.0, true, Color(0.75, 0.8, 0.75))
	box(Vector3(0, DOOR_H * 0.5, -0.1), Vector3(3.0, DOOR_H, 0.08), daylight)
	box(Vector3(0, DOOR_H * 0.5, -0.15), Vector3(0.08, DOOR_H, 0.04), m_dark, false)
	hsign("EXIT", Vector3(0, 2.6, -0.22), 180, m_green)
	var exit := Pickup.new()
	exit.kind = "action"
	exit.prompt = "Exit"
	exit.action = _on_exit
	exit.shape_size = Vector3(3.0, 2.2, 0.6)
	exit.position = Vector3(0, 0, -0.5)
	add_child(exit)

	# Reception desk
	box(Vector3(5, 0.55, -7.5), Vector3(3.5, 1.1, 0.7), m_wood)
	box(Vector3(5, 1.12, -7.5), Vector3(3.7, 0.05, 0.9), m_white, false)
	box(Vector3(5.8, 1.3, -7.6), Vector3(0.5, 0.35, 0.05), m_dark, false)   # monitor
	hsign("RECEPTION", Vector3(5, 2.3, -11.77), 0)

	# Waiting area
	for i in 5:
		chair(Vector3(-7.3, 0, -3.0 - i * 1.0), -PI * 0.5)
	plant(Vector3(-7.2, 0, -11.2))
	plant(Vector3(7.2, 0, -11.2))
	wheelchair(Vector3(6.6, 0, -1.6), PI * 0.3)
	sign_text("Recovery is not a straight line.", Vector3(-7.77, 2.0, -6.5), 90, 20, Color(0.3, 0.35, 0.4))

	npc("doctor", Vector3(1.9, 0, -1.4), 0.0, ["If you think you're ready, come and tell me at the door.", "Nobody leaves until they're ready. That's the deal."], "Dr. Reyes")
	npc("nurse", Vector3(5, 0, -8.6), PI, ["Your room is number twelve, west hall.", "If you need anything, the nurses' station is in the east hall."], "Nurse Kim")

	_lobby_spawn = Transform3D(Basis.IDENTITY, Vector3(0, 0.05, -2.6))


func _main_hall() -> void:
	room(-2, 2, -52, -12, m_floor, {
		"s": [[0.0, 3.0]], "n": [[0.0, 2.4]],
		"w": [[-18.0, 1.4], [-30.0, 4.0]], "e": [[-18.0, 1.2], [-30.0, 4.0]]})
	lamp(Vector3(0, 0, -16))
	lamp(Vector3(0, 0, -30))
	lamp(Vector3(0, 0, -44))

	hsign("GROUP THERAPY", Vector3(-1.77, 2.45, -18), 90)
	hsign("DR. OFFICE", Vector3(1.77, 2.45, -18), -90)
	hsign("< ROOMS   COMMON ROOM / POOL >", Vector3(0, 2.65, -27.6), 0)
	hsign("COURTYARD  -  LAWN", Vector3(0, 2.6, -51.77), 0)

	# Daily schedule board
	box(Vector3(1.77, 1.55, -24.6), Vector3(0.05, 1.1, 1.5), mat("cork", Color.WHITE, 1.0, false))
	sign_text(_schedule_board_text(), Vector3(1.74, 1.55, -24.6), -90, 12, Color(0.12, 0.12, 0.14))
	var board := Pickup.new()
	board.kind = "read"
	board.prompt = "Daily schedule"
	board.title = "DAILY SCHEDULE"
	board.text_source = _schedule_text
	board.shape_size = Vector3(0.3, 1.2, 1.5)
	board.position = Vector3(1.6, 0.95, -24.6)
	add_child(board)

	bench(Vector3(-1.55, 0, -38), PI * 0.5)
	wheelchair(Vector3(-1.3, 0, -46), PI * 0.5)
	iv_stand(Vector3(1.5, 0, -41))
	box(Vector3(1.7, 0.5, -35), Vector3(0.4, 1.0, 0.4), m_metal)   # water fountain

	npc("nurse", Vector3(0.4, 0, -14), 0.0, ["Keep moving. It helps with the shakes.", "Drink some water. Your body needs it."], "Nurse Ortiz",
		[Vector3(0.4, 0, -14), Vector3(0.4, 0, -30), Vector3(14, 0, -30)])


func _therapy_room() -> void:
	room(-14, -2, -28, -12, m_floor, {"e": [[-18.0, 1.4]]})
	lamp(Vector3(-8, 0, -20))
	box(Vector3(-8, 1.6, -27.77), Vector3(2.4, 1.2, 0.04), m_sheet, false)
	sign_text("HOW ARE YOU, REALLY?", Vector3(-8, 1.75, -27.74), 0, 24, Color(0.2, 0.3, 0.6))
	sign_text("one day at a time", Vector3(-8, 1.4, -27.74), 0, 16, Color(0.3, 0.3, 0.3))

	var center := Vector3(-8, 0, -20)
	var seats := 7
	var people := {
		0: ["therapist", "Maria", ["Group is at eleven. Your chair will be here.", "Nobody in this circle is judging you. We've all been where you are."]],
		2: ["patient", "Dee", ["...", "First week is the worst. Then it's just... long."]],
		4: ["patient", "Marcus", ["I keep dreaming about it. Every night."]],
		5: ["patient", "Ray", ["They say talking helps. I'm still waiting."]],
	}
	for i in seats:
		var a := TAU * i / seats
		var pos := center + Vector3(sin(a), 0, cos(a)) * 2.2
		var yaw := atan2(sin(a), cos(a))  # face the middle of the circle
		chair(pos, yaw)
		if people.has(i):
			var p: Array = people[i]
			var n := npc(p[0], pos, yaw, p[2], p[1])
			n.pose = "sit"
			if p[0] == "therapist":
				n.dialogue_id = "group"
				n.prompt = "Join group therapy"


func _office() -> void:
	room(2, 10, -28, -12, m_floor, {"w": [[-18.0, 1.2]]})
	lamp(Vector3(6, 0, -20))
	box(Vector3(7, 0.74, -14.6), Vector3(2.0, 0.08, 0.9), m_wood)
	box(Vector3(7.8, 0.36, -14.6), Vector3(0.45, 0.72, 0.85), m_wood, false)
	box(Vector3(6.2, 0.36, -14.6), Vector3(0.05, 0.72, 0.85), m_wood, false)
	box(Vector3(6.6, 0.95, -14.4), Vector3(0.5, 0.35, 0.05), m_dark, false)   # monitor
	chair(Vector3(7, 0, -13.6), 0.0)
	chair(Vector3(6.4, 0, -15.8), PI)
	chair(Vector3(7.6, 0, -15.8), PI)
	box(Vector3(9.6, 0.65, -20), Vector3(0.6, 1.3, 0.6), m_metal)              # filing cabinet
	box(Vector3(9.65, 1.0, -24), Vector3(0.5, 2.0, 2.0), m_wood)               # bookshelf
	for i in 3:
		box(Vector3(2.22, 1.7, -14.5 - i * 0.7), Vector3(0.04, 0.4, 0.5), m_wood, false)  # diplomas
	plant(Vector3(2.6, 0, -27.4))
	var adler := npc("doctor", Vector3(7.0, 0, -16.6), 0.0, ["One day at a time. I know it sounds like a poster.", "We'll talk properly at your round."], "Dr. Adler",
		[Vector3(7.0, 0, -16.6), Vector3(8.6, 0, -25.5)])
	adler.dialogue_id = "doctor"


func _west_hall() -> void:
	room(-32, -2, -32, -28, m_floor, {
		"e": [[-30.0, 4.0]],
		"s": [[-21.0, 1.2], [-15.0, 1.2]]})
	lamp(Vector3(-6, 0, -30))
	lamp(Vector3(-16, 0, -30), true)
	lamp(Vector3(-26, 0, -30))
	box(Vector3(-31.77, 1.6, -30), Vector3(0.04, 1.2, 2.4), m_window, false)

	# Room numbers and the closed doors of the other rooms
	room_number("10", -27.0, true)
	room_number("11", -21.0, true)
	room_number("12", -15.0, true)
	room_number("13", -27.0, false)
	room_number("14", -21.0, false)
	room_number("15", -15.0, false)
	closed_door(Vector3(-27.0, 0, -28.18), 180, "Room 10", "Locked. Someone is crying inside.")
	closed_door(Vector3(-27.0, 0, -31.82), 0, "Room 13", "Locked.")
	closed_door(Vector3(-21.0, 0, -31.82), 0, "Room 14", "Locked.")
	closed_door(Vector3(-15.0, 0, -31.82), 0, "Room 15", "Locked. The name tag has been peeled off.")

	box(Vector3(-10, 0.5, -31.5), Vector3(0.9, 1.0, 0.5), m_metal)     # med cart
	iv_stand(Vector3(-30.5, 0, -31.4))
	npc("patient", Vector3(-30.5, 0, -30.2), 0.0, ["They never turn these lights off.", "Rough night?"], "",
		[Vector3(-30.5, 0, -30.2), Vector3(-4.5, 0, -30.2)])


func _room_11() -> void:
	room(-26, -20, -28, -20, m_floor, {"n": [[-21.0, 1.2]]})
	lamp(Vector3(-23, 0, -24), false, 0.4)
	hospital_bed(Vector3(-24.9, 0, -21.25), 0.0)
	iv_stand(Vector3(-23.9, 0, -20.7))
	box(Vector3(-23, 1.6, -20.22), Vector3(1.4, 1.1, 0.04), m_window, false)
	var p := npc("patient", Vector3(-24.9, 0, -21.25), 0.0, ["Close the door on your way out.", "Leave me alone. Please."], "")
	p.pose = "lie"


func _room_12() -> void:
	room(-20, -14, -28, -20, m_floor, {"n": [[-15.0, 1.2]]})
	lamp(Vector3(-17, 0, -24), false, 0.6)

	hospital_bed(Vector3(-18.9, 0, -21.25), 0.0)
	iv_stand(Vector3(-17.9, 0, -22.6))
	box(Vector3(-17.95, 0.3, -20.55), Vector3(0.5, 0.6, 0.45), m_wood)          # nightstand
	box(Vector3(-16.5, 1.6, -20.22), Vector3(1.4, 1.1, 0.04), m_window, false)  # frosted window
	box(Vector3(-19.45, 1.0, -26.6), Vector3(0.6, 2.0, 1.0), m_wood)            # wardrobe
	chair(Vector3(-15.2, 0, -21.2), PI * 0.75)

	# Clipboard at the foot of the bed
	box(Vector3(-18.9, 0.92, -22.36), Vector3(0.24, 0.32, 0.02), m_wood, false)
	box(Vector3(-18.9, 0.92, -22.375), Vector3(0.2, 0.26, 0.01), m_sheet, false)
	var clip := Pickup.new()
	clip.kind = "read"
	clip.prompt = "Clipboard"
	clip.title = "PATIENT CHART - ROOM 12"
	clip.text_source = _chart_text
	clip.shape_size = Vector3(0.6, 0.5, 0.3)
	clip.position = Vector3(-18.9, 0.65, -22.5)
	add_child(clip)

	# Sink and mirror on the east wall
	box(Vector3(-14.45, 0.85, -24.5), Vector3(0.5, 0.15, 0.6), m_white)
	box(Vector3(-14.4, 0.4, -24.5), Vector3(0.2, 0.8, 0.25), m_white, false)
	box(Vector3(-14.19, 1.6, -24.5), Vector3(0.02, 0.9, 0.74), m_dark, false)   # mirror frame
	var mirror := Mirror.new()
	mirror.position = Vector3(-14.17, 1.6, -24.5)
	mirror.rotation.y = -PI * 0.5   # faces -X, into the room
	add_child(mirror)

	# Wake up standing beside the bed, facing the door.
	var pos := Vector3(-17.6, 0.05, -22.2)
	var to_door := Vector3(-15, 0, -28) - pos
	bed_spawn = Transform3D(Basis(Vector3.UP, atan2(-to_door.x, -to_door.z)), pos)


func _east_hall() -> void:
	room(2, 20, -32, -28, m_floor, {
		"w": [[-30.0, 4.0]], "n": [[8.0, 2.4]], "s": [[14.0, 6.0]], "e": [[-30.0, 2.4]]})
	lamp(Vector3(6, 0, -30))
	lamp(Vector3(15, 0, -30))
	hsign("COMMON ROOM", Vector3(8, 2.45, -31.77), 0)
	hsign("NURSES' STATION", Vector3(14, 2.45, -28.23), 180)
	hsign("POOL", Vector3(19.77, 2.6, -30), -90)


func _nurses_station() -> void:
	room(10, 18, -28, -22, m_floor, {"n": [[14.0, 6.0]]})
	lamp(Vector3(14, 0, -25))
	box(Vector3(14, 0.55, -27.0), Vector3(5.0, 1.1, 0.5), m_wood)
	box(Vector3(14, 1.12, -27.0), Vector3(5.2, 0.05, 0.7), m_white, false)
	box(Vector3(12.8, 1.3, -26.9), Vector3(0.5, 0.35, 0.05), m_dark, false)
	box(Vector3(14, 1.4, -22.35), Vector3(4.0, 1.8, 0.3), m_metal)            # medicine cabinets
	chair(Vector3(15.5, 0, -25.8), 0.0)
	var bell := npc("nurse", Vector3(14, 0, -26.1), 0.0, ["Medication is handed out here. Nothing for you yet, sorry.", "Try to eat something at dinner."], "Nurse Bell")
	bell.dialogue_id = "nurse"


func _common_room() -> void:
	room(2, 18, -46, -32, m_floor, {"s": [[8.0, 2.4]]})
	lamp(Vector3(6, 0, -39))
	lamp(Vector3(14, 0, -39))
	for x in [5.0, 10.0, 15.0]:
		box(Vector3(x, 1.6, -45.77), Vector3(2.0, 1.2, 0.04), m_window, false)

	table(Vector3(6, 0, -36), Vector2(1.6, 1.0))
	chair(Vector3(5.5, 0, -35.1), 0.0)
	chair(Vector3(6.5, 0, -36.9), PI)
	table(Vector3(6, 0, -41), Vector2(1.6, 1.0))
	chair(Vector3(5.5, 0, -40.1), 0.0)
	# Sofas facing the TV
	sofa(Vector3(14, 0, -36), 0.0)
	sofa(Vector3(17.2, 0, -40), PI * 0.5)
	box(Vector3(14, 0.35, -44.9), Vector3(1.8, 0.7, 0.5), m_wood)        # TV stand
	box(Vector3(14, 1.0, -44.9), Vector3(1.2, 0.7, 0.3), m_dark)
	box(Vector3(14, 1.0, -44.74), Vector3(1.05, 0.55, 0.02), mat("plain", Color(0.15, 0.2, 0.2), 1.0, true, Color(0.1, 0.16, 0.16)), false)
	box(Vector3(2.4, 1.0, -40), Vector3(0.4, 2.0, 2.4), m_wood)          # bookshelf
	plant(Vector3(17.3, 0, -32.7))

	var a := npc("patient", Vector3(5.5, 0, -35.1), 0.0, ["Somebody always takes the remote.", "You want to play cards later?"], "")
	a.pose = "sit"
	var b := npc("patient", Vector3(14, 0, -36), 0.0, ["The coffee here is terrible. I drink it anyway."], "")
	b.pose = "sit"
	npc("patient", Vector3(11, 0, -34), 0.0, ["...", "Don't stand so close."], "",
		[Vector3(11, 0, -34), Vector3(11, 0, -43), Vector3(4.5, 0, -43.5)])


func _pool() -> void:
	room(20, 40, -46, -14, mat("pool_tile", Color.WHITE, 1.0), {"w": [[-30.0, 2.4]]}, null, true, 5.0)
	for p in [Vector3(25, 0, -21), Vector3(35, 0, -21), Vector3(25, 0, -39), Vector3(35, 0, -39)]:
		lamp(p, false, 1.0, 5.0)
	for z in [-20.0, -30.0, -40.0]:
		box(Vector3(39.77, 3.6, z), Vector3(0.04, 1.4, 6.0), m_window, false)

	# Basin: water flush with the floor, coping around it, lane ropes.
	box(Vector3(30, 0.01, -30), Vector3(12, 0.02, 20), mat("water", Color.WHITE, 0.4, true, Color(0.03, 0.08, 0.1)), false)
	var coping := m_white
	box(Vector3(30, 0.03, -19.8), Vector3(12.8, 0.06, 0.4), coping, false)
	box(Vector3(30, 0.03, -40.2), Vector3(12.8, 0.06, 0.4), coping, false)
	box(Vector3(23.8, 0.03, -30), Vector3(0.4, 0.06, 20), coping, false)
	box(Vector3(36.2, 0.03, -30), Vector3(0.4, 0.06, 20), coping, false)
	var rope := mat("plain", Color(0.75, 0.2, 0.15), 1.0)
	for x in [27.0, 30.0, 33.0]:
		box(Vector3(x, 0.05, -30), Vector3(0.08, 0.08, 20), rope, false)
	# Rope barrier (the pool opens in build step 8)
	invisible_wall(Vector3(30, 0.5, -30), Vector3(13.2, 1.0, 21.2))
	for c in [Vector3(23.4, 0, -19.4), Vector3(36.6, 0, -19.4), Vector3(23.4, 0, -40.6), Vector3(36.6, 0, -40.6)]:
		box(c + Vector3(0, 0.5, 0), Vector3(0.08, 1.0, 0.08), m_dark, false)
	box(Vector3(30, 0.9, -19.4), Vector3(13.2, 0.04, 0.04), rope, false)
	box(Vector3(30, 0.9, -40.6), Vector3(13.2, 0.04, 0.04), rope, false)
	box(Vector3(23.4, 0.9, -30), Vector3(0.04, 0.04, 21.2), rope, false)
	box(Vector3(36.6, 0.9, -30), Vector3(0.04, 0.04, 21.2), rope, false)

	hsign("SUPERVISED SWIMMING ONLY", Vector3(20.23, 2.6, -24), 90)
	# Lifeguard chair
	box(Vector3(38.2, 0.9, -30), Vector3(0.7, 1.8, 0.7), m_metal)
	box(Vector3(38.2, 2.0, -30), Vector3(0.7, 0.1, 0.7), m_white, false)
	npc("nurse", Vector3(38, 0, -26.5), -PI * 0.5, ["The pool is only open in the afternoon. Check the board.", "Nobody swims without me watching."], "Nurse Dale")


func _courtyard() -> void:
	room(-12, 12, -76, -52, mat("court", Color.WHITE, 0.5), {"s": [[0.0, 2.4]], "w": [[-64.0, 8.0]]}, m_concrete, false, OUT_H)
	sky_light(Vector3(0, 14, -64))

	# Court markings
	var paint := mat("plain", Color(0.85, 0.85, 0.8), 1.0)
	box(Vector3(0, 0.005, -69.4), Vector3(3.7, 0.01, 0.08), paint, false)   # free-throw line
	box(Vector3(-1.85, 0.005, -72.6), Vector3(0.08, 0.01, 6.4), paint, false)
	box(Vector3(1.85, 0.005, -72.6), Vector3(0.08, 0.01, 6.4), paint, false)
	box(Vector3(0, 0.005, -64), Vector3(23.6, 0.01, 0.08), paint, false)    # half-court line

	# Basketball hoop
	box(Vector3(0, 1.6, -75.6), Vector3(0.16, 3.2, 0.16), m_dark)
	box(Vector3(0, 3.2, -75.2), Vector3(0.12, 0.12, 0.8), m_dark, false)
	box(Vector3(0, 3.4, -74.8), Vector3(1.8, 1.05, 0.05), m_white, false)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.2
	torus.outer_radius = 0.23
	torus.rings = 12
	torus.ring_segments = 6
	torus.material = mat("plain", Color(0.85, 0.35, 0.1), 1.0, false)
	var rim := MeshInstance3D.new()
	rim.mesh = torus
	rim.position = Vector3(0, 3.05, -74.5)
	add_child(rim)

	bench(Vector3(11.4, 0, -60), -PI * 0.5)
	bench(Vector3(11.4, 0, -68), -PI * 0.5)
	plant(Vector3(-11.3, 0, -53))
	plant(Vector3(11.3, 0, -53))
	npc("patient", Vector3(2.5, 0, -69), PI * 0.8, ["Bet you can't make a free throw with those shaky hands.", "Shoot around with me sometime."], "")


func _lawn() -> void:
	room(-44, -12, -84, -52, mat("grass", Color.WHITE, 0.5), {"e": [[-64.0, 8.0]]}, m_concrete, false, 3.0)
	sky_light(Vector3(-28, 14, -68))

	# Football goal at the west end
	var gx := -42.5
	for dz in [-3.66, 3.66]:
		box(Vector3(gx, 1.22, -68 + dz), Vector3(0.12, 2.44, 0.12), m_white)
	box(Vector3(gx, 2.44, -68), Vector3(0.12, 0.12, 7.44), m_white, false)
	var net := mat("plain", Color(0.75, 0.75, 0.72), 1.0)
	box(Vector3(gx - 1.2, 1.22, -68), Vector3(0.03, 2.44, 7.32), net, false)
	box(Vector3(gx - 0.6, 2.44, -68), Vector3(1.2, 0.03, 7.32), net, false)
	# Penalty area lines and spot
	var paint := mat("plain", Color(0.85, 0.88, 0.8), 1.0)
	box(Vector3(gx + 5.5, 0.005, -68), Vector3(0.1, 0.01, 18.3), paint, false)
	box(Vector3(gx + 2.75, 0.005, -77.15), Vector3(5.5, 0.01, 0.1), paint, false)
	box(Vector3(gx + 2.75, 0.005, -58.85), Vector3(5.5, 0.01, 0.1), paint, false)
	box(Vector3(gx + 11.0, 0.005, -68), Vector3(0.3, 0.01, 0.3), paint, false)

	for p in [Vector3(-15, 0, -81), Vector3(-40, 0, -55), Vector3(-26, 0, -82)]:
		tree(p)
	npc("patient", Vector3(gx + 0.6, 0, -68), -PI * 0.5, ["Best keeper in this place. Only keeper, but still.", "Come take a penalty when the lawn is open."], "")


## Drugs hidden around the center. Each id is taken only once.
func _hidden_pills() -> void:
	pill_bottle(Vector3(-24.0, 0, -22.7), "room11_floor")        # rolled under the next bed
	pill_bottle(Vector3(-10.2, 1.0, -31.5), "med_cart")          # on the medication cart
	pill_bottle(Vector3(16.3, 0, -44.7), "behind_tv")            # in the corner by the common room TV
	pill_bottle(Vector3(38.9, 0, -29.2), "lifeguard_chair")      # at the foot of the lifeguard chair
	pill_bottle(Vector3(-25.5, 0, -81.3), "lawn_tree")           # in the grass by a tree


# ------------------------------------------------------------------ Text

func _schedule_lines() -> Array[String]:
	var out: Array[String] = []
	for s in Config.SCHEDULE:
		var activity: String = s[1]
		var open := activity in ["Basketball", "Football", "Swimming"]
		var where: String = ("  -  " + s[2]) if s[2] != "" else ""
		out.append("%02d:00   %s%s%s" % [s[0], activity, where, "   OPEN" if open else ""])
	return out


func _schedule_board_text() -> String:
	return "DAILY SCHEDULE\n\n" + "\n".join(_schedule_lines())


func _schedule_text() -> String:
	return "\n".join(_schedule_lines()) + "\n\nActivities are once a day. Not allowed under the influence."


## The patient chart: the only place Recovery is shown - as a hand-drawn scale and a word, never a number.
func _chart_text() -> String:
	var lines: Array[String] = []
	lines.append("Programme: residential withdrawal management")
	lines.append("Admitted: the date has been crossed out and written again.")
	lines.append("")
	lines.append("Day %d." % Recovery.day())
	lines.append("Recovery  %s   %s" % [Recovery.scale_text(), Recovery.assessment()])
	lines.append("")
	lines.append("Notes:")
	lines.append("- Sleeping poorly. Check on him at night.")
	lines.append("- Encourage attendance at group therapy.")
	var recent := Recovery.notes.slice(maxi(0, Recovery.notes.size() - 5))
	for n in recent:
		lines.append("- " + n)
	lines.append("")
	lines.append("Next of kin: wife. Visit planned: %s" % Recovery.days_text().to_lower())
	return "\n".join(lines)


# ------------------------------------------------------------------ Building blocks

## A room with its walls on the inside of its rectangle, so neighbouring rooms sit back to back.
## doors: {"n"/"s": [[x, width], ...], "w"/"e": [[z, width], ...]} (n = -Z side, e = +X side)
func room(x0: float, x1: float, z_north: float, z_south: float, floor_mat: Material,
		doors := {}, wall_mat: Material = null, ceiling := true, height := H) -> void:
	if wall_mat == null:
		wall_mat = m_wall
	var c := Vector3((x0 + x1) * 0.5, 0, (z_north + z_south) * 0.5)
	var size := Vector2(x1 - x0, z_south - z_north)
	box(Vector3(c.x, -0.05, c.z), Vector3(size.x, 0.1, size.y), floor_mat, false, null, 1.5)
	if ceiling:
		box(Vector3(c.x, height + 0.05, c.z), Vector3(size.x, 0.1, size.y), m_ceiling, false, null, 1.5)
	_wall(false, z_south - T * 0.5, x0, x1, doors.get("s", []), wall_mat, height, ceiling)
	_wall(false, z_north + T * 0.5, x0, x1, doors.get("n", []), wall_mat, height, ceiling)
	_wall(true, x0 + T * 0.5, z_north + T, z_south - T, doors.get("w", []), wall_mat, height, ceiling)
	_wall(true, x1 - T * 0.5, z_north + T, z_south - T, doors.get("e", []), wall_mat, height, ceiling)


func _wall(along_z: bool, fixed: float, a: float, b: float, gaps: Array, wall_mat: Material,
		height: float, lintels: bool) -> void:
	var sorted := gaps.duplicate()
	sorted.sort_custom(func(p, q): return p[0] < q[0])
	var cursor := a
	for g in sorted:
		var g0 := clampf(g[0] - g[1] * 0.5, a, b)
		var g1 := clampf(g[0] + g[1] * 0.5, a, b)
		_wall_piece(along_z, fixed, cursor, g0, 0.0, height, wall_mat)
		if lintels:
			_wall_piece(along_z, fixed, g0, g1, DOOR_H, height, wall_mat)
		cursor = g1
	_wall_piece(along_z, fixed, cursor, b, 0.0, height, wall_mat)


func _wall_piece(along_z: bool, fixed: float, a: float, b: float, y0: float, y1: float, wall_mat: Material) -> void:
	if b - a < 0.01 or y1 - y0 < 0.01:
		return
	var mid := (a + b) * 0.5
	var y := (y0 + y1) * 0.5
	if along_z:
		box(Vector3(fixed, y, mid), Vector3(T, y1 - y0, b - a), wall_mat, true, null, 1.5)
	else:
		box(Vector3(mid, y, fixed), Vector3(b - a, y1 - y0, T), wall_mat, true, null, 1.5)


func lamp(pos: Vector3, flicker := false, energy := Config.LAMP_ENERGY, height := H) -> void:
	box(Vector3(pos.x, height - 0.03, pos.z), Vector3(1.2, 0.05, 0.3), m_lamp, false)
	var l := OmniLight3D.new()
	l.position = Vector3(pos.x, height - 0.4, pos.z)
	l.light_color = Config.LAMP_COLOR
	l.light_energy = energy
	l.omni_range = Config.LAMP_RANGE * (height / H)
	add_child(l)
	if flicker:
		_flicker.append(l)


## Big soft light high above an outdoor area (overcast sky).
func sky_light(pos: Vector3) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = Color(0.9, 0.95, 0.95)
	l.light_energy = Config.OUTDOOR_LIGHT_ENERGY
	l.omni_range = Config.OUTDOOR_LIGHT_RANGE
	l.omni_attenuation = 0.5
	add_child(l)


## Hospital sign: white text on a blue plate. rot_y: 0 faces +Z, 180 faces -Z, 90 faces +X, -90 faces -X.
func hsign(text: String, pos: Vector3, rot_y: float, plate: Material = null) -> void:
	if plate == null:
		plate = m_sign
	var w := text.length() * 0.085 + 0.3
	var along_x := absf(fmod(rot_y, 180.0)) < 1.0
	box(pos, Vector3(w, 0.26, 0.03) if along_x else Vector3(0.03, 0.26, w), plate, false)
	var forward := Vector3(sin(deg_to_rad(rot_y)), 0, cos(deg_to_rad(rot_y)))
	sign_text(text, pos + forward * 0.02, rot_y, 22, Color(0.95, 0.95, 0.92))


## Room number above a door in the west hall. south=true: rooms 10-12 (sign faces -Z, into the hall).
func room_number(number: String, x: float, south: bool) -> void:
	if south:
		sign_text(number, Vector3(x, 2.45, -28.22), 180, 32, Color(0.2, 0.25, 0.35))
	else:
		sign_text(number, Vector3(x, 2.45, -31.78), 0, 32, Color(0.2, 0.25, 0.35))


## A closed door panel on a wall (no room behind it), with a message when you try it.
func closed_door(pos: Vector3, rot_y: float, prompt: String, message: String) -> void:
	var along_x := absf(fmod(rot_y, 180.0)) < 1.0
	box(pos + Vector3(0, 1.05, 0), Vector3(1.0, 2.1, 0.06) if along_x else Vector3(0.06, 2.1, 1.0), m_door, false)
	var p := Pickup.new()
	p.kind = "locked"
	p.prompt = prompt
	p.message = message
	p.shape_size = Vector3(1.0, 2.0, 0.3) if along_x else Vector3(0.3, 2.0, 1.0)
	p.position = pos
	add_child(p)


func npc(role: String, pos: Vector3, yaw: float, lines: Array, display_name := "",
		waypoints: Array = []) -> Npc:
	var n := Npc.new()
	n.role = role
	n.display_name = display_name
	n.facing = yaw
	n.lines.assign(lines)
	n.waypoints.assign(waypoints)
	n.position = pos
	add_child.call_deferred(n)  # after the level's colliders exist
	return n


## yaw: the direction a seated person faces (0 = -Z). Backrest is behind them.
func chair(pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	box(Vector3(0, 0.45, 0), Vector3(0.45, 0.06, 0.45), m_fabric, true, root)
	box(Vector3(0, 0.75, 0.21), Vector3(0.45, 0.55, 0.05), m_fabric, false, root)
	box(Vector3(0, 0.21, 0), Vector3(0.38, 0.42, 0.38), m_dark, false, root)


func bench(pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	box(Vector3(0, 0.45, 0), Vector3(1.6, 0.06, 0.45), m_wood, true, root)
	box(Vector3(0, 0.22, 0), Vector3(1.4, 0.44, 0.3), m_dark, false, root)


func sofa(pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	box(Vector3(0, 0.22, 0), Vector3(2.2, 0.44, 0.85), m_fabric, true, root)
	box(Vector3(0, 0.65, 0.35), Vector3(2.2, 0.6, 0.18), m_fabric, false, root)
	for sx in [-1.0, 1.0]:
		box(Vector3(sx * 1.05, 0.55, 0), Vector3(0.18, 0.3, 0.85), m_fabric, false, root)


func table(pos: Vector3, size: Vector2) -> void:
	box(pos + Vector3(0, 0.74, 0), Vector3(size.x, 0.06, size.y), m_white)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			box(pos + Vector3(sx * (size.x * 0.5 - 0.08), 0.36, sz * (size.y * 0.5 - 0.08)),
				Vector3(0.05, 0.72, 0.05), m_dark, false)


## Hospital bed, head toward local +Z.
func hospital_bed(pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	box(Vector3(0, 0.3, 0), Vector3(0.95, 0.35, 2.1), m_metal, true, root)
	box(Vector3(0, 0.55, 0), Vector3(0.9, 0.15, 2.0), m_sheet, false, root)       # mattress
	box(Vector3(0, 0.66, 0.75), Vector3(0.6, 0.1, 0.35), m_white, false, root)    # pillow
	box(Vector3(0, 0.6, -0.35), Vector3(0.92, 0.08, 1.2), m_fabric, false, root)  # blanket
	box(Vector3(0, 0.75, 1.03), Vector3(0.95, 0.9, 0.05), m_metal, false, root)   # headboard
	box(Vector3(0, 0.6, -1.03), Vector3(0.95, 0.6, 0.05), m_metal, false, root)   # footboard
	for sx in [-1.0, 1.0]:
		box(Vector3(sx * 0.48, 0.75, 0.2), Vector3(0.03, 0.25, 1.0), m_metal, false, root)  # side rails


func iv_stand(pos: Vector3) -> void:
	box(pos + Vector3(0, 0.9, 0), Vector3(0.04, 1.8, 0.04), m_metal)
	box(pos + Vector3(0, 0.03, 0), Vector3(0.5, 0.04, 0.5), m_metal, false)
	box(pos + Vector3(0, 1.75, 0), Vector3(0.4, 0.03, 0.03), m_metal, false)
	box(pos + Vector3(0.15, 1.6, 0), Vector3(0.12, 0.2, 0.05), mat("plain", Color(0.8, 0.85, 0.9), 1.0), false)  # bag


func wheelchair(pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	box(Vector3(0, 0.5, 0), Vector3(0.5, 0.06, 0.45), m_fabric, true, root)
	box(Vector3(0, 0.8, 0.22), Vector3(0.5, 0.5, 0.04), m_fabric, false, root)
	for sx in [-1.0, 1.0]:
		var w := cylinder(Vector3(sx * 0.3, 0.3, 0.05), 0.3, 0.04, m_dark, root)
		w.rotation.z = PI * 0.5


func plant(pos: Vector3) -> void:
	cylinder(pos + Vector3(0, 0.25, 0), 0.25, 0.5, m_concrete)
	box(pos + Vector3(0, 0.85, 0), Vector3(0.6, 0.7, 0.6), mat("grass", Color(0.9, 1.1, 0.9), 2.0), false)


func tree(pos: Vector3) -> void:
	box(pos + Vector3(0, 1.5, 0), Vector3(0.35, 3.0, 0.35), m_wood)
	box(pos + Vector3(0, 3.8, 0), Vector3(2.6, 2.2, 2.6), mat("grass", Color(0.8, 1.0, 0.8), 1.0), false)
