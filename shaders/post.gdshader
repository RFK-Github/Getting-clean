shader_type canvas_item;

// Post-processing: tint, colour reduction, dither, vignette, plus effects:
// hallucination, headache (withdrawal episode), numb (under the influence) and fade.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 tint = vec3(0.85, 1.0, 0.5);
uniform float tint_strength = 0.6;
uniform float color_depth = 20.0;
uniform float dither_strength = 1.0;
uniform float vignette = 0.7;
uniform float hallucination = 0.0;  // colour/chromatic effect 0..1
uniform float wobble = 0.0;         // wavy distortion 0..1
uniform float headache = 0.0;       // pulsing dark-red vignette + blur 0..1
uniform float numb = 0.0;           // grey, soft, distant 0..1
uniform float fade = 0.0;
uniform vec3 fade_color : source_color = vec3(0.0);

float bayer4(vec2 p) {
	float b[16] = {0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0};
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	return b[x + y * 4] / 16.0 - 0.5;
}

vec3 blur9(vec2 uv, vec2 px) {
	vec3 s = vec3(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			s += texture(screen_tex, uv + vec2(float(x), float(y)) * px).rgb;
		}
	}
	return s / 9.0;
}

void fragment() {
	// Heartbeat pulse, ~72 bpm
	float pulse = pow(0.5 + 0.5 * sin(TIME * 7.5), 3.0);

	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y * 38.0 + TIME * 5.0) * 0.005 * wobble;
	uv.y += sin(uv.x * 23.0 + TIME * 3.0) * 0.003 * wobble;
	vec3 c = texture(screen_tex, uv).rgb;

	float blur = numb * 1.2;   // (withdrawal episodes no longer blur: just the ringing and a dark vignette)
	if (blur > 0.01) {
		c = mix(c, blur9(uv, SCREEN_PIXEL_SIZE * blur), clamp(blur, 0.0, 1.0));
	}

	if (hallucination > 0.0) {
		float r = texture(screen_tex, uv + vec2(0.008 * hallucination, 0.0)).r;
		c.r = mix(c.r, r, 0.8);
		c = mix(c, c * vec3(1.35, 0.7, 0.6), hallucination * 0.6);
	}

	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(lum) * 0.92, numb * 0.7);   // drugs: the world goes grey and flat
	c = mix(c, lum * tint * 1.4, tint_strength);

	float d = length(SCREEN_UV - 0.5);
	float vig = smoothstep(0.35, 0.8, d) * vignette * (1.0 + hallucination * 0.5 + numb * 0.4);
	c *= 1.0 - vig;
	float ache = smoothstep(0.2, 0.8, d) * headache * 0.6;   // steady, no pulsing
	c = mix(c, c * vec3(0.45, 0.12, 0.1), clamp(ache, 0.0, 0.9));

	c += bayer4(FRAGCOORD.xy) * dither_strength / color_depth;
	c = floor(c * color_depth + 0.5) / color_depth;

	c = mix(c, fade_color, fade);
	COLOR = vec4(c, 1.0);
}
