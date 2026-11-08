extends RefCounted
## Small low-res textures generated in code (no asset files needed).

static var _cache: Dictionary = {}


static func get_texture(kind: String) -> Texture2D:
	if _cache.has(kind):
		return _cache[kind]
	var img: Image = _drawing() if kind == "drawing" else _pattern(kind)
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
			c = Color(clampf(c.r + n * amt, 0.0, 1.0), clampf(c.g + n * amt, 0.0, 1.0), clampf(c.b + n * amt, 0.0, 1.0))
			img.set_pixel(x, y, c)
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
