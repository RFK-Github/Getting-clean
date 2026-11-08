extends CanvasLayer
## HUD: withdrawal meter (bottom left), stamina bar (bottom centre), memories,
## interaction prompt and messages. Layout uses anchors, so it follows the internal resolution.

const BAR_W := 128.0
const STAMINA_W := 160.0
const TEXT_COLOR := Color(0.8, 0.85, 0.65)

var player: Node  # set by main (needs stamina / max_stamina / sprinting)

var _fill: ColorRect
var _meter_label: Label
var _stamina_root: Control
var _stamina_fill: ColorRect
var _stamina_lost: ColorRect
var _items: Label
var _prompt: Label
var _msg: Label
var _help: Label
var _msg_time := 0.0
var _help_time: float = Config.HELP_TEXT_DURATION
var _stamina_hide := 0.0


func _ready() -> void:
	layer = 2
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font_size = Config.UI_FONT_SIZE
	root.theme = th
	add_child(root)

	# Withdrawal meter, bottom left
	_meter_label = _label(root, "WITHDRAWAL", Vector2(0, 1), Vector2(16, -42), Vector2(160, 20))
	var bar_bg := _rect(root, Color(0.04, 0.05, 0.03), Vector2(0, 1), Vector2(16, -20), Vector2(BAR_W + 2, 10))
	_fill = _rect(bar_bg, Color.WHITE, Vector2.ZERO, Vector2(1, 1), Vector2(0, 8))
	var tick_x := 1 + round(BAR_W * Config.HALLUCINATION_THRESHOLD / Config.METER_MAX)
	_rect(bar_bg, Color(0.5, 0.5, 0.4), Vector2.ZERO, Vector2(tick_x, 0), Vector2(1, 10))

	# Stamina, bottom centre
	_stamina_root = _rect(root, Color(0.04, 0.05, 0.03, 0.8), Vector2(0.5, 1), Vector2(-STAMINA_W / 2 - 1, -18), Vector2(STAMINA_W + 2, 6))
	_stamina_lost = _rect(_stamina_root, Color(0.3, 0.1, 0.08), Vector2.ZERO, Vector2(1, 1), Vector2(0, 4))
	_stamina_fill = _rect(_stamina_root, Color(0.75, 0.78, 0.6), Vector2.ZERO, Vector2(1, 1), Vector2(0, 4))

	# Memories, top right
	_items = _label(root, "", Vector2(1, 0), Vector2(-216, 12), Vector2(200, 20))
	_items.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Crosshair dot
	_rect(root, Color(0.8, 0.85, 0.65, 0.5), Vector2(0.5, 0.5), Vector2(-1, -1), Vector2(3, 3))

	_prompt = _label(root, "", Vector2(0.5, 0.5), Vector2(-200, 40), Vector2(400, 20))
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_msg = _label(root, "", Vector2(0.5, 0.5), Vector2(-260, 90), Vector2(520, 80))
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_help = _label(root, "WASD move   Shift sprint   F flashlight   E interact   ESC menu",
		Vector2(0, 0), Vector2(16, 12), Vector2(500, 20))
	_help.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE_SMALL)

	Withdrawal.message_posted.connect(_on_message)
	Withdrawal.items_changed.connect(_update_items)
	_update_items()


func set_prompt(text: String) -> void:
	_prompt.text = text


func _process(delta: float) -> void:
	# Withdrawal
	var t := Withdrawal.meter / Config.METER_MAX
	_fill.size.x = round(BAR_W * t)
	var c := Color(0.6, 0.7, 0.3).lerp(Color(0.75, 0.15, 0.1), t)
	var high := Withdrawal.meter >= Config.HALLUCINATION_THRESHOLD
	if high and fmod(Time.get_ticks_msec() / 1000.0 * 5.0, 1.0) < 0.3:
		c = Color(0.9, 0.85, 0.7)
	if Withdrawal.is_influenced():
		c = c.lerp(Color(0.45, 0.45, 0.45), 0.8)  # numb: the meter goes grey too
	_fill.color = c
	_meter_label.offset_left = 16 + (randi_range(-1, 1) if high else 0)

	# Stamina: hidden when full, darker segment = what withdrawal has taken away
	if player != null:
		var stamina: float = player.get("stamina")
		var max_stamina: float = player.get("max_stamina")
		_stamina_fill.size.x = round(STAMINA_W * stamina / Config.STAMINA_MAX)
		_stamina_lost.position.x = 1 + round(STAMINA_W * max_stamina / Config.STAMINA_MAX)
		_stamina_lost.size.x = STAMINA_W - (_stamina_lost.position.x - 1)
		if stamina < max_stamina - 0.5 or player.get("sprinting"):
			_stamina_hide = Config.STAMINA_BAR_HIDE_DELAY
		else:
			_stamina_hide = maxf(0.0, _stamina_hide - delta)
		_stamina_root.modulate.a = clampf(_stamina_hide / 0.5, 0.0, 1.0)

	_msg_time = maxf(0.0, _msg_time - delta)
	_msg.modulate.a = clampf(_msg_time, 0.0, 1.0)
	_help_time = maxf(0.0, _help_time - delta)
	_help.modulate.a = clampf(_help_time / 2.0, 0.0, 1.0)


func _on_message(text: String) -> void:
	_msg.text = text
	_msg_time = Config.MESSAGE_DURATION


func _update_items() -> void:
	_items.text = "MEMORIES %d/%d" % [Withdrawal.found_items.size(), Config.ITEMS_TOTAL]


## Places a control at an anchor point (0..1 of the screen) plus a pixel offset.
func _place(c: Control, anchor: Vector2, offset: Vector2, size: Vector2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = offset.x
	c.offset_top = offset.y
	c.offset_right = offset.x + size.x
	c.offset_bottom = offset.y + size.y


func _rect(parent: Control, color: Color, anchor: Vector2, offset: Vector2, size: Vector2) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	_place(r, anchor, offset, size)
	return r


func _label(parent: Control, text: String, anchor: Vector2, offset: Vector2, size: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", TEXT_COLOR)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(l)
	_place(l, anchor, offset, size)
	return l
