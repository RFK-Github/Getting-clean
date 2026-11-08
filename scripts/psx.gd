extends RefCounted
## Creates materials using the PSX shader.

const SHADER := preload("res://shaders/psx.gdshader")
const Cfg := preload("res://scripts/config.gd")


static func material(tex: Texture2D, color := Color.WHITE, uv_scale := Cfg.TEXTURE_SCALE,
		world_uv := true, emission := Color.BLACK) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("albedo_tex", tex)
	m.set_shader_parameter("albedo_color", color)
	m.set_shader_parameter("emission_color", emission)
	m.set_shader_parameter("use_world_uv", world_uv)
	m.set_shader_parameter("uv_scale", uv_scale)
	m.set_shader_parameter("snap_resolution", Cfg.VERTEX_SNAP)
	m.set_shader_parameter("affine_strength", Cfg.AFFINE_STRENGTH)
	return m
