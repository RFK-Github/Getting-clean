extends CanvasLayer
## Inventory ("Belongings", I or Tab): the personal items you've found and the letters
## you've read. Click one to see it again. Pauses the game while open.

const StoryItems := preload("res://scripts/story_items.gd")
const Tex := preload("res://scripts/textures.gd")
const ICONS := {"drawing": "drawing", "photo": "photo", "teddy": "icon_teddy", "bracelet": "icon_bracelet", "ring": "icon_ring"}

var _root: Control
var _items_row: HBoxContainer
var _letters_row: HBoxContainer
var _days: Label
var _detail_title: Label
var _detail: Label


func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func is_open() -> bool:
	return _root.visible


func _input(event: InputEvent) -> void:
	if _root.visible:
		if event.is_action_pressed("inventory") or event.is_action_pressed("pause"):
			close()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("inventory") and _can_open():
		open()
		get_viewport().set_input_as_handled()


func _can_open() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path.ends_with("main.tscn") and not get_tree().paused \
		and not Game.in_cutscene and Withdrawal.state == ""


func open() -> void:
	_refresh()
	_root.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	_root.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refresh() -> void:
	_days.text = Recovery.days_text()
	for c in _items_row.get_children():
		c.queue_free()
	for c in _letters_row.get_children():
		c.queue_free()
	for it in StoryItems.ITEMS:
		var found: bool = it["id"] in Withdrawal.found_items
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 96)
		b.focus_mode = Control.FOCUS_NONE
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.expand_icon = true
		if found:
			b.icon = Tex.get_texture(ICONS[it["id"]])
			b.text = it["name"]
			b.pressed.connect(func(): _show(it["name"], it["short"]))
		else:
			b.text = "?"
			b.disabled = true
		b.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE_SMALL)
		_items_row.add_child(b)
	for l in StoryItems.LETTERS:
		var read: bool = l["id"] in Recovery.letters_read
		var b := Button.new()
		b.custom_minimum_size = Vector2(118, 30)
		b.focus_mode = Control.FOCUS_NONE
		b.text = StoryItems.letter_date(l) if read else "-"
		b.disabled = not read
		b.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE_SMALL)
		if read:
			b.pressed.connect(func(): _show("Letter, " + StoryItems.letter_date(l), l["text"]))
		_letters_row.add_child(b)
	if Withdrawal.found_items.is_empty() and Recovery.letters_read.is_empty():
		_show("", "Nothing yet. Look around the center: some things here are yours.")
	else:
		_show("", "Choose something to look at it again.")


func _show(title: String, text: String) -> void:
	_detail_title.text = title
	_detail.text = text


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font_size = Config.UI_FONT_SIZE
	_root.theme = th
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.08, 0.95)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "BELONGINGS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_days = Label.new()
	_days.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE_SMALL)
	_days.add_theme_color_override("font_color", Color(0.7, 0.75, 0.7))
	header.add_child(_days)

	_items_row = HBoxContainer.new()
	_items_row.add_theme_constant_override("separation", 8)
	box.add_child(_items_row)
	var letters_title := Label.new()
	letters_title.text = "Letters from your wife"
	letters_title.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE_SMALL)
	box.add_child(letters_title)
	_letters_row = HBoxContainer.new()
	_letters_row.add_theme_constant_override("separation", 6)
	box.add_child(_letters_row)

	_detail_title = Label.new()
	_detail_title.add_theme_color_override("font_color", Color(0.75, 0.82, 0.85))
	box.add_child(_detail_title)
	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(520, 110)
	_detail.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE_SMALL)
	box.add_child(_detail)
	var hint := Label.new()
	hint.text = "[I] Close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE_SMALL)
	hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	box.add_child(hint)
