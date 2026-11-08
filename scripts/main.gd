extends Node3D
## Assembles the current level (Game.current_level): environment/fog, level geometry,
## navigation, player, post-processing, HUD, withdrawal episodes, hallucinations and pause menu.

const Player := preload("res://scripts/player.gd")
const Hud := preload("res://scripts/hud.gd")
const Hallucination := preload("res://scripts/hallucination.gd")
const Episode := preload("res://scripts/episode.gd")
const PauseMenu := preload("res://scripts/pause_menu.gd")
const POST_SHADER := preload("res://shaders/post.gdshader")

const LEVELS := {
	"philadelphia": preload("res://scripts/levels/philadelphia.gd"),
	"hospital": preload("res://scripts/levels/hospital.gd"),
}

var _post: ShaderMaterial


func _ready() -> void:
	Withdrawal.state = ""  # nothing carries over mid-episode from a previous level
	var level_script: GDScript = LEVELS.get(Game.current_level, LEVELS["philadelphia"])
	var level: Node3D = level_script.new()
	var s: Dictionary = level.get_settings()

	_make_environment(s)

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

	var post := _make_post_effect(s)
	_post = post

	var hud := Hud.new()
	hud.player = player
	add_child(hud)
	player.prompt_changed.connect(hud.set_prompt)

	if s.get("hallucinations", false):
		var hallucination := Hallucination.new()
		hallucination.player = player
		hallucination.bed_spawn = level.bed_spawn if level.bed_spawn != Transform3D.IDENTITY else level.spawn
		hallucination.post_material = post
		add_child(hallucination)

	if s.get("episodes", false):
		var episode := Episode.new()
		episode.player = player
		episode.post_material = post
		add_child(episode)

	add_child(PauseMenu.new())

	var msg: String = s.get("start_message", "")
	if msg != "":
		Withdrawal.post_message(msg)


func _process(_delta: float) -> void:
	# Under the influence: grey, soft, muffled (sound is done by Withdrawal/Settings).
	_post.set_shader_parameter("numb", Withdrawal.influence_strength())


func _make_environment(s: Dictionary) -> void:
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
	add_child(we)


func _bake_navigation(region: NavigationRegion3D) -> void:
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.agent_radius = Config.NAV_AGENT_RADIUS
	nm.agent_height = Config.NAV_AGENT_HEIGHT
	nm.agent_max_climb = 0.25
	region.navigation_mesh = nm
	region.bake_navigation_mesh(false)


func _make_post_effect(s: Dictionary) -> ShaderMaterial:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	var tint: Color = s.get("tint", Color.WHITE)
	var mat := ShaderMaterial.new()
	mat.shader = POST_SHADER
	mat.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	mat.set_shader_parameter("tint_strength", s.get("tint_strength", 0.0))
	mat.set_shader_parameter("color_depth", Config.COLOR_DEPTH)
	mat.set_shader_parameter("dither_strength", Config.DITHER_STRENGTH)
	mat.set_shader_parameter("vignette", Config.VIGNETTE)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = mat
	layer.add_child(rect)
	return mat
