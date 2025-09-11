class_name Arrow extends Node3D

@onready var sprite := $Sprite3D as Sprite3D
@onready var seek_area := $SeekArea as Area3D
@onready var hit_fx := $GPUParticles3D as GPUParticles3D
@onready var audio_hit := $AudioHit as AudioStreamPlayer3D
@onready var audio_flux_on := $AudioFluxOn as AudioStreamPlayer3D
@onready var audio_flux_off := $AudioFluxOff as AudioStreamPlayer3D
@onready var hurt_area := $HurtArea as Area3D

var impulse := 50.0

var direction := Vector3.ZERO:
	set(value):
		direction = value
		velocity = direction * impulse
var velocity := Vector3.ZERO

var _spawn_tick := 0
var is_hit := false
var is_shot := false
var echo_level := -1
var replay_states := ReplayStates.new(2)
var shot_tick := 0
var original_parent: Node3D = null
var hit_what := ""

func _ready() -> void:
	print("Arrow spawned ", self, " for parent ", get_parent())
	_spawn_tick = T.tick
	visible = false
	T.register_tickable(self)
	original_parent = get_parent()
	#replay_states.debug = true

func shoot() -> void:
	print("Shot arrow ", self, " at tick ", T.get_tick(self))
	reset()
	_spawn_tick = T.tick
	is_shot = true
	show()
	shot_tick = T.tick
	velocity = direction * impulse
	#replay_states.invalidate_from(T.tick)


func reset() -> void:
	is_shot = false
	is_hit = false
	reparent(original_parent)
	top_level = true
	sprite.pixel_size = 0.1
	#print("shoot at tick ", G.tick, ", arrow: ", self, " replay states size: ", replay_states.size)


func cancel() -> void:
	is_shot = false
	is_hit = false

	var parent := get_parent_node_3d()
	if parent is Player:
		T.disable_flux(parent)
		audio_flux_off.play()
	
	if parent is StaticBody3D:
		var platform: MovingPlatform = parent.get_meta("moving_platform")
		if platform:
			T.disable_flux(platform)
			audio_flux_off.play()


func hit() -> void:
	is_hit = true

func check_hit() -> bool:
	if !is_shot || is_hit || Utils.time_since_tick_ms(shot_tick) < 20:
		return false
	for body in hurt_area.get_overlapping_bodies():
		if body is WorldTile:
			hit_what = "world"
			return true

		if body is StaticBody3D:
			hit_what = "staticbody"
			return true

		if body is Player && Utils.time_since_tick_ms(shot_tick) > 100:
			hit_what = "player"
			return true
		
	return false

func apply_hit() -> void:
	for body in hurt_area.get_overlapping_bodies():
		if body is WorldTile:
			_hit_world(body)
		if body is StaticBody3D:
			_hit_staticbody(body)
		if body is Player:
			_hit_player(body as Player)

func _dealt_damage(body: Node3D) -> void:
	_hit.call_deferred(body)

				
func _hit_world(body: Node3D) -> void:
	_hit.call_deferred(body)

func _hit_staticbody(body: Node3D) -> void:
	if body.has_meta("moving_platform"):
		var platform: MovingPlatform = body.get_meta("moving_platform")
		T.enable_flux(platform)
		audio_flux_on.play()
		
	_hit.call_deferred(body)
	
func _hit_player(plr: Player) -> void:
	T.enable_flux(plr)
	audio_flux_on.play()

	_hit.call_deferred(plr)

func _hit(body: Node3D) -> void:
	audio_hit.play()
	hit()
	reparent(body)
	top_level = false
	hit_fx.emitting = true

func save_state(state: ReplayStates.State) -> void:
	state.flags = [is_hit, is_shot]

func replay_state(state: ReplayStates.State) -> void:
	if !is_hit && state.flags[0]:
		print("Arrow {0} just hit on replay".format([self]))
	if !is_shot && state.flags[1]:
		print("Arrow {0} was just shot on replay".format([self]))
	is_hit = state.flags[0]
	is_shot = state.flags[1]


func after_tick() -> void:
	if !is_shot:
		hide()
	else:
		show()


func _on_tick(tick: int, _immune_tick := false) -> void:
	# if !immune_tick && Replay.replay_node(self, tick):
	# 	#print("Replaying arrow id {0} tick {1}".format([get_instance_id(), tick]))
	# 	after_tick()
	# 	if !is_hit:
	# 		if check_hit():
	# 			apply_hit()
	# 	return
	#print("Not replaying arrow id {0} tick {1}".format([get_instance_id(), tick]))
	var alive_time := Utils.time_since_tick_ms(_spawn_tick)

	if !is_hit:
		if alive_time > 100:
			velocity.y -= 70 * C.TIME_BETWEEN_TICKS
		
		var old_pos := global_position
		global_position += velocity * C.TIME_BETWEEN_TICKS

		var diff := global_position - old_pos
		rotation.z = Vector2(diff.x, diff.y).angle()
		if check_hit():
			print("Arrow {0} just hit at tick {1}".format([self, tick]))
			apply_hit()

	#Replay.save_replay_state(self, tick)
	after_tick()