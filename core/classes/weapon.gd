@abstract class_name Weapon extends Node3D

@abstract func can_use() -> bool
@abstract func use_press(direction: Vector2) -> AnimAction # String: action name, to be used for anims etc
@abstract func use_release(direction: Vector2) -> AnimAction
