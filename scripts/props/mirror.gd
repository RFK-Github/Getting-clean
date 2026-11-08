extends Node3D
## A real-time mirror. A second camera sits at the player's camera position reflected
## through the mirror plane and renders into a small texture (PS1 resolution).
## The mirror faces local +Z. Visual layer 2 is only seen in mirrors (the player's head).

var size := Vector2(0.64, 0.8)  # keep the same aspect as Config.MIRROR_RESOLUTION

var _viewport: SubViewport
var _cam: Camera3D

const SHADER_CODE := """
shader_type spatial;
render_mode unshaded;
uniform sampler2D reflection : filter_nearest;
void fragment() {
	ALBEDO = texture(reflection, vec2(1.0 - UV.x, UV.y)).rgb * 0.9;
}
"""


func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Config.MIRROR_RESOLUTION
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)

	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_FRUSTUM
	_cam.keep_aspect = Camera3D.KEEP_HEIGHT
	_cam.cull_mask = 0xFFFFF  # sees layer 2 (player's head) too
	_viewport.add_child(_cam)

	var shader := Shader.new()
	shader.code = SHADER_CODE
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("reflection", _viewport.get_texture())
	var quad := QuadMesh.new()
	quad.size = size
	quad.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var eye: Camera3D = player.get("camera")
	var local := to_local(eye.global_position)
	var near := local.z
	if near < 0.05 or local.length() > Config.MIRROR_UPDATE_DISTANCE:
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Reflected eye: same x/y, mirrored z. Camera looks out of the mirror (toward local +Z).
	var reflected := Vector3(local.x, local.y, -local.z)
	_cam.global_transform = Transform3D(global_basis.rotated(global_basis.y.normalized(), PI), to_global(reflected))
	# Off-centre frustum that exactly covers the mirror quad.
	_cam.set_frustum(size.y, Vector2(local.x, -local.y), near, 30.0)
