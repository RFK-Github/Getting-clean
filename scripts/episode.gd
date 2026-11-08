extends Node
## Withdrawal episode, in four phases:
##   build - a headache builds: pulsing vignette, blur, ringing ears, heartbeat, shake. You can still move.
##   grab  - he grabs his head and shakes it. No control.
##   kneel - he falls to his knees. A flashback plays here (signal flashback_point).
##   out   - he blacks out and wakes up in his room the next morning (a day passes).
## Getting through it without a pill still counts: Withdrawal.episode_survived (Recovery).

signal flashback_point

const Audio := preload("res://scripts/audio.gd")
const Player := preload("res://scripts/player.gd")

var player: Player
var post_material: ShaderMaterial

var phase := ""          # "", "build", "grab", "kneel", "out"
var _t := 0.0
var _cooldown: float = Config.EPISODE_FIRST_COOLDOWN
var _headache := 0.0
var _ringing: AudioStreamPlayer
var _heart: AudioStreamPlayer


func _ready() -> void:
	_ringing = _sound(Audio.tinnitus(), Settings.LOUD_BUS)
	_heart = _sound(Audio.heartbeat(), "Master")
	Withdrawal.pill_taken.connect(_on_pill_taken)


func _process(delta: float) -> void:
	if phase == "":
		_cooldown -= delta
		if _cooldown <= 0.0 and Withdrawal.state == "" and not Withdrawal.is_influenced() \
				and Withdrawal.meter >= Config.EPISODE_THRESHOLD \
				and randf() < Config.EPISODE_CHANCE_PER_SEC * delta:
			start()
	else:
		_t += delta
		match phase:
			"build":
				if _t >= Config.EPISODE_BUILD_TIME:
					_enter("grab")
			"grab":
				if _t >= Config.EPISODE_GRAB_TIME:
					_enter("kneel")
			"kneel":
				if _t >= Config.EPISODE_KNEEL_TIME:
					black_out()
	_apply(delta)


func start() -> void:
	if phase != "":
		return
	Withdrawal.state = "episode"
	Withdrawal.episode_started.emit()
	_ringing.play()
	_heart.play()
	_enter("build")


func _enter(next: String) -> void:
	phase = next
	_t = 0.0
	match next:
		"grab":
			player.frozen = true
			player.body.play_action("grab_head")
		"kneel":
			flashback_point.emit()


## He blacks out on the floor and wakes up in his bed: one day passes.
## extra: a thought to show when he wakes (after a flashback).
func black_out(extra := "") -> void:
	if phase == "out":
		return
	phase = "out"
	_ringing.stop()
	_heart.stop()
	Withdrawal.state = ""
	Withdrawal.episode_survived.emit()
	Recovery.next_day("episode", extra)


## Taking a pill during the build-up cuts the episode short (and it doesn't count as survived).
func _on_pill_taken() -> void:
	if phase == "":
		return
	phase = ""
	player.frozen = false
	player.body.play_action("")
	Withdrawal.state = ""
	_cooldown = Config.EPISODE_COOLDOWN


func _apply(delta: float) -> void:
	var headache_target := 0.0
	var kneel_target := 0.0
	var shake_head := 0.0
	match phase:
		"build":
			headache_target = _t / Config.EPISODE_BUILD_TIME
		"grab":
			headache_target = 1.0
			shake_head = 1.0
		"kneel":
			headache_target = 1.0
			kneel_target = 1.0
		"out":
			headache_target = 1.0
			kneel_target = 1.0
	_headache = move_toward(_headache, headache_target, delta * 2.0)
	player.kneel = move_toward(player.kneel, kneel_target, delta * (1.6 if kneel_target > player.kneel else 1.0))
	player.head_shake = move_toward(player.head_shake, shake_head, delta * 3.0)
	player.set_shake("episode", Config.EPISODE_SHAKE * _headache)
	post_material.set_shader_parameter("headache", _headache)
	if _headache > 0.001:
		_ringing.volume_db = Config.TINNITUS_DB + linear_to_db(_headache)
		_heart.volume_db = Config.HEARTBEAT_DB + linear_to_db(_headache)
	elif _ringing.playing:
		_ringing.stop()
		_heart.stop()


func _sound(stream: AudioStream, bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	add_child(p)
	return p
