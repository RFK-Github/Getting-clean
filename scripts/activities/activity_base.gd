extends Node
## Base for the activities (simple minigames). Once per in-game day each.
## Showing up always gives a little Recovery and lowers withdrawal; doing well gives more.
## Activities are allowed under the influence too.
## If a withdrawal episode or a hallucination starts during the activity, it stops
## (showing up still counts) and the player gets control back.
## A subclass overrides setup(), tick(delta), cleanup() and calls finish(did_well).

signal ended

const Player := preload("res://scripts/player.gd")
const Psx := preload("res://scripts/psx.gd")
const Tex := preload("res://scripts/textures.gd")

var id := ""
var host := ""          # who comments ("Leon", "Sam", "Nurse Dale")
var note := ""          # line on the patient chart
var player: Player
var level: Node3D

var _ui: CanvasLayer
var ui_root: Control
var title_label: Label
var help_label: Label
var _done := false


## Why this activity can't start right now ("" = it can).
static func refusal(activity_id: String, host_name: String) -> String:
	if not Recovery.can_talk(activity_id):
		return "%s: \"That's enough for today. Come back tomorrow.\"" % host_name
	return ""


func begin(p: Player, lvl: Node3D) -> void:
	player = p
	level = lvl
	player.frozen = true
	_build_ui()
	setup()


func setup() -> void:
	pass


func tick(_delta: float) -> void:
	pass


func cleanup() -> void:
	pass


func _process(delta: float) -> void:
	if _done:
		return
	if Withdrawal.state != "":
		Withdrawal.post_message("You can't focus any more. Your hands won't stop shaking.")
		finish(false)
		return
	tick(delta)


func comment(text: String) -> void:
	Withdrawal.post_message("%s: \"%s\"" % [host, text])


func finish(did_well: bool) -> void:
	if _done:
		return
	_done = true
	Recovery.mark_talked(id)
	var gain := Config.RECOVERY_ACTIVITY_SHOW_UP + (Config.RECOVERY_ACTIVITY_DO_WELL if did_well else 0.0)
	Recovery.add(gain, note)
	Withdrawal.meter = maxf(0.0, Withdrawal.meter - Config.ACTIVITY_RELIEF - (Config.ACTIVITY_RELIEF_GOOD if did_well else 0.0))
	cleanup()
	player.frozen = false   # an episode freezes him again itself when it gets there
	player.reset_look()
	_ui.queue_free()
	ended.emit()
	queue_free()


# ------------------------------------------------------------------ UI helpers

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 3
	add_child(_ui)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font_size = Config.UI_FONT_SIZE
	ui_root.theme = th
	_ui.add_child(ui_root)
	title_label = label("", Vector2(0.5, 0), Vector2(-250, 56), Vector2(500, 22))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label = label("", Vector2(0.5, 1), Vector2(-300, -64), Vector2(600, 20))
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.add_theme_font_size_override("font_size", Config.UI_FONT_SIZE_SMALL)


func label(text: String, anchor: Vector2, offset: Vector2, size: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", Color(0.9, 0.92, 0.85))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	ui_root.add_child(l)
	_place(l, anchor, offset, size)
	return l


func rect(color: Color, anchor: Vector2, offset: Vector2, size: Vector2, parent: Control = null) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else ui_root).add_child(r)
	_place(r, anchor, offset, size)
	return r


func _place(c: Control, anchor: Vector2, offset: Vector2, size: Vector2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = offset.x
	c.offset_top = offset.y
	c.offset_right = offset.x + size.x
	c.offset_bottom = offset.y + size.y


func ball_mesh(radius: float, color: Color) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 8
	s.rings = 4
	s.material = Psx.material(Tex.get_texture("plain"), color, 1.0, false)
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	level.add_child(mi)
	return mi


## A bouncing 0..1 value for "hold to charge" power bars.
static func pingpong01(x: float) -> float:
	var m := fmod(x, 2.0)
	return m if m <= 1.0 else 2.0 - m
