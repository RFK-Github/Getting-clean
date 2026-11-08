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


## Distant city traffic: low brown noise with slow swells (loop).
static func traffic() -> AudioStreamWAV:
	var n := RATE * 4
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var samples := PackedFloat32Array()
	samples.resize(n)
	var brown := 0.0
	for i in n:
		var t := float(i) / RATE
		brown = brown * 0.995 + rng.randf_range(-1.0, 1.0) * 0.05
		var swell := 0.7 + 0.3 * sin(TAU * 0.25 * t)  # 4 s period = seamless loop
		samples[i] = brown * 0.8 * swell
	return _make(samples)


## Far-off siren: rising and falling wail (plays 3 cycles, no loop).
static func siren() -> AudioStreamWAV:
	var cycle := 2.0
	var n := int(RATE * cycle * 3)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var freq := 650.0 + 350.0 * (0.5 - 0.5 * cos(TAU * t / cycle))
		phase += TAU * freq / RATE
		var env := clampf(t / 0.5, 0.0, 1.0) * clampf((cycle * 3 - t) / 0.8, 0.0, 1.0)
		samples[i] = (sin(phase) * 0.6 + sin(phase * 2.0) * 0.15) * env
	var w := _make(samples)
	w.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return w


## Elevated train: heavy low rumble with wheel clacks (loop).
static func rumble() -> AudioStreamWAV:
	var n := RATE * 3
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var samples := PackedFloat32Array()
	samples.resize(n)
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		low = low * 0.98 + rng.randf_range(-1.0, 1.0) * 0.08
		var s := low * 1.5 + sin(TAU * 45.0 * t) * 0.25
		var since_clack := fmod(t, 0.375)
		if since_clack < 0.06:
			s += rng.randf_range(-1.0, 1.0) * 0.5 * (1.0 - since_clack / 0.06)
		samples[i] = s
	return _make(samples)


## Short unsettling swell for the figure in the fog (no loop).
static func sting() -> AudioStreamWAV:
	var n := int(RATE * 1.2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := clampf(t / 0.15, 0.0, 1.0) * pow(1.0 - t / 1.2, 2.0)
		var s := sin(TAU * 311.0 * t) * 0.3 + sin(TAU * 329.6 * t) * 0.3 + sin(TAU * 466.0 * t) * 0.2
		s += rng.randf_range(-1.0, 1.0) * 0.2
		samples[i] = s * env
	var w := _make(samples)
	w.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return w


## Ringing in the ears: high, slightly beating tone (loop).
static func tinnitus() -> AudioStreamWAV:
	var n := RATE * 3
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		samples[i] = sin(TAU * 3800.0 * t) * 0.2 + sin(TAU * 3803.0 * t) * 0.15 + sin(TAU * 1900.0 * t) * 0.05
	return _make(samples)


## Heavy heartbeat, lub-dub at 75 bpm (loop).
static func heartbeat() -> AudioStreamWAV:
	var n := int(RATE * 0.8)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		for beat in [[0.0, 1.0], [0.22, 0.7]]:
			var dt: float = t - beat[0]
			if dt >= 0.0 and dt < 0.15:
				s += sin(TAU * 50.0 * dt) * exp(-dt * 30.0) * beat[1]
		samples[i] = s * 0.9
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
