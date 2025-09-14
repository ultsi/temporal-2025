@tool
extends Node3D

var immune_tick := 0.0
var global_tick := 0.0
var prev_tick := 0.0
var time := 0.0
var timepoint_tick := 0


const MAX_FLUX_TICKS := 600.0 # 10 seconds ahead max

class Tickable extends RefCounted:
	var node: Node3D
	var flux_ticks_left := -1
	var immune := false


var _tickables: Dictionary[int, Tickable] = {}
var _flux_counter: Dictionary[int, bool] = {}

func _ready() -> void:
	process_physics_priority = -1000


func register_tickable(node: Node3D) -> void:
	if !node.has_method("_on_tick"):
		print("Can't register tickable because no method '_on_tick' in node {0}".format([node]))
		return
	var tickable := Tickable.new()
	tickable.node = node
	tickable.node.tick = global_tick
	_tickables[node.get_instance_id()] = tickable

func enable_flux(node: Node3D, ticks := MAX_FLUX_TICKS) -> void:
	if !_tickables.has(node.get_instance_id()):
		print("Can't enable flux as node {0} isn't tickable".format([node]))
		return
	var tickable := _tickables[node.get_instance_id()]
	tickable.flux_ticks_left = ticks
	_flux_counter[node.get_instance_id()] = true

func disable_flux(node: Node3D) -> void:
	if !_tickables.has(node.get_instance_id()):
		print("Can't disable flux as node {0} isn't tickable".format([node]))
		return
	var tickable := _tickables[node.get_instance_id()]
	tickable.flux_ticks_left = -1
	_flux_counter.erase(node.get_instance_id())

func clear_flux() -> void:
	for id in _tickables:
		var tickable := _tickables[id]
		tickable.flux_ticks_left = -1

	_flux_counter.clear()

func is_flux(node: Node3D) -> bool:
	return is_tickable(node) && _tickables[node.get_instance_id()].flux_ticks_left > 0

func flux_ticks_left(node: Node3D) -> int:
	return _tickables[node.get_instance_id()].flux_ticks_left if is_tickable(node) else -1

func enable_immune(node: Node3D) -> void:
	if !_tickables.has(node.get_instance_id()):
		print("Can't enable immune as node {0} isn't tickable".format([node]))
		return
	var tickable := _tickables[node.get_instance_id()]
	tickable.immune = true

func disable_immune(node: Node3D) -> void:
	if !_tickables.has(node.get_instance_id()):
		print("Can't disable immune as node {0} isn't tickable".format([node]))
		return
	var tickable := _tickables[node.get_instance_id()]
	tickable.immune = false

func clear_immune() -> void:
	for id in _tickables:
		var tickable := _tickables[id]
		tickable.immune = false


func is_tickable(node: Node3D) -> bool:
	return _tickables.has(node.get_instance_id())


func erase_tickable(id: int) -> void:
	_tickables.erase(id)
	_flux_counter.erase(id)


func reset_loop() -> void:
	global_tick = 0
	clear_flux()
	clear_immune()
	for id in _tickables:
		var tickable := _tickables[id]
		tickable.node.tick = 0


const FLUX_SLOWDOWN := 2 ** 16 # 16 stage slowdown
var _next_flux_tick_plus := 1
var _next_flux_slowdown_tick := 0
# runs 60fps by default so just what we need
# also since movement depends on ticks we prob just want to use
# physics process in every tickable object
# calling move_and_slide in non physics_process makes it wonky
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	RenderingServer.global_shader_parameter_set("TIME_SYNCED", Time.get_ticks_msec() / 1000.0)

	immune_tick += 1

	var are_flux_objects := _flux_counter.size() > 0

	var global_tick_increment := 1.0 if !are_flux_objects else 0.1

	for id in _tickables:
		var tickable := _tickables[id]
		if tickable.node == null || tickable.node.is_queued_for_deletion():
			erase_tickable(id)
			continue
	
		if tickable.flux_ticks_left > 0:
			tickable.node.tick += 1.0
			tickable.node.call("_on_tick", 1.0)
			tickable.flux_ticks_left -= 1

			if tickable.flux_ticks_left <= 0:
				disable_flux.call_deferred(tickable.node)
		elif tickable.immune:
			tickable.node.call("_on_tick", 1.0, true)
		else:
			if tickable.node.tick <= global_tick:
				tickable.node.tick = global_tick
				tickable.node.call("_on_tick", global_tick_increment)
			else:
				tickable.node.tick += 0.1
				tickable.node.call("_on_tick", 0.1)


	prev_tick = global_tick
	global_tick += global_tick_increment
	if !are_flux_objects && global_tick_increment == 1.0:
		global_tick = round(global_tick)
	time = global_tick * C.TIME_BETWEEN_TICKS

	if !are_flux_objects:
		_next_flux_tick_plus = 1
