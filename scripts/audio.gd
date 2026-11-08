extends RefCounted
## Placeholder sounds generated in code.

const RATE := 22050


## Loud, piercing hallucination sound (loop).
static func screech() -> AudioStreamWAV:
	var n := RATE * 2
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		var trem := 0.6 + 0.4 * sin(TAU * 7.0 * t)
		var s := (fposmod(t * 220.0, 1.0) * 2.0 - 1.0) * 0.3
		s += (fposmod(t * 233.0, 1.0) * 2.0 - 1.0) * 0.3
		s += sin(TAU * 880.0 * t + 6.0 * sin(TAU * 3.0 * t)) * 0.2
		s += rng.randf_range(-1.0, 1.0) * 0.25
		samples[i] = s * trem
	return _make(samples)


## Low electrical hum from fluorescent lights (loop).
static func hum() -> AudioStreamWAV:
	var n := RATE
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		samples[i] = sin(TAU * 50.0 * t) * 0.5 + sin(TAU * 100.0 * t) * 0.25 + rng.randf_range(-1.0, 1.0) * 0.05
	return _make(samples)


static func _make(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = samples.size()
	return w
