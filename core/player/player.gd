@tool
class_name Player extends CharacterBody3D

@onready var sprite := $AnimatedSprite3D as AnimatedSprite3D
@onready var light := $SpotLight3D as SpotLight3D
@onready var name_label := $Label3D as Label3D
@onready var audio_walk := $AudioWalk as AudioStreamPlayer3D
@onready var audio_jump := $AudioJump as AudioStreamPlayer3D
@onready var audio_dash := $AudioDash as AudioStreamPlayer3D
@onready var audio_hurt := $AudioHurt as AudioStreamPlayer3D
@onready var audio_rewind := $AudioRewind as AudioStreamPlayer3D
@onready var bow := $WeaponBasicBow as BasicBow
@onready var multimesh_inst := $MultiMeshInstance3D as MultiMeshInstance3D

@export var sprites: Dictionary[String, SpriteFrames] = {}

static var player: Player

var health := 100
const MAX_ECHOS := 1
var echos: Array[Player] = []
var replay_states := ReplayStates.new(1, 0, 4, 1)

const JUMP_IMPULSE := 50
const TERMINAL_VELOCITY := -100.0
const GRAVITY := 150
const ACCEL := 200
const MAX_SPEED := 17

var is_echo := false

var _r_direction := Vector2.ZERO
var _r_attack_pressed := false

var _last_step_pos := Vector3.ZERO
var _last_step_tick := -1000
var _last_on_floor_tick := -1000
var _last_attack_tick := -1000
var _next_anim_tick := -1000
var _last_hurt_at := -1000
var _last_attack2_tick := -1000
var _last_dash_tick := -1000
var _spawn_pos := Vector3.ZERO
var _hurt_energy := Vector3.ZERO
var _multimesh: MultiMesh
var _cur_replay_state: ReplayStates.State

func _ready() -> void:
	_spawn_pos = global_position
	if replay_states.size > T.tick:
		is_echo = true
	else:
		player = self
	
	T.register_tickable(self)
	_multimesh = multimesh_inst.multimesh
	_multimesh.instance_count = 0
	_multimesh.use_colors = true
	_multimesh.instance_count = 50
	_multimesh.visible_instance_count = 0


func _face_dir(dir: Vector2) -> void:
	sprite.flip_h = dir.x <= 0


func is_dead() -> bool:
	return health == 0


func _get_face_dir() -> Vector2:
	return Vector2(-1, 0) if sprite.flip_h else Vector2(1, 0)


func _play_anim_non_looped(anim: String) -> void:
	if sprite.animation == anim:
		return

	sprite.play(anim)


func animate(actions: Dictionary[String, AnimAction]) -> void:
	# hmm state machine
	if is_dead():
		_play_anim_non_looped("death")
		return

	if Utils.time_since_tick_ms(_last_hurt_at) < 50:
		_play_anim_non_looped("hurt")
		_next_anim_tick = Utils.tick_from_now(50)
		return

	var selected_anim: AnimAction = null

	if actions.has("attack_press"):
		selected_anim = actions["attack_press"]
	elif actions.has("attack_release"):
		selected_anim = actions["attack_release"]
	
	if selected_anim:
		_play_anim_non_looped(selected_anim.anim)
		_next_anim_tick = Utils.tick_from_now(int(selected_anim.playtime * 1000))

	if _next_anim_tick > T.tick:
		return

	if abs(velocity.x) > 0.1:
		sprite.play("walk")
		return

	sprite.play("idle")


func do_jump() -> void:
	velocity.y = JUMP_IMPULSE
	audio_jump.play()


func do_dash(dir: Vector2) -> void:
	_last_dash_tick = T.tick
	var angle := dir.angle()
	var snapped_angle := roundf(angle / (PI / 8.0)) * (PI / 8.0)
	var snapped_direction := Vector2(cos(snapped_angle), sin(snapped_angle))

	snapped_direction = snapped_direction.normalized()
	velocity.x = snapped_direction.x * 35
	velocity.y = snapped_direction.y * 35
	audio_dash.play()

func _get_input_direction() -> Vector2:
	if is_echo:
		return _r_direction
	return Input.get_vector("move_left", "move_right", "move_down", "move_up")

func _get_attack_pressed() -> bool:
	if is_echo:
		return _r_attack_pressed
	return Input.is_action_pressed("attack")

func _on_tick(tick: int, immune_tick := false) -> void:
	if is_echo:
		Replay.replay_node(self, tick)
		sprite.transparency = 0.9
	else:
		sprite.transparency = 0.0
	
	var actions: Dictionary[String, AnimAction] = {}
	_r_direction = _get_input_direction()
	if health <= 0:
		_r_direction = Vector2.ZERO
	elif _r_direction != Vector2.ZERO:
		_face_dir(_r_direction)

	sprite.transparency = 0.0

	name_label.text = str(replay_states.size)
	var time := Time.get_ticks_msec()
	var is_in_dash := Utils.time_since_tick_ms(_last_dash_tick) < 120
	var ready_to_dash := Utils.time_since_tick_ms(_last_dash_tick) > 700
	var gravity_after_dash := Utils.time_since_tick_ms(_last_dash_tick) < 150
	var can_attack := tick - _last_attack_tick > 6
	

	if Utils.time_since_tick_ms(_last_hurt_at) < 100:
		velocity += _hurt_energy
	else:
		# limits
		if (velocity.y < TERMINAL_VELOCITY):
			velocity.y = TERMINAL_VELOCITY

		if is_in_dash:
			velocity = velocity.normalized() * 40

		var attack_mode := _get_attack_pressed()
		if can_attack && attack_mode:
			# modify to be generic so we can swap bows as we wish
			var action := bow.use_press(_r_direction)
			actions[action.anim] = action
		elif time - _last_attack_tick > 50:
			velocity += Vector3(_r_direction.x, 0, 0) * ACCEL * C.TIME_BETWEEN_TICKS

		if (absf(velocity.x) > MAX_SPEED):
			if is_on_floor() || (!is_in_dash && !is_on_floor()):
				velocity.x = move_toward(velocity.x, MAX_SPEED * signf(velocity.x), ACCEL)

		if !is_on_floor():
			if !gravity_after_dash:
				velocity.y -= GRAVITY * C.TIME_BETWEEN_TICKS
				if _r_direction.length_squared() < 0.01:
					velocity.x *= 0.5

			if Input.is_action_just_released("jump") && velocity.y > 0.0:
				velocity.y *= 0.2

			if Utils.time_since_tick_ms(_last_on_floor_tick) < 50:
				if Input.is_action_just_pressed("jump"):
					do_jump()
					actions["jump"] = AnimAction.new("jump")
		else:
			_last_on_floor_tick = tick
			if !is_in_dash && _r_direction.length_squared() < 0.01 || attack_mode:
				velocity.x *= 0.1
			if Input.is_action_just_pressed("jump"):
				do_jump()
				actions["jump"] = AnimAction.new("jump")

		if Input.is_action_just_pressed("dash") && ready_to_dash:
			do_dash(_r_direction)

		## REFACTOR
		## bow.can_use() to be a part of the player
		## bow not replayed
		## arrow not replayed
		## only player
		## maybe echo objects can be replayed
		## like arrows could become echos as well with some skill
		if Input.is_action_just_released("attack") && can_attack:
			var action := bow.use_release(_r_direction)
			actions[action.anim] = action
			_last_attack_tick = tick
			

		if Input.is_action_just_pressed("attack2"):
			_last_attack2_tick = tick
			# no attack2 for now


	if abs(global_position.x - _last_step_pos.x) > 2 && is_on_floor() && Utils.time_since_tick_ms(_last_step_tick) > 200:
		_last_step_pos = global_position
		_last_step_tick = tick
		audio_walk.play()

		if !is_echo:
			Input.start_joy_vibration(0, 0.01, 0.0, 0.1)

	#print("saving replay state ", tick)
	Replay.save_replay_state(self, tick)
	
	move_and_slide()
	animate(actions)


func replay_state(state: ReplayStates.State) -> void:
	sprite.animation = state.animation
	_last_dash_tick = state.ints[0]
	_last_on_floor_tick = state.ints[1]
	_last_attack_tick = state.ints[2]
	_last_hurt_at = state.ints[3]
	_r_direction = state.vector2s[0]

	_r_attack_pressed = state.flags[0]

	_cur_replay_state = state


func save_state(state: ReplayStates.State) -> void:
	state.animation = sprite.animation
	state.ints = [
		_last_dash_tick,
		_last_on_floor_tick,
		_last_attack_tick,
		_last_hurt_at
	]
	state.vector2s = [_r_direction]

	state.flags = [
		_r_attack_pressed
	]


func show_flux_past() -> void:
	var our_tick := T.get_tick(self)
	if T.tick >= our_tick:
		return

	var forward := our_tick - T.tick
	#print("We are currently {0} ticks forward in time".format([forward]))

	var vis_inst := int(forward / 6.0) # 6.0 needs to be the same with snapped below
	_multimesh.visible_instance_count = vis_inst

	var forward_perc := 1.0 - float(forward) / T.MAX_FLUX_TICKS
	sprite.modulate = Color(forward_perc, forward_perc, 1.0)

	for i in range(vis_inst):
		var phase := 1.0 - float(i) / vis_inst
		var inst_tick := int(T.tick + phase * forward)
		inst_tick = snappedi(inst_tick, 6)
		var this_forward_perc := phase * forward / T.MAX_FLUX_TICKS # TODO this isn't in line with forward_perc but w/e for now
		var inst_transform := Transform3D()
		inst_transform.basis = global_transform.basis
		inst_transform.origin = Replay.get_position_at(self, inst_tick)
		_multimesh.set_instance_transform(i, inst_transform)
		_multimesh.set_instance_color(i, Color(1.0 - this_forward_perc, 1.0 - this_forward_perc, 1, this_forward_perc * this_forward_perc))
		#print("Setting multimesh inst {0}: phase {1}, tick {2}, pos {3}".format([i, phase, inst_tick, inst_transform.origin]))


func die() -> void:
	if is_echo:
		return
	print("Player died at ", T.tick)
	T.reset_loop()
	if MAX_ECHOS >= 0:
		if echos.size() >= MAX_ECHOS:
			var echo: Player = echos.pop_front()
			print("freeing previous echo {0}, size now {1}".format([echo, echos.size()]))
			echo.queue_free()
		# for now always a new echo is created when we die
		var new_player: Player = preload("res://core/player/player.tscn").instantiate()
		new_player.replay_states = replay_states
		get_parent().add_child(new_player)
		Replay.replay_node(new_player, T.tick)
		new_player.replay_states = replay_states.new_with_same_config()
		Replay.save_replay_state(new_player, T.tick)
		new_player.is_echo = false
		new_player.echos = echos
		self.is_echo = true
		echos.append(self)


func take_damage(_damage: int) -> void:
	die()


func _physics_process(_dt: float) -> void:
	if Engine.is_editor_hint():
		return

	if Input.is_action_just_pressed("timepoint"):
		T.clear_flux()

	light.show()


	if !is_echo && Input.is_action_just_pressed("echo"):
		die()

	show_flux_past()
