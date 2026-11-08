extends CharacterBody3D
## First-person player: WASD + mouse, sprint with stamina (Shift), flashlight (F),
## interact (E), first-person body and screen shake.

signal prompt_changed(text: String)

const PlayerBody := preload("res://scripts/player_body.gd")

var head: Node3D
var camera: Camera3D
var flashlight: SpotLight3D
var body: PlayerBody
var frozen := false   # no control (panic, withdrawal episodes)
var kneel := 0.0      # 0 = standing, 1 = on the knees (withdrawal episode)
var head_shake := 0.0 # 0..1 shaking the head side to side (withdrawal episode)

var _shakes := {}     # screen shake per source ("train", "hallucination", "episode")
var _time := 0.0

var stamina: float = Config.STAMINA_MAX
var max_stamina: float = Config.STAMINA_MAX
var sprinting := false

var _exhausted := false
var _regen_wait := 0.0
var _pitch := 0.0
var _bob := 0.0
var _target: Object = null
var _shown_prompt := ""
var _jump_buffer := 0.0
var _gun_cool := 0.0
var _muzzle: OmniLight3D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 16  # world + NPCs

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.75
	cs.shape = cap
	cs.position.y = 0.875
	add_child(cs)

	head = Node3D.new()
	head.position.y = Config.PLAYER_HEIGHT
	add_child(head)

	camera = Camera3D.new()
	camera.fov = Config.FOV
	camera.near = 0.05
	camera.far = 40.0
	head.add_child(camera)
	camera.set_cull_mask_value(2, false)  # layer 2 = own head, only visible in mirrors
	camera.make_current()

	flashlight = SpotLight3D.new()
	flashlight.position = Vector3(0.24, -0.27, -0.56)  # front of the torch in the right hand
	flashlight.light_energy = Config.FLASHLIGHT_ENERGY
	flashlight.light_color = Color(1.0, 0.97, 0.85)
	flashlight.spot_range = Config.FLASHLIGHT_RANGE
	flashlight.spot_angle = Config.FLASHLIGHT_ANGLE
	flashlight.shadow_enabled = true
	camera.add_child(flashlight)

	body = PlayerBody.new()
	add_child(body)
	body.setup(camera)
	if Game.has_gun:
		body.give_gun()
	_muzzle = OmniLight3D.new()
	_muzzle.position = Vector3(-0.24, -0.22, -0.8)
	_muzzle.light_color = Color(1.0, 0.85, 0.55)
	_muzzle.light_energy = 4.0
	_muzzle.omni_range = 8.0
	_muzzle.visible = false
	camera.add_child(_muzzle)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func reset_look() -> void:
	_pitch = 0.0
	head.rotation.x = 0.0


## Screen shake from one source. The strongest source wins. 0 = off.
func set_shake(source: String, amount: float) -> void:
	_shakes[source] = amount


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not frozen:
		var rel: Vector2 = event.screen_relative
		rotate_y(-rel.x * Config.MOUSE_SENSITIVITY)
		_pitch = clampf(_pitch - rel.y * Config.MOUSE_SENSITIVITY, -1.45, 1.4)
		head.rotation.x = _pitch
		body.add_look_delta(rel)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and Game.has_gun and not frozen and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		shoot()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("flashlight"):
		flashlight.visible = not flashlight.visible
	elif event.is_action_pressed("interact") and not frozen:
		if _target != null and is_instance_valid(_target):
			_target.call("interact")
			_target = null   # re-read the prompt next frame (it may have changed, e.g. "Turn off")


func _physics_process(delta: float) -> void:
	_gun_cool = maxf(0.0, _gun_cool - delta)
	if _shakes.get("gun", 0.0) > 0.0:
		_shakes["gun"] = maxf(0.0, _shakes["gun"] - delta * 0.1)
	if not is_on_floor():
		velocity.y -= Config.GRAVITY * delta

	var input := Vector2.ZERO
	if not frozen:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	_update_stamina(delta, input)

	var speed := Config.SPRINT_SPEED if sprinting else Config.WALK_SPEED
	var dir := global_transform.basis * Vector3(input.x, 0.0, input.y)
	dir.y = 0.0
	dir = dir.normalized()
	var on_floor := is_on_floor()
	# Jump buffer: pressing jump just before landing still jumps the moment you touch down.
	# Holding Space keeps jumping (bunny hop): every landing jumps again.
	if Input.is_action_just_pressed("jump") or Input.is_action_pressed("jump"):
		_jump_buffer = Config.JUMP_BUFFER_TIME
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)
	var jumping := on_floor and not frozen and _jump_buffer > 0.0 and stamina >= Config.JUMP_STAMINA
	if jumping:
		_jump_buffer = 0.0
	if on_floor and not jumping:
		# On the ground: walk / sprint exactly where you steer.
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	elif jumping:
		# Take off. Keep any speed you carried in (jumping right as you land = bunny hop).
		var carried := Vector2(velocity.x, velocity.z)
		if carried.length() < speed:
			carried = Vector2(dir.x, dir.z) * speed
		velocity.x = carried.x
		velocity.z = carried.y
		velocity.y = Config.JUMP_VELOCITY
		stamina -= Config.JUMP_STAMINA
	else:
		# In the air: Quake-style air strafing. Hold a strafe key and turn the mouse the same
		# way to curve and gain a little speed; no input = keep your momentum.
		_air_accelerate(dir, delta)
	move_and_slide()

	var speed_ratio := Vector2(velocity.x, velocity.z).length() / Config.WALK_SPEED
	if speed_ratio > 0.1 and is_on_floor():
		_bob += delta * Config.HEAD_BOB_FREQ * minf(speed_ratio, Config.SPRINT_BOB_MULTIPLIER)
	body.update_motion(delta, speed_ratio, sprinting, _bob)
	_update_target()


## Air acceleration (as in Quake/Source): only the part of the velocity along the wished
## direction is capped (at a small speed), so steering sideways while turning adds speed.
func _air_accelerate(wish_dir: Vector3, delta: float) -> void:
	if wish_dir == Vector3.ZERO:
		return
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var current := horizontal.dot(wish_dir)
	var add := Config.AIR_WISH_SPEED - current
	if add <= 0.0:
		return
	var accel := minf(Config.AIR_ACCELERATION * Config.AIR_WISH_SPEED * delta, add)
	horizontal += wish_dir * accel
	if horizontal.length() > Config.AIR_MAX_SPEED:
		horizontal = horizontal.normalized() * Config.AIR_MAX_SPEED
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Fire the revolver: a shot straight ahead. Everyone who hears it panics.
func shoot() -> void:
	if _gun_cool > 0.0:
		return
	_gun_cool = Config.GUN_COOLDOWN
	Game.shots_fired = true
	var s := AudioStreamPlayer.new()
	s.stream = preload("res://scripts/audio.gd").gunshot()
	s.bus = Settings.LOUD_BUS
	s.volume_db = Config.GUNSHOT_DB
	add_child(s)
	s.play()
	s.finished.connect(s.queue_free)
	_muzzle.visible = true
	get_tree().create_timer(0.06, false).timeout.connect(func(): _muzzle.visible = false)
	body.gun_kick()
	_pitch = clampf(_pitch + 0.03, -1.45, 1.4)
	head.rotation.x = _pitch
	set_shake("gun", 0.02)
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * Config.GUN_RANGE
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 16, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty() and hit.collider != null and hit.collider.has_method("shot"):
		hit.collider.shot()
	get_tree().call_group("npc", "panic_from", global_position)


func _update_stamina(delta: float, input: Vector2) -> void:
	max_stamina = Config.STAMINA_MAX * (1.0 - Withdrawal.meter / Config.METER_MAX * Config.WITHDRAWAL_STAMINA_PENALTY)
	if _exhausted and stamina >= minf(Config.STAMINA_MIN_TO_SPRINT, max_stamina * 0.9):
		_exhausted = false
	var wants_sprint := Input.is_action_pressed("sprint") and input.y < -0.1 and not frozen
	sprinting = wants_sprint and not _exhausted and stamina > 0.0 and is_on_floor()
	if sprinting:
		stamina = maxf(0.0, stamina - Config.STAMINA_DRAIN_PER_SEC * delta)
		_regen_wait = Config.STAMINA_REGEN_DELAY
		if stamina <= 0.0:
			_exhausted = true
	else:
		_regen_wait -= delta
		if _regen_wait <= 0.0:
			stamina += Config.STAMINA_REGEN_PER_SEC * delta
	stamina = minf(stamina, max_stamina)


func _process(delta: float) -> void:
	_time += delta
	var s := 0.0
	if Settings.screen_shake:
		for v in _shakes.values():
			s = maxf(s, v)
	var bob_amount := Config.HEAD_BOB * (Config.SPRINT_BOB_MULTIPLIER if sprinting else 1.0)
	var bob := sin(_bob) * bob_amount
	camera.h_offset = randf_range(-s, s) if s > 0.0 else 0.0
	camera.v_offset = bob + (randf_range(-s, s) if s > 0.0 else 0.0)
	camera.rotation.z = (randf_range(-s, s) * 0.6 if s > 0.0 else 0.0) + kneel * 0.08

	# Withdrawal episode: drop to the knees and shake the head (gentler with screen shake off).
	head.position.y = Config.PLAYER_HEIGHT - kneel * Config.KNEEL_DROP
	body.position.y = -kneel * Config.KNEEL_DROP
	var swing := Config.HEAD_SHAKE_ANGLE * (1.0 if Settings.screen_shake else 0.3)
	head.rotation.y = sin(_time * Config.HEAD_SHAKE_SPEED) * swing * head_shake
	var target_fov := Config.FOV + (Config.SPRINT_FOV_KICK if sprinting else 0.0)
	camera.fov = lerpf(camera.fov, target_fov, clampf(delta * 6.0, 0.0, 1.0))


func _update_target() -> void:
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * Config.INTERACT_DISTANCE
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 8 | 16, [get_rid()])
	q.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var new_target: Object = null
	if not hit.is_empty() and hit.collider != null and hit.collider.has_method("interact"):
		new_target = hit.collider
	_target = new_target
	var text := "[E] " + str(_target.get("prompt")) if _target != null else ""
	if text != _shown_prompt:   # also when the prompt itself changes (e.g. the phone starts ringing)
		_shown_prompt = text
		prompt_changed.emit(text)
