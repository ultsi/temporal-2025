@tool
class_name MovingSpikes extends Node3D

@export_range(0.0, 100.0, 0.1) var distance := 4.0:
    set(value):
        distance = value
        _set_values()
@export_range(0.01, 10.0) var move_time := 1.0:
    set(value):
        move_time = value
        _set_values()
@export_range(0.01, 10.0) var stop_time := 1.0:
    set(value):
        stop_time = value
        _set_values()

@onready var moving_platform := $MovingPlatform as MovingPlatform

func _set_values() -> void:
    if !moving_platform:
        return

    moving_platform.target_pos_8px = Vector3(0, distance, 0)
    moving_platform.move_time = move_time
    moving_platform.stop_time = stop_time

func _ready() -> void:
    _set_values()
