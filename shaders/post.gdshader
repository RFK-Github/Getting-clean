shader_type canvas_item;

// Post-processing: green-yellow tint, colour reduction, dither, vignette, hallucination and fade.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 tint = vec3(0.85, 1.0, 0.5);
uniform float tint_strength = 0.6;
uniform float color_depth = 20.0;
uniform float dither_strength = 1.0;
uniform float vignette = 0.7;
uniform float hallucination = 0.0;  // colour/chromatic effect 0..1
uniform float wobble = 0.0;         // wavy distortion 0..1
uniform float fade = 0.0;
uniform vec3 fade_color : source_color = vec3(0.0);

float bayer4(vec2 p) {
	float b[16] = {0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0};
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	return b[x + y * 4] / 16.0 - 0.5;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y * 38.0 + TIME * 5.0) * 0.005 * wobble;
	uv.y += sin(uv.x * 23.0 + TIME * 3.0) * 0.003 * wobble;
	vec3 c = texture(screen_tex, uv).rgb;

	if (hallucination > 0.0) {
		float r = texture(screen_tex, uv + vec2(0.008 * hallucination, 0.0)).r;
		c.r = mix(c.r, r, 0.8);
		c = mix(c, c * vec3(1.35, 0.7, 0.6), hallucination * 0.6);
	}

	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, lum * tint * 1.4, tint_strength);

	float d = length(SCREEN_UV - 0.5);
	c *= 1.0 - smoothstep(0.35, 0.8, d) * vignette * (1.0 + hallucination * 0.5);

	c += bayer4(FRAGCOORD.xy) * dither_strength / color_depth;
	c = floor(c * color_depth + 0.5) / color_depth;

	c = mix(c, fade_color, fade);
	COLOR = vec4(c, 1.0);
}
