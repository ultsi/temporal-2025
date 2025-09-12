class_name ReplayStates extends RefCounted

class State:
	var tick: int
	var valid: bool
	var position: Vector3
	var rotation: Vector3
	var animation: String
	var frame: int
	var health: int
	var ammo: int
	var visible: bool
	var color: Color
	var flags: Array[bool]
	var ints: Array[int]
	var floats: Array[float]
	var vector2s: Array[Vector2]

const MAX_TICKS_STORED := 60 * 60 * 10 # 10 minutes (10 minutes loop?)

# first iteration just easy tick based
var ticks: PackedByteArray = []
var valid: PackedByteArray = []
var position: PackedVector3Array = []
var rotation: PackedVector3Array = []
# direction and velocity can be inferred from previous and current tick

var animation: PackedStringArray = []
var frame: PackedByteArray = [] # just s8
var health: PackedInt32Array = [] # int32
var ammo: PackedInt32Array = [] # int32
var visible: PackedByteArray = [] # just s8
var color: PackedColorArray = []
var flags: PackedByteArray = []
var ints: PackedInt32Array = []
var floats: PackedFloat32Array = []
var vector2s: PackedVector2Array = []
var flags_count := 0:
	set(value):
		if modified:
			print("Can't change flags count after the replay states have been modified!")
			return
		flags_count = value
		resize_flags(MAX_TICKS_STORED)
var ints_count := 0:
	set(value):
		if modified:
			print("Can't change ints count after the replay states have been modified!")
			return
		ints_count = value
		resize_ints(MAX_TICKS_STORED)
var floats_count := 0:
	set(value):
		if modified:
			print("Can't change floats count after the replay states have been modified!")
			return
		floats_count = value
		resize_floats(MAX_TICKS_STORED)

var vector2s_count := 0:
	set(value):
		if modified:
			print("Can't change vector2s count after the replay states have been modified!")
			return
		vector2s_count = value
		resize_vector2s(MAX_TICKS_STORED)

var size := 0
var modified := false

func _init(p_flags_count := 0, p_floats_count := 0, p_ints_count := 0, p_vector2s_count := 0) -> void:
	flags_count = p_flags_count
	floats_count = p_floats_count
	ints_count = p_ints_count
	vector2s_count = p_vector2s_count
	resize(MAX_TICKS_STORED)

func resize(new_size: int) -> void:
	ticks.resize(new_size)
	valid.resize(new_size)
	position.resize(new_size)
	rotation.resize(new_size)
	animation.resize(new_size)
	frame.resize(new_size)
	health.resize(new_size)
	ammo.resize(new_size)
	color.resize(new_size)
	visible.resize(new_size)
	resize_flags(new_size)
	resize_ints(new_size)
	resize_floats(new_size)
	resize_vector2s(new_size)

func resize_flags(new_size: int) -> void:
	flags.resize(new_size * flags_count)

func resize_ints(new_size: int) -> void:
	ints.resize(new_size * ints_count)

func resize_floats(new_size: int) -> void:
	floats.resize(new_size * floats_count)

func resize_vector2s(new_size: int) -> void:
	vector2s.resize(new_size * vector2s_count)


func validate_state(state: State) -> bool:
	if state.flags.size() != flags_count:
		print("Can't store less or more flags ({0}) than flags_count ({1})".format([state.flags.size(), flags_count]))
		return false

	return true


func encode_tick(state: State, t: int) -> void:
	if !validate_state(state):
		return
	ticks[t] = t
	valid[t] = 1
	position[t] = state.position
	rotation[t] = state.rotation
	animation[t] = state.animation
	frame.encode_s8(t, state.frame)
	health[t] = state.health
	ammo[t] = state.ammo
	visible.encode_s8(t, 1 if state.visible else 0)
	color[t] = state.color
	
	for i in range(flags_count):
		flags.encode_s8(t * flags_count + i, 1 if state.flags[i] else 0)

	for i in range(ints_count):
		ints[t * ints_count + i] = state.ints[i]

	for i in range(floats_count):
		floats[t * floats_count + i] = state.floats[i]

	for i in range(vector2s_count):
		vector2s[t * vector2s_count + i] = state.vector2s[i]

	if size < t:
		size = t

	modified = true
	
func decode_tick_at(t: int) -> State:
	if t >= MAX_TICKS_STORED:
		print("Decoding failed! Tick is larger than size")
		return null

	var state := State.new()
	state.tick = ticks[t]
	state.valid = valid[t] == 1
	state.position = position[t]
	state.rotation = rotation[t]
	state.animation = animation[t]
	state.frame = frame.decode_s8(t)
	state.health = health[t]
	state.ammo = ammo[t]
	state.visible = visible.decode_s8(t) == 1
	state.color = color[t]
	state.flags = []
	state.flags.resize(flags_count)
	for i in range(flags_count):
		state.flags[i] = flags.decode_s8(t * flags_count + i) == 1

	state.ints = []
	state.ints.resize(ints_count)
	for i in range(ints_count):
		state.ints[i] = ints[t * ints_count + i]

	state.floats = []
	state.floats.resize(floats_count)
	for i in range(floats_count):
		state.floats[i] = floats[t * floats_count + i]

	state.vector2s = []
	state.vector2s.resize(vector2s_count)
	for i in range(vector2s_count):
		state.vector2s[i] = vector2s[t * vector2s_count + i]

	return state

func decode_previous_tick() -> State:
	return decode_tick_at(T.prev_tick)

func decode_tick() -> State:
	return decode_tick_at(T.global_tick)

func invalidate_from(start_tick: int) -> void:
	resize(start_tick)
	resize(MAX_TICKS_STORED)
	size = start_tick

func new_with_same_config() -> ReplayStates:
	return ReplayStates.new(flags_count, floats_count, ints_count, vector2s_count)
