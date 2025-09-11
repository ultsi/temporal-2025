class_name DirectionIndicator extends Node3D

var shader: ShaderMaterial

func _ready() -> void:
    var mesh := $DirectionRingShader as MeshInstance3D
    shader = mesh.get_active_material(0)
    if !Engine.is_editor_hint():
        shader = shader.duplicate()
        mesh.set_surface_override_material(0, shader)


func set_angle(angle: float) -> void:
    shader.set_shader_parameter("ANGLE", angle)
