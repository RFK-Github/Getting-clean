extends Area3D
## Something the player can interact with (E).
## kind:
##   "pill"   - pill bottle (item_id = unique id; message "" = Withdrawal.pill_message())
##   "item"   - one of the 5 personal items (item_id). Flickers under the influence.
##   "letter" - one of the wife's letters (item_id): read it in the panel, then it's gone.
##   "fake"   - a decoy copy of an item (only exists under the influence): turns to nothing.
##   "locked" - shows `message` (locked doors)
##   "door"   - goes to target_level
##   "read"   - opens the reading panel with title + text (or text_source() if set)
##   "action" - calls `action` (e.g. the exit doctor)

var kind := "pill"
var item_id := ""
var prompt := ""
var message := ""
var target_level := ""
var title := ""
var text_source: Callable   # optional: returns the text when read (e.g. the clipboard)
var action: Callable        # for kind "action"
var prompt_source: Callable # optional: returns the prompt live (e.g. "Answer the phone" while it rings)
var shape_size := Vector3(0.4, 0.4, 0.4)

var _flicker_t := 0.0
var _glint_t := 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = shape_size
	cs.shape = box
	cs.position.y = shape_size.y * 0.5
	add_child(cs)


## Under the influence, real items and letters flicker in and out of sight (and fakes flicker too).
func _process(delta: float) -> void:
	if prompt_source.is_valid():
		prompt = prompt_source.call()
	if kind != "item" and kind != "letter" and kind != "fake":
		return
	_glint_t += delta * Config.ITEM_SPARKLE_SPEED
	var glint := get_node_or_null("Sparkle") as Node3D
	if glint:
		glint.scale = Vector3.ONE * (0.65 + 0.35 * sin(_glint_t + position.x))
	var numb := Withdrawal.influence_strength()
	_flicker_t -= delta
	if _flicker_t <= 0.0:
		_flicker_t = randf_range(0.08, 0.4)
		var seen := numb <= 0.0 or randf() > numb * Config.ITEM_FLICKER
		for c in get_children():
			if c is Node3D:
				(c as Node3D).visible = seen


func interact() -> void:
	match kind:
		"pill":
			Withdrawal.take_pill(item_id)
			Withdrawal.post_message(message if message != "" else Withdrawal.pill_message())
			queue_free()
		"item":
			Withdrawal.add_item(item_id)
			Withdrawal.post_message(message)
			queue_free()
		"letter":
			Recovery.read_letter(item_id)
			Game.show_text(title, message)
			queue_free()
		"fake":
			Withdrawal.post_message("You reach for it. Your hand closes on nothing.")
			queue_free()
		"door":
			Game.change_level(target_level)
		"read":
			Game.show_text(title, text_source.call() if text_source.is_valid() else message)
		"action":
			action.call()
		_:
			Withdrawal.post_message(message)
