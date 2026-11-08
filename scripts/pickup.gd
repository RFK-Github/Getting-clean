extends Area3D
## Something the player can interact with (E).
## kind: "pill" (pill bottle), "item" (one of the 5 personal items),
## "locked" (locked door, shows a message) or "door" (goes to target_level).

var kind := "pill"
var item_id := ""
var prompt := ""
var message := ""
var target_level := ""
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
			Withdrawal.take_pill()
			Withdrawal.post_message(message)
			queue_free()
		"item":
			Withdrawal.add_item(item_id)
			Withdrawal.post_message(message)
			queue_free()
		"door":
			Game.change_level(target_level)
		_:
			Withdrawal.post_message(message)
