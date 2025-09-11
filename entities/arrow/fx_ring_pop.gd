class_name FXRingPop extends MeshInstance3D

@export_range(0.0, 2.0, 0.01) var duration := 0.4:
	set(value):
		duration = value
		_update_shader_params()

var shader: ShaderMaterial

func _ready() -> void:
	shader = get_surface_override_material(0).duplicate()
	set_surface_override_material(0, shader)

	hide()


func _update_shader_params() -> void:
	if !shader:
		return
	
	shader.set_shader_parameter("DURATION", duration)

func play() -> void:
	shader.set_shader_parameter("START_TIME", G.level_time)
	show()
	
	get_tree().create_timer(duration * 0.8).timeout.connect(_finished)

func _finished() -> void:
	hide()
