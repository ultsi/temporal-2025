## Common constants and enums
@tool
@abstract class_name C extends RefCounted

const LAYER_Z_DIFF := 2.0

const TICKS_PER_SECOND := 60
const TIME_BETWEEN_TICKS := 1.0 / TICKS_PER_SECOND

enum RenderLayers {
	WORLD_DEFAULT = 1,
	MID_EDGES = 2,
	COMBINED = 3,
	FLUX_ON = 4,
	STASIS_ON = 5,
	PLAYER = 6,
	TEMPORAL_ENTITIES = 7,
	PRESELECT = 8
}

# collision layers
enum CollisionLayers {
	PLAYER = 2,
	ENEMY = 3,
	NON_RESETABLE_AREA = 4,
	WATER = 7,
	PLAYER_USABLE = 8,
	PLAYER_CLIMBABLE = 9,
	TIME_RADIATION = 10,
}

enum ZGroupEnum {
	B3,
	B2,
	B1,
	MID,
	F1,
	F2,
	MAX
}

const ZGroupEnumStr: Dictionary[ZGroupEnum, String] = {
	ZGroupEnum.B3: "B3",
	ZGroupEnum.B2: "B2",
	ZGroupEnum.B1: "B1",
	ZGroupEnum.MID: "MID",
	ZGroupEnum.F1: "F1",
	ZGroupEnum.F2: "F2",
}

const Z_GROUP_DIFF := 4

const LEVEL_TILES_WIDTH := 40
const LEVEL_TILES_HEIGHT := 22
const LEVEL_WORLD_WIDTH := LEVEL_TILES_WIDTH * 2 ## meters
const LEVEL_WORLD_HEIGHT := LEVEL_TILES_HEIGHT * 2 ## meters


const NEIGHBORS_DIRS: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	#Vector2i(0, 0), # mid not needed
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
]

const ORTHOGONAL_DIRS_CW: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(0, 1)
]

const DIAGONALS_DIRS_CW: Array[Vector2i] = [
	Vector2(1, 1),
	Vector2i(1, -1),
	Vector2i(-1, -1),
	Vector2(-1, 1)
]

const DIRECTION_BITS: Dictionary[Vector2i, int] = {
	Vector2i(0, 1): 1,
	Vector2i(1, 1): 2,
	Vector2i(1, 0): 4,
	Vector2i(1, -1): 8,
	Vector2i(0, -1): 16,
	Vector2i(-1, -1): 32,
	Vector2i(-1, 0): 64,
	Vector2i(-1, 1): 128,
}

const DIRECTION_BIT_NORTH := DIRECTION_BITS[Vector2i(0, 1)]
const DIRECTION_BIT_SOUTH := DIRECTION_BITS[Vector2i(0, -1)]
const DIRECTION_BIT_EAST := DIRECTION_BITS[Vector2i(1, 0)]
const DIRECTION_BIT_WEST := DIRECTION_BITS[Vector2i(-1, 0)]
