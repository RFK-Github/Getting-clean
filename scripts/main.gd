extends Node3D
## Assembles the game: environment/fog, level, navigation, player, post-processing, HUD, hallucination and menu.

const Player := preload("res://scripts/player.gd")
const TestLevel := preload("res://scripts/levels/test_level.gd")
const Hud := preload("res://scripts/hud.gd")
const Hallucination := preload("res://scripts/hallucination.gd")
const PauseMenu := preload("res://scripts/pause_menu.gd")
const Audio := preload("res://scripts/audio.gd")
const POST_SHADER := preload("res://shaders/post.gdshader")


func _ready() -> void:
	_make_environment()

	var region := NavigationRegion3D.new()
	add_child(region)
	var level := TestLevel.new()
	region.add_child(level)
	level.build()
	_bake_navigation(region)

	var player := Player.new()
	add_child(player)
	player.global_transform = level.bed_spawn

	var post := _make_post_effect()

	var hud := Hud.new()
	hud.player = player
	add_child(hud)
	player.prompt_changed.connect(hud.set_prompt)

	var hallucination := Hallucination.new()
	hallucination.player = player
	hallucination.bed_spawn = level.bed_spawn
	hallucination.post_material = post
	add_child(hallucination)

	add_child(PauseMenu.new())

	var hum := AudioStreamPlayer.new()
	hum.stream = Audio.hum()
	hum.volume_db = Config.AMBIENT_HUM_DB
	add_child(hum)
	hum.play()

	Withdrawal.post_message("Night. You can't sleep. You want to get clean. For her.")


func _make_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Config.FOG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Config.AMBIENT_COLOR
	env.ambient_light_energy = Config.AMBIENT_ENERGY
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Config.FOG_COLOR
	env.fog_density = Config.FOG_DENSITY
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _bake_navigation(region: NavigationRegion3D) -> void:
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.agent_radius = 0.5
	nm.agent_height = 2.0
	nm.agent_max_climb = 0.25
	region.navigation_mesh = nm
	region.bake_navigation_mesh(false)


func _make_post_effect() -> ShaderMaterial:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	var mat := ShaderMaterial.new()
	mat.shader = POST_SHADER
	mat.set_shader_parameter("tint", Vector3(Config.TINT_COLOR.r, Config.TINT_COLOR.g, Config.TINT_COLOR.b))
	mat.set_shader_parameter("tint_strength", Config.TINT_STRENGTH)
	mat.set_shader_parameter("color_depth", Config.COLOR_DEPTH)
	mat.set_shader_parameter("dither_strength", Config.DITHER_STRENGTH)
	mat.set_shader_parameter("vignette", Config.VIGNETTE)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = mat
	layer.add_child(rect)
	return mat
