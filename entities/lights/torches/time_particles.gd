extends GPUParticles3D

@export var inverse := false

func _process(delta: float) -> void:
	speed_scale = delta / 0.017
	interpolate = speed_scale == 1.0
