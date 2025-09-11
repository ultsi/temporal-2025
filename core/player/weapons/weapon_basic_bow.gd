class_name BasicBow extends Weapon

@onready var direction_indicator := $DirectionIndicator as DirectionIndicator
@onready var audio_draw := $AudioDraw as AudioStreamPlayer3D
@onready var audio_shoot := $AudioShoot as AudioStreamPlayer3D
var arrow_scene := preload("res://entities/arrow/arrow.tscn")
var player: Player
var ammo_count := 0
var max_ammo := 10
var arrow_ring_buffer: Array[Arrow] = []
var arrow_index := 0
var drawing := false
var drawing_start := 0
var last_use_time := 0
var shot_arrow: Arrow

const ARROWS_BUFFER_SIZE := 1

const IMPULSE_RANGE := [20, 60]
const MIN_DRAW_TIME_MS := 100
const MAX_DRAW_TIME_MS := 500

func _ready() -> void:
	direction_indicator.hide()

	_create_arrows.call_deferred()


func _create_arrows() -> void:
	for i in range(ARROWS_BUFFER_SIZE):
		var arrow: Arrow = arrow_scene.instantiate()
		add_child(arrow)
		arrow.top_level = true
		arrow.global_position = global_position
		arrow_ring_buffer.append(arrow)
		arrow.name = "Arrow #" + str(randi_range(0, 1337))

		print("created arrow ", arrow)

func can_use() -> bool:
	return Time.get_ticks_msec() - last_use_time > 100


func use_press(dir: Vector2) -> AnimAction:
	if shot_arrow:
		shot_arrow.cancel()
		shot_arrow = null
		return AnimAction.new()

	if !drawing:
		audio_draw.play()
		drawing_start = Time.get_ticks_msec()
	drawing = true
	direction_indicator.show()
	if dir != Vector2.ZERO:
		var angle := dir.angle()
		direction_indicator.set_angle(angle)
	else:
		direction_indicator.set_angle(-1.0)
		# var snapped_angle := roundf(angle / (PI / 8.0)) * (PI / 8.0)
		# snapped_direction = Vector2(cos(snapped_angle), sin(snapped_angle))

		# snapped_direction = snapped_direction.normalized()
		# if snapped_direction != Vector2.ZERO:
		#     var snapped_dir_angle := snapped_direction.angle() + 1.0 / 2 * PI + 2 * PI
		#     direction_indicator.set_angle(snapped_dir_angle)
		# else:
		#     direction_indicator.set_angle(-1.0)
	return AnimAction.new("attack_press", 0.05)

func use_release(dir: Vector2) -> AnimAction:
	var time_drawn := Time.get_ticks_msec() - drawing_start
	direction_indicator.hide()
	drawing = false
	if time_drawn < MIN_DRAW_TIME_MS:
		print("too short draw {0}".format([time_drawn]))
		return AnimAction.new()

	var perc_drawn := clampf(float(time_drawn - MIN_DRAW_TIME_MS) / (MAX_DRAW_TIME_MS - MIN_DRAW_TIME_MS), 0, 1)
	audio_shoot.play()
	if dir == Vector2.ZERO:
		dir = Player.player._get_face_dir()

	ammo_count -= 1
	var arrow: Arrow = arrow_ring_buffer[arrow_index]
	print("Player {0} shot arrow {1} from basic bow {2}".format([get_parent_node_3d(), arrow, self]))
	arrow.global_position = global_position
	arrow.impulse = perc_drawn * (IMPULSE_RANGE[1] - IMPULSE_RANGE[0]) + IMPULSE_RANGE[0]
	#print("arrow impulse at {0}, draw_time {1}, perc_drawn {2}".format([arrow.impulse, time_drawn, perc_drawn]))
	arrow.direction = Vector3(dir.x, dir.y, 0).normalized()
	arrow.shoot()
	shot_arrow = arrow
	arrow_index = (arrow_index + 1) % ARROWS_BUFFER_SIZE
	last_use_time = Time.get_ticks_msec()
	return AnimAction.new("attack_release", 0.05)
