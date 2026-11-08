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


## A scream: rising, harsh, with tyres screeching underneath (no loop).
static func scream() -> AudioStreamWAV:
	var n := int(RATE * 1.4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phase := 0.0
	var band := 0.0
	for i in n:
		var t := float(i) / RATE
		var freq := 700.0 + 500.0 * minf(t / 0.3, 1.0) + sin(TAU * 7.0 * t) * 40.0
		phase += TAU * freq / RATE
		var voice := (fposmod(phase / TAU, 1.0) * 2.0 - 1.0) * 0.35 + sin(phase * 2.0) * 0.15
		band = band * 0.7 + rng.randf_range(-1.0, 1.0) * 0.3
		var tyres := band * 0.5 * clampf((t - 0.2) / 0.2, 0.0, 1.0)
		var env := clampf(t / 0.05, 0.0, 1.0) * clampf((1.4 - t) / 0.3, 0.0, 1.0)
		samples[i] = (voice + tyres) * env
	var w := _make(samples)
	w.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return w


## Car horn: two flat tones (no loop).
static func horn() -> AudioStreamWAV:
	var n := int(RATE * 1.0)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		var s := signf(sin(TAU * 415.0 * t)) * 0.2 + signf(sin(TAU * 523.0 * t)) * 0.2
		samples[i] = s * clampf((1.0 - t) / 0.1, 0.0, 1.0)
	var w := _make(samples)
	w.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return w


## Steady rain (loop).
static func rain() -> AudioStreamWAV:
	var n := RATE * 2
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var samples := PackedFloat32Array()
	samples.resize(n)
	var soft := 0.0
	for i in n:
		soft = soft * 0.6 + rng.randf_range(-1.0, 1.0) * 0.4
		var drop := rng.randf_range(-1.0, 1.0) * 0.6 if rng.randf() < 0.002 else 0.0
		samples[i] = soft * 0.45 + drop
	return _make(samples)


const LOFI_RATE := 8000   # music is lo-fi on purpose (and quicker to generate)

static var _cache := {}


static func _note_hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## Hospital background music: slow, sad, slightly wobbly pads (Am - Fmaj7 - Cmaj7 - Em)
## with a few soft piano notes on top. Loops. Generated once, then cached.
static func hospital_music() -> AudioStreamWAV:
	if _cache.has("hospital_music"):
		return _cache["hospital_music"]
	var chords := [[45, 52, 57, 60, 64], [41, 48, 53, 57, 64], [36, 48, 52, 55, 59], [40, 47, 52, 55, 59]]
	var melody := [[0.6, 76], [2.2, 72], [3.1, 71], [4.6, 69], [6.4, 72], [8.6, 67], [10.2, 71], [12.5, 64], [14.1, 67]]
	var seg := 4.0
	var n := int(LOFI_RATE * seg * chords.size())
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phases := PackedFloat32Array()
	phases.resize(5)
	for i in n:
		var t := float(i) / LOFI_RATE
		var ci := int(t / seg)
		var local := fmod(t, seg)
		var swell := sin(PI * local / seg)
		var wobble := 1.0 + sin(TAU * 0.4 * t) * 0.003   # worn tape
		var s := 0.0
		var chord: Array = chords[ci]
		for v in chord.size():
			phases[v] += TAU * _note_hz(chord[v]) * wobble / LOFI_RATE
			s += (sin(phases[v]) + 0.25 * sin(phases[v] * 3.0)) * 0.07
		s *= 0.35 + 0.65 * swell
		for m in melody:
			var dt: float = t - m[0]
			if dt >= 0.0 and dt < 2.5:
				var f := _note_hz(m[1])
				s += (sin(TAU * f * dt) + 0.3 * sin(TAU * 2.0 * f * dt)) * exp(-dt * 2.2) * 0.12
		samples[i] = s
	var w := _make(samples, LOFI_RATE)
	_cache["hospital_music"] = w
	return w


## An old song on a small radio: a simple waltz through a tinny speaker, with crackle.
static func radio_song() -> AudioStreamWAV:
	if _cache.has("radio_song"):
		return _cache["radio_song"]
	var tune := [67, 72, 76, 74, 72, 71, 72, 74, 76, 79, 77, 76, 74, 72, 71, 72]
	var beat := 0.5
	var n := int(LOFI_RATE * beat * tune.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / LOFI_RATE
		var k := int(t / beat)
		var dt := fmod(t, beat)
		var f := _note_hz(tune[k])
		var s := signf(sin(TAU * f * t)) * 0.12 * exp(-dt * 3.0)
		s += sin(TAU * _note_hz(tune[k] - 24) * t) * 0.12 * (1.0 if k % 3 == 0 else 0.5)   # oom-pah-pah
		if rng.randf() < 0.004:
			s += rng.randf_range(-0.5, 0.5)   # crackle
		s += rng.randf_range(-0.02, 0.02)
		samples[i] = s
	var w := _make(samples, LOFI_RATE)
	_cache["radio_song"] = w
	return w


## A TV left on: static hiss with a murmur of voices.
static func tv() -> AudioStreamWAV:
	var n := LOFI_RATE * 2
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	var samples := PackedFloat32Array()
	samples.resize(n)
	var voice := 0.0
	for i in n:
		var t := float(i) / LOFI_RATE
		voice = voice * 0.9 + rng.randf_range(-1.0, 1.0) * 0.1
		var syllables := maxf(0.0, sin(TAU * 3.1 * t) * sin(TAU * 0.5 * t))
		samples[i] = rng.randf_range(-1.0, 1.0) * 0.08 + voice * 1.6 * syllables + sin(TAU * 60.0 * t) * 0.03
	return _make(samples, LOFI_RATE)


## Running tap water.
static func water() -> AudioStreamWAV:
	var n := LOFI_RATE * 2
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	var samples := PackedFloat32Array()
	samples.resize(n)
	var lp := 0.0
	for i in n:
		lp = lp * 0.5 + rng.randf_range(-1.0, 1.0) * 0.5
		samples[i] = lp * 0.4
	return _make(samples, LOFI_RATE)


## A music box playing a few notes of a lullaby (no loop). For the girl's apparitions.
static func music_box() -> AudioStreamWAV:
	if _cache.has("music_box"):
		return _cache["music_box"]
	var notes := [[0.0, 79], [0.4, 76], [0.8, 79], [1.2, 76], [1.6, 74], [2.0, 76], [2.4, 72]]
	var n := int(LOFI_RATE * 4.0)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / LOFI_RATE
		var s := 0.0
		for m in notes:
			var dt: float = t - m[0]
			if dt >= 0.0 and dt < 1.6:
				var f := _note_hz(m[1])
				s += (sin(TAU * f * dt) + 0.4 * sin(TAU * 3.0 * f * dt)) * exp(-dt * 3.5) * 0.25
		samples[i] = s
	var w := _make(samples, LOFI_RATE)
	w.loop_mode = AudioStreamWAV.LOOP_DISABLED
	_cache["music_box"] = w
	return w


## An old phone ringing: two tones, ring-ring, pause (loop, 4 s).
static func phone_ring() -> AudioStreamWAV:
	var n := LOFI_RATE * 4
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / LOFI_RATE
		var on := (t < 0.4) or (t > 0.6 and t < 1.0)
		var bell := signf(sin(TAU * 20.0 * t)) * 0.5 + 0.5   # the bell's clatter
		samples[i] = (sin(TAU * 440.0 * t) + sin(TAU * 480.0 * t)) * 0.25 * bell if on else 0.0
	return _make(samples, LOFI_RATE)


static func _make(samples: PackedFloat32Array, rate := RATE) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = samples.size()
	return w
