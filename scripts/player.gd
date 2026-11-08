extends CharacterBody3D
## First-person player: WASD + mouse, sprint with stamina (Shift), flashlight (F),
## interact (E), first-person body and screen shake.

signal prompt_changed(text: String)

const PlayerBody := preload("res://scripts/player_body.gd")

var head: Node3D
var camera: Camera3D
var flashlight: SpotLight3D
var body: PlayerBody
var shake := 0.0      # set by hallucinations
var frozen := false   # no control (panic, later: withdrawal episodes)

var stamina: float = Config.STAMINA_MAX
var max_stamina: float = Config.STAMINA_MAX
var sprinting := false

var _exhausted := false
var _regen_wait := 0.0
var _pitch := 0.0
var _bob := 0.0
var _target: Object = null


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1

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

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func reset_look() -> void:
	_pitch = 0.0
	head.rotation.x = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not frozen:
		var rel: Vector2 = event.screen_relative
		rotate_y(-rel.x * Config.MOUSE_SENSITIVITY)
		_pitch = clampf(_pitch - rel.y * Config.MOUSE_SENSITIVITY, -1.45, 1.4)
		head.rotation.x = _pitch
		body.add_look_delta(rel)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("flashlight"):
		flashlight.visible = not flashlight.visible
	elif event.is_action_pressed("interact") and not frozen:
		if _target != null and is_instance_valid(_target):
			_target.call("interact")


func _physics_process(delta: float) -> void:
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
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

	var speed_ratio := Vector2(velocity.x, velocity.z).length() / Config.WALK_SPEED
	if speed_ratio > 0.1 and is_on_floor():
		_bob += delta * Config.HEAD_BOB_FREQ * minf(speed_ratio, Config.SPRINT_BOB_MULTIPLIER)
	body.update_motion(delta, speed_ratio, sprinting, _bob)
	_update_target()


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
	var s := shake if Settings.screen_shake else 0.0
	var bob_amount := Config.HEAD_BOB * (Config.SPRINT_BOB_MULTIPLIER if sprinting else 1.0)
	var bob := sin(_bob) * bob_amount
	if s > 0.0:
		camera.h_offset = randf_range(-s, s)
		camera.v_offset = bob + randf_range(-s, s)
		camera.rotation.z = randf_range(-s, s) * 0.6
	else:
		camera.h_offset = 0.0
		camera.v_offset = bob
		camera.rotation.z = 0.0
	var target_fov := Config.FOV + (Config.SPRINT_FOV_KICK if sprinting else 0.0)
	camera.fov = lerpf(camera.fov, target_fov, clampf(delta * 6.0, 0.0, 1.0))


func _update_target() -> void:
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * Config.INTERACT_DISTANCE
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 8, [get_rid()])
	q.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var new_target: Object = null
	if not hit.is_empty() and hit.collider != null and hit.collider.has_method("interact"):
		new_target = hit.collider
	if new_target != _target:
		_target = new_target
		prompt_changed.emit("[E] " + str(_target.get("prompt")) if _target != null else "")
