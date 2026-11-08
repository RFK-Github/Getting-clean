extends "res://scripts/cutscenes/cutscene_base.gd"
## FINAL CUTSCENE A (good ending): he walks out of the center clean. Nobody is waiting -
## his wife already said goodbye (the_visit.gd). He stands alone at his daughter's grave,
## and stays.

const Audio := preload("res://scripts/audio.gd")

const GRAVE := Vector3(0, 0, 0)

var _sun: DirectionalLight3D


func get_settings() -> Dictionary:
	return {
		"fog_mode": "exponential",
		"fog_color": Color(0.8, 0.78, 0.7),
		"fog_density": 0.02,
		"ambient_color": Color(0.9, 0.92, 0.88),
		"ambient_energy": 0.5,
		"tint": Color(0.95, 0.97, 0.9),
		"tint_strength": 0.2,
		"vignette": 0.8,
	}


func build() -> void:
	duration = 20.0

	cam = Camera3D.new()
	cam.fov = 65
	cam.near = 0.05
	cam.far = 80
	add_child(cam)

	grave_set(GRAVE)
	world_env.environment.background_color = Color(0.8, 0.78, 0.7)
	_sun = DirectionalLight3D.new()
	_sun.light_color = Color(1.0, 0.9, 0.7)
	_sun.light_energy = 0.0
	_sun.rotation_degrees = Vector3(-25, 150, 0)
	add_child(_sun)

	at(0.8, func(): say("They let you go on a Tuesday. Nobody is waiting outside. You knew nobody would be.", 3.4))
	at(4.6, func(): say("Every week, you come here. Clean.", 3.0))
	at(8.0, func(): say("Forever seven years old.", 2.6))
	at(11.0, func(): say("You don't run from it any more. You stay. You hold on.", 3.4))
	at(18.2, func(): fade(Color(0, 0, 0, 1), 1.6))


func animate(delta: float) -> void:
	# The sun breaks through while he stands at her stone.
	_sun.light_energy = minf(_sun.light_energy + delta * 0.15, 0.9)
	var eye := GRAVE + Vector3(0, 1.6, 0.4 - t * 0.02)
	look_blend(eye, GRAVE + Vector3(0, 0.6, -1.6), GRAVE + Vector3(0, 0.6, -1.6), 0.0)
