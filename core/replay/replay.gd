@tool
class_name Replay extends RefCounted

static func _save_node_state(node: Node3D, state: ReplayStates.State) -> void:
	state.position = node.global_position
	state.rotation = node.rotation

static func _get_replay_states(node: Node3D) -> ReplayStates:
	var maybe_states: Variant = node.get("replay_states")
	if maybe_states is ReplayStates:
		return maybe_states

	return null

static func save_replay_state(node: Node3D, tick := -1) -> void:
	var replay_states := _get_replay_states(node)
	if !replay_states:
		print("Unable to save replay state as there's no replay_states for node ", node)
		return


	if tick < 0:
		tick = T.global_tick

	var state := ReplayStates.State.new()
	_save_node_state(node, state)

	if node is Player:
		var plr := node as Player
		plr.save_state(state)

	if node.has_method("save_state"):
		node.call("save_state", state)

	replay_states.encode_tick(state, tick)


static func replay_node(node: Node3D, tick := -1) -> bool:
	var replay_states := _get_replay_states(node)
	if !replay_states:
		print("Unable to replay node as there's no replay_states for node ", node)
		return false
	
	if tick < 0:
		tick = T.global_tick

	if replay_states.size <= T.global_tick:
		return false

	var state := replay_states.decode_tick_at(tick)
	if !state || !state.valid:
		return false

	var dist := node.global_position.distance_to(state.position)
	if dist > 1.0:
		print("reseted replay node's position as it had drifted too far. node {0}, dist: {1}".format([node, dist]))
		node.global_position = state.position
	node.rotation = state.rotation

	if node is Player:
		var plr := node as Player
		plr.replay_state(state)

	if node.has_method("replay_state"):
		node.call("replay_state", state)
	
	return true

static func get_position_at(node: Node3D, tick := -1) -> Vector3:
	var replay_states := _get_replay_states(node)
	if !replay_states:
		print("Unable to get position for node as there's no replay_states for node ", node)
		return Vector3.ZERO

	if tick < 0:
		tick = T.global_tick
	
	if replay_states.size <= T.global_tick:
		return Vector3.ZERO

	var state := replay_states.decode_tick_at(tick)
	if !state || !state.valid:
		return Vector3.ZERO

	return state.position
