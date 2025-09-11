class_name TimeImmuneField extends Node3D

@onready var area := $Area3D as Area3D

func _ready() -> void:
	area.body_entered.connect(_body_entered)
	area.body_exited.connect(_body_exited)
	area.area_entered.connect(_area_entered)
	area.area_exited.connect(_area_exited)

func _body_entered(body: Node3D) -> void:
	print(body)
	if T.is_tickable(body):
		T.enable_immune(body)

func _body_exited(body: Node3D) -> void:
	if T.is_tickable(body):
		T.disable_immune(body)

func _area_entered(p_area: Area3D) -> void:
	print(p_area)
	if T.is_tickable(p_area.get_parent_node_3d()):
		T.enable_immune(p_area.get_parent_node_3d())

func _area_exited(p_area: Area3D) -> void:
	if T.is_tickable(p_area.get_parent_node_3d()):
		T.disable_immune(p_area.get_parent_node_3d())