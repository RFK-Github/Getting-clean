extends CanvasLayer
## Shows an in-engine cutscene over the game: its own 3D world in a SubViewport at the
## internal resolution, the same PS1 post effect, subtitles, and fades. Pauses the game.
## E skips (after Config.CUTSCENE_SKIP_AFTER seconds). Used through Game.play_cutscene().

var _scene: Node3D
var _container: SubViewportContainer
var _fade: ColorRect
var _skippable := false


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS


## end_black: stay black and paused afterwards (the endings show an end card next).
func play(scene_script: GDScript, end_black := false) -> void:
	var tree := get_tree()
	tree.paused = true

	_container = SubViewportContainer.new()
	_container.stretch = true
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_container)
	var viewport := SubViewport.new()
	viewport.size = Config.INTERNAL_RESOLUTION
	viewport.own_world_3d = true
	viewport.audio_listener_enable_3d = true
	_container.add_child(viewport)

	_scene = scene_script.new()
	var s: Dictionary = _scene.get_settings()
	var env: WorldEnvironment = _scene.make_environment(s)
	viewport.add_child(env)
	_scene.world_env = env
	viewport.add_child(_scene)

	var post := ColorRect.new()
	post.set_anchors_preset(Control.PRESET_FULL_RECT)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post.material = _scene.make_post_material(s)
	add_child(post)

	var subtitle := Label.new()
	subtitle.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	subtitle.offset_top = -90
	subtitle.offset_bottom = -24
	subtitle.offset_left = 40
	subtitle.offset_right = -40
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE)
	subtitle.add_theme_color_override("font_color", Color(0.92, 0.9, 0.85))
	subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	subtitle.add_theme_constant_override("shadow_offset_x", 1)
	subtitle.add_theme_constant_override("shadow_offset_y", 1)
	add_child(subtitle)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	_scene.subtitle_label = subtitle
	_scene.fade_rect = _fade
	_scene.post_material = post.material
	_scene.build()
	_scene.cam.current = true

	var fade_in := create_tween()
	fade_in.tween_property(_fade, "color:a", 0.0, Config.CUTSCENE_FADE_TIME)
	get_tree().create_timer(Config.CUTSCENE_SKIP_AFTER, true).timeout.connect(func(): _skippable = true)

	await _scene.finished
	_skippable = false

	# Back to the game: fade to black, remove the scene, fade the game back in.
	var out := create_tween()
	out.tween_property(_fade, "color", Color(0, 0, 0, 1), Config.CUTSCENE_FADE_TIME * 0.5)
	await out.finished
	_container.queue_free()
	post.queue_free()
	subtitle.queue_free()
	if end_black:
		return
	tree.paused = false
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, Config.CUTSCENE_FADE_TIME)
	await back.finished


func _input(event: InputEvent) -> void:
	if _scene == null or not is_instance_valid(_scene):
		return
	if _skippable and event.is_action_pressed("interact"):
		_skippable = false
		_scene.skip()
	get_viewport().set_input_as_handled()
