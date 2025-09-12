@tool

extends OmniLight3D

@export_range(0.01, 1.0, 0.001) var flicker := 0.01
@export_range(0.1, 10.0, 0.1) var og_energy := 1.0
@export_range(0.1, 200.0, 0.1) var og_range := 10.0

@export var inverse_time := false

const flicker_time := 0.1 ## in seconds
var next_flicker := 0.0

func _process(_delta: float) -> void:
	var time := T.time
	if time < next_flicker:
		return
		
	if randf() < flicker:
		light_energy = og_energy * 0.8
		#omni_range = og_range * 0.5
	else:
		light_energy = og_energy
		omni_range = og_range

	next_flicker = time + flicker_time
