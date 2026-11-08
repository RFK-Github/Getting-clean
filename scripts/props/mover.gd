extends Node3D
## Moves a vehicle (car, bus, train) along the Z axis and removes it when it passes end_z.
## Build the vehicle's meshes as children of this node, front facing `direction`.

var direction := -1.0        # -1 = toward -Z, +1 = toward +Z
var max_speed := 8.0
var acceleration := 0.0      # 0 = starts at full speed
var delay := 0.0             # seconds before it starts moving
var end_z := -250.0
var speed := 0.0


func _ready() -> void:
	if acceleration <= 0.0:
		speed = max_speed


func _process(delta: float) -> void:
	if delay > 0.0:
		delay -= delta
		return
	if acceleration > 0.0:
		speed = minf(max_speed, speed + acceleration * delta)
	position.z += direction * speed * delta
	if (direction < 0.0 and position.z < end_z) or (direction > 0.0 and position.z > end_z):
		queue_free()
