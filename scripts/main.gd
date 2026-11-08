extends Node3D
## Assembles the current level (Game.current_level): environment/fog, level geometry,
## navigation, player, post-processing, HUD, withdrawal episodes (with flashbacks),
## hallucinations and pause menu.

const Player := preload("res://scripts/player.gd")
const Hud := preload("res://scripts/hud.gd")
const Hallucination := preload("res://scripts/hallucination.gd")
const Episode := preload("res://scripts/episode.gd")
const PauseMenu := preload("res://scripts/pause_menu.gd")
const TheVisit := preload("res://scripts/cutscenes/the_visit.gd")

const LEVELS := {
	"philadelphia": preload("res://scripts/levels/philadelphia.gd"),
	"hospital": preload("res://scripts/levels/hospital.gd"),
}

## Flashbacks, in story order. One plays at the kneeling point of each withdrawal episode
## until all have been seen. [id, cutscene script, message afterwards]
const FLASHBACKS := [
	["car", preload("res://scripts/cutscenes/flashback_car.gd"),
		"Headlights. A scream. Then nothing. Why can't you remember the rest?"],
	["street", preload("res://scripts/cutscenes/flashback_street.gd"),
		"That was you. Before this place. Before you promised her."],
	["grave", preload("res://scripts/cutscenes/flashback_grave.gd"),
		"She's gone. They're both gone, in different ways. You know that now."],
]

var _post: ShaderMaterial
var _ringing: AudioStreamPlayer
var _ringing_noticed := false
var _episode: Node


func _ready() -> void:
	Withdrawal.state = ""  # nothing carries over mid-episode from a previous level
	Withdrawal.hold = false
	var level_script: GDScript = LEVELS.get(Game.current_level, LEVELS["philadelphia"])
	var level: Node3D = level_script.new()
	var s: Dictionary = level.get_settings()

	add_child(level.make_environment(s))

	if s.get("navigation", false):
		var region := NavigationRegion3D.new()
		add_child(region)
		region.add_child(level)
		level.build()
		_bake_navigation(region)
	else:
		add_child(level)
		level.build()

	var player := Player.new()
	add_child(player)
	player.global_transform = level.spawn
	player.camera.far = s.get("camera_far", 40.0)
	player.flashlight.visible = s.get("flashlight_on", true)
	Withdrawal.rate_multiplier = s.get("withdrawal_rate", 1.0)

	_post = level.make_post_material(s)
	var post_layer := CanvasLayer.new()
	post_layer.layer = 1
	add_child(post_layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = _post
	post_layer.add_child(rect)

	var hud := Hud.new()
	hud.player = player
	add_child(hud)
	player.prompt_changed.connect(hud.set_prompt)

	if s.get("hallucinations", false):
		var hallucination := Hallucination.new()
		hallucination.player = player
		hallucination.post_material = _post
		add_child(hallucination)

	if s.get("episodes", false):
		var episode := Episode.new()
		episode.player = player
		episode.post_material = _post
		episode.flashback_point.connect(_play_next_flashback)
		_episode = episode
		add_child(episode)

	add_child(PauseMenu.new())

	# Ringing in the ears once withdrawal symptoms start.
	_ringing = AudioStreamPlayer.new()
	_ringing.stream = preload("res://scripts/audio.gd").tinnitus()
	_ringing.bus = Settings.LOUD_BUS
	add_child(_ringing)

	var msg: String = s.get("start_message", "")
	if msg != "":
		Withdrawal.post_message(msg)


func _process(_delta: float) -> void:
	# Under the influence: grey, soft, muffled (sound is done by Withdrawal/Settings).
	_post.set_shader_parameter("numb", Withdrawal.influence_strength())

	# Ringing ears: from Config.SYMPTOM_START, louder the worse it gets.
	var ring := inverse_lerp(Config.SYMPTOM_START, Config.METER_MAX, Withdrawal.meter)
	if ring > 0.0:
		_ringing.volume_db = lerpf(Config.TINNITUS_SYMPTOM_MIN_DB, Config.TINNITUS_SYMPTOM_MAX_DB, ring)
		if not _ringing.playing:
			_ringing.play()
		if not _ringing_noticed:
			_ringing_noticed = true
			Withdrawal.post_message("Your ears have started ringing.")
	elif _ringing.playing:
		_ringing.stop()


## On the knees during a withdrawal episode: the next flashback the player hasn't seen.
## Afterwards he blacks out and wakes up in his room the next day. (No flashback left:
## the episode blacks out by itself after kneeling.)
func _play_next_flashback() -> void:
	for fb in FLASHBACKS:
		if fb[0] in Recovery.flashbacks_seen:
			continue
		await Game.play_cutscene(fb[1], true)
		Recovery.see_flashback(fb[0])
		if Recovery.flashbacks_seen.size() == FLASHBACKS.size():
			await Game.play_cutscene(TheVisit, true)   # now he knows: she comes to see him
		_episode.black_out(fb[2])
		return


func _bake_navigation(region: NavigationRegion3D) -> void:
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.agent_radius = Config.NAV_AGENT_RADIUS
	nm.agent_height = Config.NAV_AGENT_HEIGHT
	nm.agent_max_climb = 0.25
	region.navigation_mesh = nm
	region.bake_navigation_mesh(false)
