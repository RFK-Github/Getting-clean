extends RefCounted
## Small low-res textures generated in code (no asset files needed).

static var _cache: Dictionary = {}


static func get_texture(kind: String) -> Texture2D:
	if _cache.has(kind):
		return _cache[kind]
	var img: Image
	match kind:
		"drawing":
			img = _drawing()
		"photo":
			img = _photo()
		"puff":
			img = _radial(16, 0.9)
		"sun":
			img = _radial(32, 1.6)
		_:
			img = _pattern(kind)
	var tex := ImageTexture.create_from_image(img)
	_cache[kind] = tex
	return tex


static func _pattern(kind: String) -> Image:
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var stains: Array[int] = []
	for i in 4:
		stains.append(rng.randi_range(0, 31))
	for y in 32:
		for x in 32:
			var n := rng.randf_range(-1.0, 1.0)
			var amt := 0.04
			var c := Color(0.5, 0.5, 0.5)
			match kind:
				"tiles":
					var check := ((x >> 4) + (y >> 4)) % 2 == 0
					c = Color(0.62, 0.64, 0.55) if check else Color(0.55, 0.58, 0.5)
					if x % 16 == 0 or y % 16 == 0:
						c = Color(0.3, 0.32, 0.27)
				"wall":
					c = Color(0.55, 0.58, 0.47)
					if stains.has(x) and y < 18 + (x % 9):
						c = c.darkened(0.15)
					amt = 0.05
				"ceiling":
					c = Color(0.5, 0.5, 0.46)
					if x % 16 == 0 or y % 16 == 0:
						c = Color(0.32, 0.32, 0.3)
				"wood":
					c = Color(0.38, 0.26, 0.15).darkened(0.15 * (0.5 + 0.5 * sin(y * 1.7 + sin(x * 0.3) * 2.0)))
				"carpet":
					c = Color(0.3, 0.3, 0.2)
					amt = 0.08
				"metal":
					c = Color(0.42, 0.45, 0.43)
					amt = 0.03
				"fabric":
					c = Color(0.3, 0.33, 0.38)
					if (x + y) % 4 == 0:
						c = c.darkened(0.15)
				"door":
					c = Color(0.35, 0.38, 0.3)
					if y == 2 or y == 29 or x == 2 or x == 29:
						c = c.darkened(0.3)
				"plain":
					c = Color.WHITE
					amt = 0.0
				"brick", "brick_window":
					c = _brick(x, y)
					if kind == "brick_window":
						c = _window(x, y, c, Color(0.62, 0.56, 0.48))
					amt = 0.03
				"concrete", "concrete_window":
					c = Color(0.62, 0.58, 0.5)
					if y % 16 == 0:
						c = c.darkened(0.2)
					if kind == "concrete_window":
						c = _window(x, y, c, Color(0.5, 0.5, 0.48))
				"asphalt":
					c = Color(0.2, 0.2, 0.21)
					if stains.has(x) and absi(y - x) < 2:
						c = Color(0.13, 0.13, 0.13)
					amt = 0.06
				"sidewalk":
					c = Color(0.48, 0.46, 0.42)
					if x % 16 == 0 or y % 16 == 0:
						c = Color(0.32, 0.31, 0.28)
					amt = 0.05
				"tower":
					c = Color(0.22, 0.24, 0.27)
					if x % 8 >= 2 and x % 8 <= 6 and y % 8 >= 2 and y % 8 <= 6:
						c = Color(0.32, 0.36, 0.4)
						if hash(Vector2i(x >> 3, y >> 3)) % 9 == 0:
							c = Color(0.85, 0.7, 0.45)
					amt = 0.02
				"shutter":
					c = Color(0.4, 0.42, 0.4) if y % 4 < 2 else Color(0.3, 0.32, 0.3)
					if stains.has(x):
						c = Color(0.35, 0.25, 0.18)  # rust streak
					amt = 0.03
				"car":
					c = Color(0.8, 0.8, 0.8)
					amt = 0.02
				"linoleum":
					c = Color(0.72, 0.76, 0.7) if ((x >> 4) + (y >> 4)) % 2 == 0 else Color(0.66, 0.7, 0.66)
					if rng.randf() < 0.04:
						c = c.darkened(0.25)  # speckles
					if x % 16 == 0 or y % 16 == 0:
						c = c.darkened(0.12)
					amt = 0.02
				"white_wall":
					c = Color(0.86, 0.87, 0.83)
					if stains.has(x) and y > 24:
						c = c.darkened(0.06)
					amt = 0.015
				"pool_tile":
					c = Color(0.82, 0.88, 0.9)
					if x % 8 == 0 or y % 8 == 0:
						c = Color(0.55, 0.62, 0.65)
					amt = 0.02
				"water":
					c = Color(0.25, 0.55, 0.65)
					if (x + int(4.0 * sin(y * 0.6))) % 11 == 0:
						c = Color(0.55, 0.8, 0.85)
					amt = 0.03
				"grass":
					c = Color(0.3, 0.42, 0.2)
					if rng.randf() < 0.15:
						c = Color(0.38, 0.5, 0.24)
					amt = 0.06
				"court":
					c = Color(0.36, 0.38, 0.36)
					amt = 0.04
				"cork":
					c = Color(0.62, 0.45, 0.28)
					amt = 0.1
			c = Color(clampf(c.r + n * amt, 0.0, 1.0), clampf(c.g + n * amt, 0.0, 1.0), clampf(c.b + n * amt, 0.0, 1.0))
			img.set_pixel(x, y, c)
	return img


## Red brick: 4 px rows, 8 px bricks, every other row offset. Each brick gets its own shade.
static func _brick(x: int, y: int) -> Color:
	var row := y >> 2
	var bx := (x + (row % 2) * 4) >> 3
	if y % 4 == 3 or (x + (row % 2) * 4) % 8 == 7:
		return Color(0.42, 0.38, 0.34)  # mortar
	var shade := float(hash(Vector2i(bx, row)) % 100) / 100.0
	return Color(0.5, 0.2, 0.13).lerp(Color(0.62, 0.3, 0.2), shade)


## One window per texture tile (1 tile = one storey when uv_scale = 1/3).
## Glass at x 10..21, y 6..23 - philadelphia.gd uses these numbers to place lit windows.
static func _window(x: int, y: int, wall: Color, stone: Color) -> Color:
	if y == 24 and x >= 9 and x <= 22:
		return stone  # sill
	if y == 5 and x >= 10 and x <= 21:
		return stone.darkened(0.15)  # lintel
	if x >= 10 and x <= 21 and y >= 6 and y <= 23:
		if x == 10 or x == 21 or y == 6 or y == 23 or x == 15:
			return Color(0.25, 0.22, 0.2)  # frame
		return Color(0.07, 0.08, 0.09).lerp(Color(0.2, 0.2, 0.22), float(y - 6) / 17.0)
	return wall


## White blob with soft alpha falloff (steam puffs, sun glow).
static func _radial(size: int, power: float) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var half := size / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - half, y + 0.5 - half).length() / half
			var a := pow(clampf(1.0 - d, 0.0, 1.0), power)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return img


## A faded family photo: white border, two adults and a child on the father's shoulders.
static func _photo() -> Image:
	var w := 24
	var h := 30
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGB8)
	img.fill(Color(0.9, 0.88, 0.82))
	for y in range(2, 24):
		for x in range(2, 22):
			var sky := Color(0.55, 0.62, 0.6).lerp(Color(0.45, 0.5, 0.35), float(y) / 24.0)
			img.set_pixel(x, y, sky)
	var dad := Color(0.25, 0.22, 0.24)
	var mom := Color(0.42, 0.25, 0.28)
	var kid := Color(0.75, 0.45, 0.35)
	for y in range(9, 24):       # father
		for x in range(7, 11):
			img.set_pixel(x, y, dad)
	for y in range(6, 9):
		for x in range(8, 10):
			img.set_pixel(x, y, Color(0.7, 0.55, 0.45))
	for y in range(11, 24):      # mother
		for x in range(13, 16):
			img.set_pixel(x, y, mom)
	for y in range(8, 11):
		for x in range(13, 15):
			img.set_pixel(x, y, Color(0.72, 0.58, 0.48))
	for y in range(2, 6):        # the child on his shoulders
		for x in range(7, 11):
			img.set_pixel(x, y, kid)
	# The photo is creased right across her.
	for x in range(2, 22):
		img.set_pixel(x, 4 + x / 8, Color(0.85, 0.83, 0.78))
	return img


## The daughter's drawing: two stick figures holding hands, sun and grass.
static func _drawing() -> Image:
	var w := 48
	var h := 34
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGB8)
	img.fill(Color(0.93, 0.92, 0.85))
	var green := Color(0.3, 0.6, 0.25)
	var yellow := Color(0.95, 0.8, 0.2)
	var blue := Color(0.2, 0.3, 0.75)
	var red := Color(0.8, 0.2, 0.2)
	for x in w:
		img.set_pixel(x, h - 4, green)
		img.set_pixel(x, h - 3, green)
	for y in 9:
		for x in 9:
			if Vector2(x - 4, y - 4).length() <= 3.6:
				img.set_pixel(w - 9 + x, 2 + y, yellow)
	# Adult (blue) and child (red)
	var big_hand := _stick(img, 17, h - 5, 20, blue)
	var small_hand := _stick(img, 29, h - 5, 12, red)
	_line(img, big_hand, small_hand, Color(0.3, 0.25, 0.3))
	# Small heart above them
	for p in [Vector2i(22, 6), Vector2i(24, 6), Vector2i(21, 7), Vector2i(22, 7), Vector2i(23, 7),
			Vector2i(24, 7), Vector2i(25, 7), Vector2i(22, 8), Vector2i(23, 8), Vector2i(24, 8), Vector2i(23, 9)]:
		img.set_pixelv(p, red)
	return img


## Draws a stick figure and returns the position of its outer hand.
static func _stick(img: Image, cx: int, foot_y: int, height: int, col: Color) -> Vector2i:
	var r := maxi(2, height / 6)
	var top := foot_y - height
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			var d := Vector2(x, y).length()
			if d <= r + 0.3 and d >= r - 0.8:
				img.set_pixel(cx + x, top + r + y, col)
	var neck := top + 2 * r + 1
	var hip := foot_y - height / 3
	_line(img, Vector2i(cx, neck), Vector2i(cx, hip), col)
	_line(img, Vector2i(cx, hip), Vector2i(cx - 3, foot_y), col)
	_line(img, Vector2i(cx, hip), Vector2i(cx + 3, foot_y), col)
	var arm_y := neck + 2
	_line(img, Vector2i(cx - 4, arm_y + 2), Vector2i(cx, arm_y), col)
	_line(img, Vector2i(cx, arm_y), Vector2i(cx + 4, arm_y + 2), col)
	return Vector2i(cx + 4, arm_y + 2) if cx < 24 else Vector2i(cx - 4, arm_y + 2)


static func _line(img: Image, a: Vector2i, b: Vector2i, col: Color) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in steps + 1:
		var t := 0.0 if steps == 0 else float(i) / steps
		var p := Vector2(a).lerp(Vector2(b), t).round()
		if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
			img.set_pixel(int(p.x), int(p.y), col)
