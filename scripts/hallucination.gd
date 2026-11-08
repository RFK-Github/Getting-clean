extends Node
## Hallucinations at high withdrawal: the screen shakes, a loud sound plays and a monster
## chases the player. Survive until it fades - or get caught: panic, and you wake up in bed.
## Never while under the influence; taking a pill makes an active one vanish.

const Monster := preload("res://scripts/monster.gd")
const Audio := preload("res://scripts/audio.gd")
const Player := preload("res://scripts/player.gd")

signal caught_player   # step 5: a day passes

var player: Player
var bed_spawn: Transform3D
var post_material: ShaderMaterial

var active := false
var panicking := false
var fade := 0.0  # 0..1, tweened during panic

var _time_left := 0.0
var _cooldown := 0.0
var _spawn_delay := 0.0
var _intensity := 0.0
var _monster: Monster
var _sound: AudioStreamPlayer


func _ready() -> void:
	_cooldown = Config.HALLUCINATION_COOLDOWN
	_sound = AudioStreamPlayer.new()
	_sound.stream = Audio.screech()
	_sound.bus = Settings.LOUD_BUS
	_sound.volume_db = Config.LOUD_SOUND_DB
	add_child(_sound)
	Withdrawal.pill_taken.connect(_on_pill_taken)


func _process(delta: float) -> void:
	if active:
		_time_left -= delta
		if _spawn_delay > 0.0:
			_spawn_delay -= delta
			if _spawn_delay <= 0.0:
				_spawn_monster()
		if _time_left <= 0.0:
			_end("It's gone. Was it ever there?")
			Withdrawal.hallucination_survived.emit()
	elif not panicking:
		_cooldown -= delta
		if _cooldown <= 0.0 and Withdrawal.state == "" and not Withdrawal.is_influenced() \
				and Withdrawal.meter >= Config.HALLUCINATION_THRESHOLD:
			var t := inverse_lerp(Config.HALLUCINATION_THRESHOLD, Config.METER_MAX, Withdrawal.meter)
			var chance := lerpf(Config.HALLUCINATION_CHANCE_PER_SEC, Config.HALLUCINATION_CHANCE_AT_MAX, t)
			if randf() < chance * delta:
				start()
	_update_effects(delta)


func start() -> void:
	if active or panicking:
		return
	active = true
	Withdrawal.state = "hallucination"
	_time_left = Config.HALLUCINATION_DURATION + Withdrawal.addiction * Config.HALLUCINATION_DURATION_PER_ADDICTION
	_spawn_delay = Config.MONSTER_SPAWN_DELAY
	_sound.play()


func _spawn_monster() -> void:
	_monster = Monster.new()
	_monster.target = player
	_monster.speed = Config.MONSTER_SPEED + Withdrawal.addiction * Config.MONSTER_SPEED_PER_ADDICTION
	_monster.caught.connect(_on_caught)
	get_parent().add_child(_monster)
	var behind := player.global_position + player.global_transform.basis.z * Config.MONSTER_SPAWN_DISTANCE
	var p := NavigationServer3D.map_get_closest_point(player.get_world_3d().navigation_map, behind)
	if p == Vector3.ZERO:
		p = behind
	p.y = 0.02
	_monster.global_position = p


func _remove_monster() -> void:
	if _monster != null and is_instance_valid(_monster):
		_monster.queue_free()
	_monster = null


func _end(message: String) -> void:
	active = false
	Withdrawal.state = ""
	_sound.stop()
	_remove_monster()
	_cooldown = Config.HALLUCINATION_COOLDOWN
	if message != "":
		Withdrawal.post_message(message)


func _on_pill_taken() -> void:
	if active:
		_end("")


func _on_caught() -> void:
	if panicking:
		return
	panicking = true
	active = false
	player.frozen = true
	_remove_monster()
	post_material.set_shader_parameter("fade_color", Color(0.35, 0.0, 0.0))
	var tw := create_tween()
	tw.tween_property(self, "fade", 1.0, 0.5)
	tw.tween_interval(1.0)
	tw.tween_callback(_wake_up)
	tw.tween_interval(0.8)
	tw.tween_property(self, "fade", 0.0, 2.0)
	tw.tween_callback(_finish_panic)


func _wake_up() -> void:
	_sound.stop()
	post_material.set_shader_parameter("fade_color", Color(0, 0, 0))
	player.global_transform = bed_spawn
	player.velocity = Vector3.ZERO
	player.reset_look()
	Withdrawal.meter = Config.CAUGHT_METER_AFTER
	caught_player.emit()
	Withdrawal.post_message("You wake up in your bed. The sheets are soaked with sweat. It's morning.")


func _finish_panic() -> void:
	panicking = false
	player.frozen = false
	Withdrawal.state = ""
	_cooldown = Config.HALLUCINATION_COOLDOWN


func _update_effects(delta: float) -> void:
	var target := 0.0
	if active or panicking:
		target = 1.0
	else:
		target = clampf(inverse_lerp(Config.SYMPTOM_START, Config.METER_MAX, Withdrawal.meter), 0.0, 1.0) * 0.25
		if Withdrawal.is_influenced():
			target = 0.0
	_intensity = move_toward(_intensity, target, delta * 1.5)

	player.set_shake("hallucination", Config.SHAKE_STRENGTH * _intensity if (active or panicking) else 0.0)
	post_material.set_shader_parameter("hallucination", _intensity)
	post_material.set_shader_parameter("wobble", _intensity * (1.0 if Settings.screen_shake else 0.25))
	post_material.set_shader_parameter("fade", fade)
