@tool
class_name MovingPlatform extends Node3D

#region exports
@export var target_pos_8px := Vector3(4.0, 0.0, 0.0):
	set(value):
		target_pos_8px = value
		if is_inside_tree():
			_update_target_pos()
@export var move_time := 5.0
@export var stop_time := 1.0
@export_range(0, 1, 0.05) var offset := 0.0
@export var enabled := true
@export var inversed := false:
	set(value):
		inversed = value
#endregion

@onready var _body: StaticBody3D = $BodyPivot/StaticBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		_update_target_pos()
		return

	_body.set_meta("moving_platform", self)

	#GAME ONLY
	# delete editor only nodes
	var editor_only := $EditorOnly
	editor_only.queue_free()

	# get all children except BodyPivot
	# and parent them to StaticBody so that they move correctly with the platform from the start
	var body_pivot := $BodyPivot as Node3D
	for child: Node3D in get_children():
		if child == body_pivot || child == editor_only:
			continue

		parent_to_platform(child)

	T.register_tickable(self)


func _update_target_pos() -> void:
	if Engine.is_editor_hint():
		var target := $EditorOnly/Target as MeshInstance3D

		target.position = _get_pos_at_time(0)
		target.position.y += 0.5


func parent_to_platform(node: Node3D) -> void:
	node.reparent(_body)
	node.position.x = 0
	

func _get_pos_at_time(time: float) -> Vector3:
	var target_pos := target_pos_8px * 2

	var total_time := move_time + stop_time
	time += offset * total_time * 2.0

	var step := floori(time / total_time)
	var phase := clampf((time - step * total_time) / move_time, 0, 1)
	var dir := -1.0 if step % 2 == 0 else 1.0
	var start_pos := Vector3.ZERO if step % 2 == 1 else target_pos

	return start_pos + phase * dir * target_pos

func _on_tick(_delta: float) -> void:
	if !enabled:
		return

	var tick := T.get_node_tick(self)
	var time := Utils.tick_to_time(tick)


	#var old_pos := _body.position
	_body.position = _get_pos_at_time(time)

	#_body.constant_linear_velocity = (_body.position - old_pos) / (G.level_time_delta)
