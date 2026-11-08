shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// PS1-style shader: vertex snapping (jitter), affine textures, nearest filter.

uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform vec3 emission_color : source_color = vec3(0.0);
uniform bool use_world_uv = true;   // planar UV from world position (for boxes)
uniform float uv_scale = 0.5;
uniform vec2 snap_resolution = vec2(160.0, 120.0);
uniform float affine_strength = 0.35;

varying vec2 v_uv;
varying vec2 v_uv_affine;
varying float v_w;

void vertex() {
	vec2 uv = UV;
	if (use_world_uv) {
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		vec3 wn = abs(normalize(MODEL_NORMAL_MATRIX * NORMAL));
		if (wn.y > 0.5) {
			uv = wp.xz;
		} else if (wn.x > 0.5) {
			uv = vec2(wp.z, -wp.y);
		} else {
			uv = vec2(wp.x, -wp.y);
		}
	}
	uv *= uv_scale;

	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 snap = snap_resolution * 0.5;
	clip.xy = floor(clip.xy / clip.w * snap + 0.5) / snap * clip.w;
	POSITION = clip;

	v_uv = uv;
	v_uv_affine = uv * clip.w;
	v_w = clip.w;
}

void fragment() {
	vec2 affine_uv = v_uv_affine / max(v_w, 0.0001);
	vec2 uv = mix(v_uv, affine_uv, affine_strength);
	vec4 tex = texture(albedo_tex, uv);
	ALBEDO = tex.rgb * albedo_color.rgb;
	EMISSION = emission_color;
}
