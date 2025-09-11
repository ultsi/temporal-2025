class_name Spikes extends Node3D

@onready var area := $Area3D as Area3D

func _ready() -> void:
    area.body_entered.connect(_body_entered)


func _body_entered(body: Node3D) -> void:
    if body is Player:
        var plr := body as Player
        plr.take_damage(20)
