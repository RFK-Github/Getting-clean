extends Area3D
## Something the player can interact with (E).
## kind:
##   "pill"   - pill bottle (item_id = unique id; message "" = Withdrawal.pill_message())
##   "item"   - one of the personal items (item_id)
##   "locked" - shows `message` (locked doors, the exit doctor for now)
##   "door"   - goes to target_level
##   "read"   - opens the reading panel with title + text (or text_source() if set)

var kind := "pill"
var item_id := ""
var prompt := ""
var message := ""
var target_level := ""
var title := ""
var text_source: Callable   # optional: returns the text when read (e.g. the clipboard)
var shape_size := Vector3(0.4, 0.4, 0.4)


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
		"door":
			Game.change_level(target_level)
		"read":
			Game.show_text(title, text_source.call() if text_source.is_valid() else message)
		_:
			Withdrawal.post_message(message)
