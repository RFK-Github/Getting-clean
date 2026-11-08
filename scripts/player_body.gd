extends Node3D
## The player's own first-person body.
##
## Placeholder boxes for now: torso + legs (visible when looking down) and arms/hands
## attached to the camera that sway while walking. If a model exists at
## Config.PLAYER_MODEL_PATH (e.g. a Mixamo export) it is used instead, and its
## AnimationPlayer is driven by animation name ("idle", "walk", "run").
## See assets/characters/README.md.

const Psx := preload("res://scripts/psx.gd")
const Tex := preload("res://scripts/textures.gd")

var _camera: Camera3D
var _model: Node3D
var _anim: AnimationPlayer

# Placeholder parts
var _leg_l: Node3D
var _leg_r: Node3D
var _arms: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _look_lag := Vector2.ZERO
var _action := ""


func setup(camera: Camera3D) -> void:
	_camera = camera
	position.z = Config.BODY_BACK_OFFSET
	if ResourceLoader.exists(Config.PLAYER_MODEL_PATH):
		_load_model()
	else:
		_build_placeholder()


## Called every physics frame by the player.
## speed_ratio: horizontal speed / walk speed (0 = standing). phase: head-bob phase.
func update_motion(delta: float, speed_ratio: float, sprinting: bool, phase: float) -> void:
	if _model != null:
		_drive_animation(speed_ratio, sprinting)
		return
	if _leg_l == null:
		return
	var moving := clampf(speed_ratio, 0.0, 1.0)
	var swing := deg_to_rad(Config.LEG_SWING_DEGREES) * moving * (1.3 if sprinting else 1.0)
	_leg_l.rotation.x = sin(phase * 0.5) * swing
	_leg_r.rotation.x = -sin(phase * 0.5) * swing

	# Arms: sway with the walk, pump when sprinting, trail behind mouse movement.
	_look_lag = _look_lag.lerp(Vector2.ZERO, clampf(delta * 8.0, 0.0, 1.0))
	var sway := Config.ARM_SWAY * moving * (1.8 if sprinting else 1.0)
	_arms.position = Vector3(
		cos(phase * 0.5) * sway - _look_lag.x,
		-absf(sin(phase * 0.5)) * sway + _look_lag.y,
		0.0)
	var pump := sin(phase * 0.5) * (0.5 if sprinting else 0.12) * moving
	_arm_l.rotation.x = pump
	_arm_r.rotation.x = -pump


## Mouse movement in screen pixels, so the arms can lag slightly behind.
func add_look_delta(rel: Vector2) -> void:
	_look_lag += rel * Config.ARM_LOOK_LAG
	_look_lag = _look_lag.limit_length(0.05)


## Hook for body actions (e.g. "grab_head", "kneel" in build step 4). Not implemented yet.
func play_action(action_name: String) -> void:
	_action = action_name


# ------------------------------------------------------------------ Placeholder

func _build_placeholder() -> void:
	var skin := Psx.material(Tex.get_texture("plain"), Config.SKIN_COLOR, 1.0, false)
	var jacket := Psx.material(Tex.get_texture("fabric"), Config.JACKET_COLOR * 2.5, 2.0, false)
	var pants := Psx.material(Tex.get_texture("fabric"), Config.PANTS_COLOR * 2.5, 2.0, false)
	var shoes := Psx.material(Tex.get_texture("plain"), Config.SHOE_COLOR, 1.0, false)
	var metal := Psx.material(Tex.get_texture("metal"), Color(0.5, 0.5, 0.5), 1.0, false)

	# Torso and legs follow the body's yaw (not the camera pitch).
	_box(self, Vector3(0, 1.2, 0), Vector3(0.42, 0.55, 0.22), jacket)
	_box(self, Vector3(0, 0.88, 0), Vector3(0.38, 0.16, 0.22), pants)
	# Head and neck: only on visual layer 2, so mirrors see it but the player's camera doesn't.
	var hair := Psx.material(Tex.get_texture("plain"), Config.HAIR_COLOR, 1.0, false)
	for part in [
			_box(self, Vector3(0, 1.52, -0.02), Vector3(0.1, 0.1, 0.1), skin),
			_box(self, Vector3(0, 1.66, -0.04), Vector3(0.22, 0.26, 0.24), skin),
			_box(self, Vector3(0, 1.8, -0.02), Vector3(0.24, 0.07, 0.26), hair)]:
		part.layers = 2
	_leg_l = _leg(Vector3(-0.1, 0.82, 0), pants, shoes)
	_leg_r = _leg(Vector3(0.1, 0.82, 0), pants, shoes)

	# Arms are attached to the camera so they follow where you look.
	_arms = Node3D.new()
	_camera.add_child(_arms)
	_arm_l = _arm(Vector3(-0.24, -0.3, -0.05), jacket, skin)
	_arm_r = _arm(Vector3(0.24, -0.3, -0.05), jacket, skin)
	# Flashlight in the right hand.
	_box(_arm_r, Vector3(0, 0.03, -0.46), Vector3(0.05, 0.05, 0.16), metal)


func _leg(hip: Vector3, pants: Material, shoes: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = hip
	add_child(pivot)
	_box(pivot, Vector3(0, -0.4, 0), Vector3(0.15, 0.8, 0.16), pants)
	_box(pivot, Vector3(0, -0.78, -0.06), Vector3(0.14, 0.08, 0.27), shoes)
	return pivot


func _arm(shoulder: Vector3, sleeve: Material, skin: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = shoulder
	_arms.add_child(pivot)
	_box(pivot, Vector3(0, 0, -0.2), Vector3(0.09, 0.09, 0.4), sleeve)
	_box(pivot, Vector3(0, 0, -0.44), Vector3(0.09, 0.06, 0.11), skin)
	return pivot


func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


# ------------------------------------------------------------------ Imported model

func _load_model() -> void:
	var scene := load(Config.PLAYER_MODEL_PATH) as PackedScene
	if scene == null:
		push_warning("Could not load player model, using placeholder boxes.")
		_build_placeholder()
		return
	_model = scene.instantiate() as Node3D
	_model.rotation.y = PI  # Mixamo characters face +Z, Godot forward is -Z
	add_child(_model)
	for mi in _model.find_children("*", "GeometryInstance3D", true, false):
		(mi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var players := _model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0]


func _drive_animation(speed_ratio: float, sprinting: bool) -> void:
	if _anim == null:
		return
	var wanted := "idle"
	if speed_ratio > 0.1:
		wanted = "run" if sprinting else "walk"
	if _action != "" and _anim.has_animation(_action):
		wanted = _action
	if _anim.has_animation(wanted) and _anim.current_animation != wanted:
		_anim.play(wanted, 0.2)
