class_name CameraAndVisuals extends Node3D

@onready var camera := $MainCamera as Camera3D

var skip_by_x := C.LEVEL_WORLD_WIDTH
var skip_by_y := C.LEVEL_WORLD_HEIGHT

func _process(_delta: float) -> void:
    if !Player.player:
        return
    var x_mult := int(Player.player.global_position.x / skip_by_x) - 1
    var y_mult := int(Player.player.global_position.y / skip_by_y) - 1

    camera.global_position.x = x_mult * skip_by_x + skip_by_x * 1.5
    camera.global_position.y = y_mult * skip_by_y + skip_by_y * 1.5
