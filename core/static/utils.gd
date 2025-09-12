@tool
@abstract class_name Utils extends RefCounted

static func hash_vector2i_to_int(pos: Vector2i) -> int:
	return pos.y * (C.LEVEL_TILES_WIDTH) + pos.x

static func hash_int_to_vector2i(xy_hash: int) -> Vector2i:
	var y := int(float(xy_hash) / C.LEVEL_TILES_WIDTH)
	return Vector2i(xy_hash - C.LEVEL_TILES_WIDTH * y, y)


static func is_tile_pos_out_of_bounds(pos: Vector2i) -> bool:
	return pos.x < 0 || pos.y < 0 || pos.x >= C.LEVEL_TILES_WIDTH || pos.y >= C.LEVEL_TILES_HEIGHT

static func time_since_tick_ms(tick: int) -> int:
	return int(float(T.global_tick - tick) / C.TICKS_PER_SECOND * 1000.0)

static func tick_from_now(time: float) -> int:
	return T.global_tick + int(time * C.TICKS_PER_SECOND)

static func tick_to_time(tick: int) -> float:
	return tick * C.TIME_BETWEEN_TICKS