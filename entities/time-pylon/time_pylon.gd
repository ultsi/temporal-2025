extends Node3D

@onready var n_orbs := $Orbs as Node3D

func _ready() -> void:
	T.register_tickable(self)

func _on_tick(_tick: int) -> void:
	n_orbs.rotation.z += 0.01
