class_name FluxIndicator extends MeshInstance3D

@export var tick_node: Node3D

@export_range(0.0, 2.0, 0.01) var duration := 0.4:
	set(value):
		duration = value
		_update_shader_params()

var shader: ShaderMaterial

func _ready() -> void:
	shader = get_surface_override_material(0).duplicate()
	set_surface_override_material(0, shader)
	_update_shader_params()
	shader.set_shader_parameter("START_TIME", -1.0)


func _process(_delta: float) -> void:
	if !tick_node:
		hide()
		return

	var ticks_ahead := (tick_node.tick - T.global_tick)

	if ticks_ahead < 0.0:
		hide()
		return

	show()

	var progress := clampf((tick_node.tick - T.global_tick) * 2.0 / T.MAX_FLUX_TICKS, 0.0, 1.0)
	print(ticks_ahead, ";", progress)
	shader.set_shader_parameter("PROGRESS", 1.0 - progress)

func _update_shader_params() -> void:
	if !shader:
		return
	
	shader.set_shader_parameter("DURATION", duration)
	shader.set_shader_parameter("START_TIME", -1.0)
