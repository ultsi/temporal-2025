@tool

class_name Level extends Node3D

## creates structure:
## MID -> TilingSystem -> Collisions -> Staticbody1, StaticBody2,...
##                     -> Tiles -> FlatTilesMultiMesh, SpikesMultiMesh, BrickwallMultiMesh 
## 					   -> Dynamic -> DynamicGrassMultiMesh, DynamicSnowMultiMesh
##	   -> PlayerStart
## 	   -> Button
##     -> ...
## F1  -> ...

#region EXPORTS

@export var debug_lights := false

@export_tool_button("Build level")
var build_tiles := func() -> void:
	if Engine.is_editor_hint() && is_inside_tree():
		if name == "Level":
			printerr("Name the level something else than Level!")
			return
		await populate_tiles()
		await take_screenshot()


#endregion

signal occlusion_grid_modified(level: Level)

#region CONSTANTS

const ZGROUPS_WITH_COLLISION := [C.ZGroupEnum.MID]
const CELL_IS_TILE := 1
const CELL_IS_FREE := 2
const CELL_IS_NONTUNNEL := 3

const NON_VISIBLE_CELLS := ["nontunnel"]

#endregion

#region HELPER CLASSES and FUNCTIONS

class TileInfo:
	var pos: Vector2i
	var atlas_coords: Vector2i
	var type: String = ''

	func _init(init_x: int, init_y: int, init_atlas_coords: Vector2i, init_type: String) -> void:
		pos = Vector2i(init_x, init_y)
		atlas_coords = init_atlas_coords
		type = init_type


class TileMultimesh:
	var parent: Node3D
	var owner: Node3D
	var name: String
	var mesh_path: String
	var instance_count: int
	var zgroup: int
	var use_colors: bool
	var use_custom_data: bool

	func create_multimesh() -> MultiMeshInstance3D:
		if zgroup == null || parent == null || owner == null || name == null || mesh_path == null || instance_count == null:
			printerr("Error creating TileMultiMesh. Required parameters missing")
			return null
		var inst := MultiMeshInstance3D.new()
		parent.add_child(inst)
		inst.name = name
		var multimesh := MultiMesh.new()
		var mesh: Mesh = load(mesh_path)
		multimesh.mesh = mesh
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_custom_data = use_custom_data != null
		multimesh.use_colors = use_colors != null
		multimesh.instance_count = instance_count
		multimesh.visible_instance_count = instance_count
		inst.multimesh = multimesh
		inst.owner = owner
		inst.set_meta("tile", true)
		inst.set_meta("_edit_lock_", true)
		inst.set_meta("_edit_group_", true)

		return inst

func get_array_xy(pos: Vector2i) -> int:
	return pos.y * (C.LEVEL_TILES_WIDTH) + pos.x

func get_vector_from_xy(xy: int) -> Vector2i:
	var y := int(float(xy) / C.LEVEL_TILES_WIDTH)
	return Vector2i(xy - C.LEVEL_TILES_WIDTH * y, y)

func get_image_vector_from_xy(xy: int) -> Vector2i:
	var vec := get_vector_from_xy(xy)
	return Vector2i(vec.x, C.LEVEL_TILES_HEIGHT - vec.y - 1)

func get_level_preview_filename() -> String:
	return scene_file_path + ".preview.png"

#endregion

## these are populated below
var tile_systems_by_zgroup: Array[Node3D] = []
var tile_maps_by_zgroup: Array[TileMapLayer] = []

var tile_type_to_mesh := {
	"spikes": "res://materials/tiles/meshes/spikes.tres",
}

var dynamic_shaders: Array[ShaderMaterial] = []

var level_on_screen := true
var occlusion_lookup_grid: Dictionary[int, int] = {}
var occlusion_grid: Dictionary[int, int] = {}
var level_preview: CompressedTexture2D
var multimesh_shader: ShaderMaterial

#region READY

# mask starts from top and goes in CW direction

static func get_neighbors_mask(xy: int, grid: Dictionary[int, int]) -> int:
	if !grid.has(xy):
		print("Weird, tried to calculate the neighbor mask for nonexistent xy ", xy)
		return 0
	
	var mask := 0
	for dir in C.DIRECTION_BITS:
		var nxy := xy + Utils.hash_vector2i_to_int(dir)
		if nxy < 0 || nxy >= Utils.hash_vector2i_to_int(Vector2i(C.LEVEL_TILES_WIDTH - 1, C.LEVEL_TILES_HEIGHT - 1)):
			continue
		if grid[xy + Utils.hash_vector2i_to_int(dir)] == CELL_IS_TILE:
			mask += C.DIRECTION_BITS[dir]
		
	return mask

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## BOTH
	## @todo move to global init
	#RenderingServer.global_shader_parameter_set("LAYERS_Z_DIFF", C.Z_GROUP_DIFF)
	#region TOOL READY
	if Engine.is_editor_hint():
		initialize_boundaries()
		init_zgroup_structure()
		return
	#endregion

	#region GAME READY
	## Get rid of 2D tilemaps
	assert(!Engine.is_editor_hint(), "Level gameplay code running in editor!")
	occlusion_grid_initialize()
	occlusion_grid_compute()

	get_node("TileMaps").queue_free()
	
	## Get rid of 3d boundaries shader
	get_node("BOUNDARIES").queue_free()

	#level_preview = load(get_level_preview_filename())
	#Game.register_level(self)
	#visible = false
	if debug_lights:
		var maybe_mesh_instances := find_children("*", "MultiMeshInstance3D")
		for node: Node in maybe_mesh_instances:
			if node is MultiMeshInstance3D:
				var inst := node as MultiMeshInstance3D
				var mesh = inst.multimesh.mesh
				multimesh_shader = mesh.surface_get_material(1)
				break
	
	#endregion
#endregion
#region physics 
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	if !level_on_screen:
		return

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if !debug_lights:
		return

	if Time.get_ticks_msec() / 1000 % 1 == 0:
		# update shader
		if !multimesh_shader:
			return
		var shader_path := multimesh_shader.shader.resource_path
		var new_shader_code := FileAccess.get_file_as_string(shader_path)
		if multimesh_shader.shader.code != new_shader_code:
			multimesh_shader.shader.code = new_shader_code
			print("Updated shader")
		
#endregion
#region BOUNDARIES
func initialize_boundaries() -> void:
	assert(Engine.is_editor_hint(), "Boundaries initialization only allowed in tool-mode!")
	var boundaries: MeshInstance3D = get_node_or_null("BOUNDARIES")
	# TOOL-ONLY BELOW
	if boundaries == null:
		# boundaries doesn't exist, create new.
		boundaries = MeshInstance3D.new()
		add_child(boundaries)
		move_child(boundaries, 0)
		boundaries.owner = self

		var mesh := QuadMesh.new()
		boundaries.mesh = mesh
		mesh.size = Vector2(C.LEVEL_TILES_WIDTH * 2.0, C.LEVEL_TILES_HEIGHT * 2.0)

		boundaries.position = Vector3(C.LEVEL_TILES_WIDTH, C.LEVEL_TILES_HEIGHT, -50)
		boundaries.name = "BOUNDARIES"
		boundaries.set_meta("_edit_lock_", true)
		boundaries.set_meta("_edit_group_", true)

		var shader: Shader = load("res://core/level/boundaries.gdshader")
		var material := ShaderMaterial.new()
		material.shader = shader

		boundaries.set_surface_override_material(0, material)

#endregion

#region LEVEL VISIBILITY OPTIMIZER
func is_visible_from_camera_pos(camera_pos: Vector3) -> bool:
	# level starts from bottom left always
	if camera_pos.x < global_position.x:
		return false

	if camera_pos.y < global_position.y:
		return false

	if camera_pos.x > global_position.x + C.LEVEL_WORLD_WIDTH * 0.5:
		return false
	
	if camera_pos.y > global_position.y + C.LEVEL_WORLD_HEIGHT * 0.5:
		return false

	return true


func show_level() -> void:
	level_on_screen = true
	visible = true


func hide_level() -> void:
	level_on_screen = false
	visible = false
#endregion

#region CELL VISIBILITY CHANGING
## start_pos in global coordinates
func occlusion_grid_initialize() -> void:
	var mid_tilemap: TileMapLayer = get_node_or_null("TileMaps/MID")
	if mid_tilemap != null:
		var MIN_X: int = mid_tilemap.get_meta("MIN_X")
		var MAX_X: int = mid_tilemap.get_meta("MAX_X")
		var MIN_Y: int = mid_tilemap.get_meta("MIN_Y")
		var MAX_Y: int = mid_tilemap.get_meta("MAX_Y")
		for x in range(MIN_X, MAX_X):
			for tile_y in range(MIN_Y, MAX_Y, -1):
				var y := -tile_y - 1
				var cell := mid_tilemap.get_cell_tile_data(Vector2i(x, tile_y))
				var xy := Utils.hash_vector2i_to_int(Vector2i(x, y))
				if cell == null:
					occlusion_lookup_grid[xy] = CELL_IS_FREE
					continue
				
				var data: Variant = cell.get_custom_data("type")
				if data == "nontunnel":
					occlusion_lookup_grid[xy] = CELL_IS_NONTUNNEL
					continue
				
				occlusion_lookup_grid[xy] = CELL_IS_TILE


func occlusion_grid_calculate_bits_for_pos(pos: Vector2i) -> int:
	var bits := 0
	
	for dir in C.NEIGHBORS_DIRS:
		var pos_key := Utils.hash_vector2i_to_int(pos + dir)
		if occlusion_lookup_grid.get(pos_key, -1) == CELL_IS_TILE:
			bits += C.DIRECTION_BITS[dir]

	var pos_xyhash := Utils.hash_vector2i_to_int(pos)
	var center: int = occlusion_lookup_grid.get(pos_xyhash, -1)
	if center == CELL_IS_TILE:
		bits += 256
	elif center == CELL_IS_NONTUNNEL:
		bits += 512
	
	return bits

# @optimize
func occlusion_grid_compute() -> void:
	for x in C.LEVEL_TILES_WIDTH:
		for y in C.LEVEL_TILES_HEIGHT:
			var pos := Vector2i(x, y)
			var pos_key := Utils.hash_vector2i_to_int(pos)
			occlusion_grid[pos_key] = occlusion_grid_calculate_bits_for_pos(pos)

# @optimize
func occlusion_grid_change(start_pos: Vector3, size: Vector2i, occlude: bool) -> void:
	print("Level occlusion grid changed!")
	var time := Time.get_ticks_usec()
	var local_start_pos := to_local(start_pos)
	var start_pos_2d := Vector2(local_start_pos.x, local_start_pos.y)
	var grid_pos := start_pos_2d / Vector2(C.LEVEL_WORLD_WIDTH, C.LEVEL_WORLD_HEIGHT)
	@warning_ignore("narrowing_conversion")
	var tile_pos := Vector2i(C.LEVEL_TILES_WIDTH * grid_pos.x, C.LEVEL_TILES_HEIGHT * grid_pos.y)

	var occlusion_type := CELL_IS_TILE if occlude else CELL_IS_FREE
	for x in size.x:
		for y in size.y:
			occlusion_lookup_grid[Utils.hash_vector2i_to_int(tile_pos + Vector2i(x, y))] = occlusion_type

	occlusion_grid_compute()

	print("Computing occlusion grid changes took ", (Time.get_ticks_usec() - time) / 1000.0, "ms")
	
	occlusion_grid_modified.emit(self)
#endregion


#region INIT ZGROUP STRUCTURE

func init_zgroup_structure() -> void:
	##
	## Check or create tilemaps root group node
	##
	var tile_maps_parent: Node2D = get_node_or_null("TileMaps")
	if tile_maps_parent == null:
		tile_maps_parent = Node2D.new()
		add_child(tile_maps_parent)
		tile_maps_parent.owner = self
		tile_maps_parent.name = "TileMaps"

	## 
	## Check or create 3d zgroup nodes
	## -> Into them create TilingSystem and Collision group nodes
	## Finally check or create TileMaps per zgroup
	##
	for zgroup in C.ZGroupEnum.MAX:
		var zgroup_name := C.ZGroupEnumStr[zgroup]
	
		## Create Zgroup if not exists
		var zgroup_node: Node3D = get_node_or_null(zgroup_name)
		if zgroup_node == null:
			zgroup_node = Node3D.new()
			add_child(zgroup_node)
			zgroup_node.owner = self
			zgroup_node.name = zgroup_name

		# replace old Node3D implementation with ZGroup type
		if zgroup_node is not ZGroup:
			var old_zgroup_node := zgroup_node
			old_zgroup_node.name += "_"
			var old_children := zgroup_node.get_children()
			match zgroup:
				C.ZGroupEnum.B3:
					zgroup_node = B3ZGroup.new()
				C.ZGroupEnum.B2:
					zgroup_node = B2ZGroup.new()
				C.ZGroupEnum.B1:
					zgroup_node = B1ZGroup.new()
				C.ZGroupEnum.MID:
					zgroup_node = MidZGroup.new()
				C.ZGroupEnum.F1:
					zgroup_node = F1ZGroup.new()
				C.ZGroupEnum.F2:
					zgroup_node = F2ZGroup.new()
			add_child(zgroup_node)
			zgroup_node.owner = self
			zgroup_node.name = zgroup_name
			# this needs to be done to not get the Z_GROUP_DIFF applied twice, because
			# reparenting will keep the childs global position, meaning if Node1 was at z = 4
			# and its being reparented to Node2 at z=0, the child will have z=4 itself to 
			# make sure it keeps its global position
			zgroup_node.position.z = (zgroup - C.ZGroupEnum.MID) * C.Z_GROUP_DIFF
			for child in old_children:
				child.reparent(zgroup_node)
			
			old_zgroup_node.queue_free()
			

		zgroup_node.position.z = (zgroup - C.ZGroupEnum.MID) * C.Z_GROUP_DIFF

		## Create ZGroup->TilingSystem group if not exists
		var tiling_system_node: Node3D = zgroup_node.get_node_or_null("TilingSystem")
		if tiling_system_node == null:
			tiling_system_node = Node3D.new()
			zgroup_node.add_child(tiling_system_node)
			tiling_system_node.owner = self
			tiling_system_node.name = "TilingSystem"
		
		tile_systems_by_zgroup.insert(zgroup, tiling_system_node)
		
		## Create ZGroup->TilingSystem->Collision group if not exists
		var collision_group_node: Node3D = tiling_system_node.get_node_or_null("Collision")
		if ZGROUPS_WITH_COLLISION.has(zgroup) && collision_group_node == null:
			## create collision node
			collision_group_node = Node3D.new()
			tiling_system_node.add_child(collision_group_node)
			collision_group_node.name = "Collision"
			collision_group_node.owner = self
			collision_group_node.set_meta("_edit_lock_", true)
			collision_group_node.set_meta("_edit_group_", true)
		
		## Create ZGroup->TilingSystem->Tiles group if not exists
		var tiles_group_node: Node3D = tiling_system_node.get_node_or_null("Tiles")
		if tiles_group_node == null:
			## create tiles node
			tiles_group_node = Node3D.new()
			tiling_system_node.add_child(tiles_group_node)
			tiles_group_node.name = "Tiles"
			tiles_group_node.owner = self
			tiles_group_node.set_meta("_edit_lock_", true)
			tiles_group_node.set_meta("_edit_group_", true)
		

		## Create ZGroup->TilingSystem->Dynamic group if not exists
		var dynamic_group_node: Node3D = tiling_system_node.get_node_or_null("Dynamic")
		if dynamic_group_node == null:
			## create tiles node
			dynamic_group_node = Node3D.new()
			tiling_system_node.add_child(dynamic_group_node)
			dynamic_group_node.name = "Dynamic"
			dynamic_group_node.owner = self
			dynamic_group_node.set_meta("_edit_lock_", true)
			dynamic_group_node.set_meta("_edit_group_", true)

		
		## Create TileMaps->Zgroup tilemap if not exists
		var tile_map: TileMapLayer = tile_maps_parent.get_node_or_null(zgroup_name)
		if tile_map == null:
			tile_map = TileMapLayer.new()
			tile_maps_parent.add_child(tile_map)
			tile_map.owner = self
			tile_map.name = zgroup_name
			tile_map.tile_set = load("res://materials/tiles/tileset.tres")

		tile_maps_by_zgroup.insert(zgroup, tile_map)

		## Set tilemap defaults!
		# always set boundaries, but as corners instead
		# always because if these have been removed, this resets them
		var MIN_X := -1
		var MAX_X := C.LEVEL_TILES_WIDTH
		var MIN_Y := 0
		var MAX_Y := -C.LEVEL_TILES_HEIGHT - 1
		tile_map.set_meta("MIN_X", MIN_X)
		tile_map.set_meta("MAX_X", MAX_X)
		tile_map.set_meta("MIN_Y", MIN_Y)
		tile_map.set_meta("MAX_Y", MAX_Y)

		# delete data which is outside MIN_X and MAX_X and delete old boundaries
		for cell_pos in tile_map.get_used_cells():
			if cell_pos.x < MIN_X || cell_pos.x > MAX_X || cell_pos.y > MIN_Y || cell_pos.y < MAX_Y:
				tile_map.erase_cell(cell_pos)
				continue
			if tile_map.get_cell_source_id(cell_pos) == 0:
				tile_map.erase_cell(cell_pos)

		# left & right (red & cyan)
		var red := Vector2i(0, 0)
		var cyan := Vector2i(1, 1)
		for y in range(MIN_Y, MAX_Y - 1, -1):
			tile_map.set_cell(Vector2i(MIN_X, y), 0, red)
			tile_map.set_cell(Vector2i(MAX_X, y), 0, cyan)
		
		# top & bottom (green & purple)
		var green := Vector2i(1, 0)
		var purple := Vector2i(0, 1)
		for x in range(MIN_X, MAX_X + 1):
			tile_map.set_cell(Vector2i(x, MAX_Y), 0, green)
			tile_map.set_cell(Vector2i(x, MIN_Y), 0, purple)

		tile_map.z_index = zgroup


	# move their positions
	for zgroup in C.ZGroupEnum.MAX:
		var zgroup_name := C.ZGroupEnumStr[zgroup]
		var tile_map: TileMapLayer = tile_maps_by_zgroup[zgroup]
		var zgroup_node := get_node(zgroup_name)
		move_child(tile_maps_parent, 0)
		tile_maps_parent.move_child(tile_map, zgroup)
		move_child(zgroup_node, 1 + zgroup)

#endregion

func create_dynamic_grass(tiles: Array[TileInfo], zgroup: int, color: Color) -> void:
	var tile_system: Node3D = tile_systems_by_zgroup[zgroup]
	var dynamic_parent: Node3D = tile_system.get_node("Dynamic")
	var params := TileMultimesh.new()
	params.parent = dynamic_parent
	params.name = "Grass"
	params.instance_count = tiles.size() * 3
	params.owner = self
	params.mesh_path = "res://materials/tiles/meshes/dynamic/grass.tres"
	params.use_colors = true
	params.zgroup = zgroup
	var mm_inst := params.create_multimesh()
	var multimesh := mm_inst.multimesh
	mm_inst.position.z -= 1
	var grass_basis := Basis.from_scale(Vector3.ONE)

	for i in tiles.size():
		var tile := tiles[i]
		var tile_top_center := Vector3(tile.pos.x * 2 + 1, tile.pos.y * 2 + 2, 0)
		multimesh.set_instance_transform(i * 3, Transform3D(grass_basis.scaled(Vector3.ONE * randf_range(0.8, 1.2)), tile_top_center + Vector3(-1, 0, 0)))
		multimesh.set_instance_transform(i * 3 + 1, Transform3D(grass_basis.scaled(Vector3.ONE * randf_range(0.8, 1.2)), tile_top_center + Vector3(0, 0, 0)))
		multimesh.set_instance_transform(i * 3 + 2, Transform3D(grass_basis.scaled(Vector3.ONE * randf_range(0.8, 1.2)), tile_top_center + Vector3(1, 0, 0)))
		multimesh.set_instance_color(i * 3, color)
		multimesh.set_instance_color(i * 3 + 1, color)
		multimesh.set_instance_color(i * 3 + 2, color)
	
	mm_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	dynamic_shaders.append(multimesh.mesh.surface_get_material(0))


#region POPULATION
##
## This populates the TilingSystem group node
## 1. 	It populates multimeshes for TilingSystem->Tiles node and forms 
## 		a lookup table for creating collision bodies
## 2.   It populates collision bodies for TilingSystem->Collision node
## 		using the lookup table
## 3.   It populates dynamic meshes for TilingSystem->Dynamic node
##

# helper func to figure out longest bodies in direction
func count_tiles_in_dir(dir: Vector2i, pos: Vector2i, tile_xy_lookup: Dictionary[int, Variant], check: Callable, res: int = 0) -> int:
	pos += dir
	var this := get_array_xy(pos)
	while (pos.x > -1 && pos.x < C.LEVEL_TILES_WIDTH
			&& pos.y > -1 && pos.y < C.LEVEL_TILES_HEIGHT
			&& tile_xy_lookup.has(this) && check.call(tile_xy_lookup[this])):
		tile_xy_lookup.erase(this)
		res += 1
		pos += dir
		this = get_array_xy(pos)

	return res

func create_box_for_static_body(body: WorldTile) -> BoxShape3D:
	var box := BoxShape3D.new()
	box.size = Vector3(2, 2, 2)
	
	var shape := CollisionShape3D.new()
	shape.shape = box
	body.add_child(shape)

	shape.owner = self
	return box

func create_static_body_for_tile(tile: TileInfo, collision_parent: Node) -> WorldTile:
	## create a staticbody box
	var body := WorldTile.new()
	collision_parent.add_child(body)
	body.position = Vector3(tile.pos.x * 2 + 1, tile.pos.y * 2 + 1, 0)
	
	body.owner = self

	return body

class MeshGroup:
	var scale: Vector3
	var pos: Vector3
	var custom_data: Color

	func _init(i_scale: Vector3, i_pos: Vector3, i_custom_data: Color) -> void:
		scale = i_scale
		pos = i_pos
		custom_data = i_custom_data

func count_neighbor_tiles(pos: Vector2i, lookup: Dictionary) -> int:
	var sum := 0
	for dir in C.NEIGHBORS_DIRS:
		var new_pos := pos + dir
		if (new_pos.x > C.LEVEL_TILES_WIDTH || new_pos.x < 0
			|| new_pos.y > C.LEVEL_TILES_HEIGHT || new_pos.y < 0
			|| lookup.has(get_array_xy(new_pos))):
			sum += 1
	return sum


func populate_tiling_system_for_zgroup(zgroup: int, free_depth_xy_lookup: Dictionary[int, int]) -> void:
	var tile_system: Node3D = tile_systems_by_zgroup[zgroup]
	var tile_map: TileMapLayer = tile_maps_by_zgroup[zgroup]
	var tiles_parent: Node3D = tile_system.get_node("Tiles")

	var MIN_X: int = tile_map.get_meta("MIN_X")
	var MAX_X: int = tile_map.get_meta("MAX_X")
	var MIN_Y: int = tile_map.get_meta("MIN_Y")
	var MAX_Y: int = tile_map.get_meta("MAX_Y")

	#region INIT ARRAYS
	var all_tiles: Array[TileInfo] = []
	var tiles_by_type := {}
	var tile_xy_visual_lookup: Dictionary[int, Variant] = {}
	var tile_xy_density_lookup: Dictionary[int, bool] = {}
	var tile_xy_collision_lookup: Dictionary[int, Variant] = {}
	## First gather all different tiles in a 
	## "grass": [TileInfo(x,y)], "black": [TileInfo(x,y), TileInfo(x,y)] format
	## and also form a lookup array for creating collision bodies
	for x in range(MIN_X, MAX_X + 1):
		for tile_y in range(MIN_Y, MAX_Y - 1, -1):
			var y := -tile_y - 1
			var cell := tile_map.get_cell_tile_data(Vector2i(x, tile_y))
			var xy := get_array_xy(Vector2i(x, y))
			if cell == null:
				var free_depth := free_depth_xy_lookup[xy] if free_depth_xy_lookup.has(xy) else 0
				free_depth_xy_lookup[xy] = free_depth + 1
				continue

			var data: Variant = cell.get_custom_data("type")
			if data is not String or data == "":
				continue

			var type: String = data

			if NON_VISIBLE_CELLS.has(type):
				continue

			if !tiles_by_type.has(type):
				var new_arr: Array[TileInfo] = []
				tiles_by_type[type] = new_arr
			
			var coords := tile_map.get_cell_atlas_coords(Vector2i(x, tile_y))
			var tile := TileInfo.new(x, y, coords, type)
			var arr: Array[TileInfo] = tiles_by_type[type]
			arr.append(tile)
			all_tiles.append(tile)
			tile_xy_visual_lookup[xy] = coords
			tile_xy_collision_lookup[xy] = tile.type
			if zgroup == C.ZGroupEnum.MID:
				tile_xy_density_lookup[xy] = true

	#endregion

	#region FLAT MULTIMESH
	## create single multimesh for all different flat tiles for this layer
	## material is changed by UV values in shader
	## @optimize the 
	var params := TileMultimesh.new()
	params.parent = tiles_parent
	params.owner = self
	params.name = "FlatTiles"
	params.mesh_path = "res://materials/tiles/meshes/uv_mapped_box_no_backface.tres"
	params.use_custom_data = true
	params.zgroup = zgroup

	## group same tiles together horizontally
	var mesh_groups: Dictionary[int, MeshGroup] = {}
	for tile in all_tiles:
		var cur := get_array_xy(tile.pos)

		if !tile_xy_visual_lookup.has(cur):
			continue ## this has already been used by some other
		var free_depth := free_depth_xy_lookup[cur] if free_depth_xy_lookup.has(cur) else 0
		free_depth_xy_lookup[cur] = 0
		tile_xy_visual_lookup.erase(cur) ## mark this used

		var mesh_scale := Vector3(1, 1, free_depth + 1)
		var pos := Vector3(tile.pos.x * 2 + 1, tile.pos.y * 2 + 1, -free_depth * 2.0 - 1.0)
		
		var left_count := count_tiles_in_dir(Vector2i.LEFT, tile.pos, tile_xy_visual_lookup, func(a: Vector2i) -> bool: return a == tile.atlas_coords)
		var right_count := count_tiles_in_dir(Vector2i.RIGHT, tile.pos, tile_xy_visual_lookup, func(a: Vector2i) -> bool: return a == tile.atlas_coords)
		mesh_scale.x += left_count + right_count
		pos.x += left_count + right_count

		var up_count := 0
		var down_count := 0
		if left_count == 0 && right_count == 0:
			up_count = count_tiles_in_dir(Vector2i.UP, tile.pos, tile_xy_visual_lookup, func(a: Vector2i) -> bool: return a == tile.atlas_coords)
			down_count = count_tiles_in_dir(Vector2i.DOWN, tile.pos, tile_xy_visual_lookup, func(a: Vector2i) -> bool: return a == tile.atlas_coords)
			mesh_scale.y += up_count + down_count
			pos.y += up_count + down_count

		var custom_uv := tile.atlas_coords / 16.0
		mesh_groups[cur] = MeshGroup.new(mesh_scale, pos, Color(custom_uv.x, custom_uv.y, 1.0 / (left_count + right_count + 1), 1.0 / (up_count + down_count + 1)))


		#endregion

	params.instance_count = mesh_groups.size()
	var mm_inst := params.create_multimesh()
	if zgroup == C.ZGroupEnum.MID:
		mm_inst.set_layer_mask_value(C.RenderLayers.MID_EDGES, true)
	var multimesh := mm_inst.multimesh
	var i := 0
	## set transforms and UV params for each tile
	for key: int in mesh_groups:
		var group := mesh_groups[key]
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(group.scale), group.pos))
		multimesh.set_instance_custom_data(i, group.custom_data)
		i += 1

	#endregion

	#region COLLISION

	# for now all can be grouped, probably non-collision tiles coming up at some point
	# so this needs to be changed.
	var tile_type_can_be_grouped := func(_type: String) -> bool:
		return true

	if ZGROUPS_WITH_COLLISION.has(zgroup):
		var collision_parent := tile_system.get_node("Collision")
		## because it's more likely that there are horizontal platforms
		## than vertical ones, just try to form horizontally bigger bodies

		for tile in all_tiles:
			var cur := get_array_xy(tile.pos)
			if !tile_xy_collision_lookup.has(cur):
				continue ## this has already been used by some other
			tile_xy_collision_lookup.erase(cur) ## mark this used

			var body := create_static_body_for_tile(tile, collision_parent)
			var box := create_box_for_static_body(body)

			var left_count := count_tiles_in_dir(Vector2i.LEFT, tile.pos, tile_xy_collision_lookup, tile_type_can_be_grouped)
			var right_count := count_tiles_in_dir(Vector2i.RIGHT, tile.pos, tile_xy_collision_lookup, tile_type_can_be_grouped)
			box.size.x += left_count * 2 + right_count * 2
			body.position.x += left_count + right_count

			var up_count := 0
			var down_count := 0
			if left_count == 0 && right_count == 0:
				up_count = count_tiles_in_dir(Vector2i.UP, tile.pos, tile_xy_collision_lookup, tile_type_can_be_grouped)
				down_count = count_tiles_in_dir(Vector2i.DOWN, tile.pos, tile_xy_collision_lookup, tile_type_can_be_grouped)
				box.size.y += up_count * 2 + down_count * 2
				body.position.y += up_count + down_count

			body.editor_description = "Pos: {0}, left_count: {1}, right_count: {2}, up_count: {3}, down_count: {4}".format([tile.pos, left_count, right_count, up_count, down_count])


	#endregion

	#region DYNAMIC MULTIMESH
	if tiles_by_type.has("grass"):
		var tiles: Array[TileInfo] = tiles_by_type["grass"]
		create_dynamic_grass(tiles, zgroup, Color(0, 1, 0))
	
	if tiles_by_type.has("bluegrass"):
		var tiles: Array[TileInfo] = tiles_by_type["bluegrass"]
		create_dynamic_grass(tiles, zgroup, Color(0, 0.5, 1))

	#endregion


#endregion

func populate_tiles() -> void:
	var start := Time.get_ticks_msec()
	var free_depth_xy_lookup: Dictionary[int, int] = {}
	for zgroup in C.ZGroupEnum.MAX:
		var tile_system: Node3D = tile_systems_by_zgroup[zgroup]
		for child in tile_system.get_children():
			child.queue_free()

	await get_tree().create_timer(0.0).timeout
	init_zgroup_structure()
	await get_tree().create_timer(0.0).timeout
	for zgroup in C.ZGroupEnum.MAX:
		populate_tiling_system_for_zgroup(zgroup, free_depth_xy_lookup)
	print("Populated all tiles in %s ms" % (Time.get_ticks_msec() - start))

#region SCREENSHOT

func take_screenshot() -> void:
	## TAKE SCREENSHOT
	#Append mainscene 
	if scene_file_path.is_empty():
		printerr("Not taking screenshot, save the level first!")
		return
	var resource: PackedScene = load("res://core/autoloads/2_g/camera_and_visuals.tscn")
	var camera_and_visuals: Node3D = resource.instantiate()
	add_child(camera_and_visuals)
	camera_and_visuals.owner = self

	if !camera_and_visuals.has_node("MainCamera/Screenshot"):
		return

	#var dir_light := camera_and_visuals.get_node("DirectionalLights/DirectionalLight3D") as DirectionalLight3D
	#dir_light.light_energy = 0.1

	var viewport: SubViewport = camera_and_visuals.get_node("MainCamera/Screenshot")
	
	await get_tree().physics_frame
	await RenderingServer.frame_pre_draw
	await RenderingServer.frame_post_draw
	var texture := viewport.get_texture()
	var image := texture.get_image() # .get_region(Rect2i(Vector2i(0, 4), Vector2i(640, 352)))
	print("saved screenshot to " + get_level_preview_filename())
	image.save_png(get_level_preview_filename())

	camera_and_visuals.queue_free()


#endregion

func _get_configuration_warnings() -> PackedStringArray:
	if name == "Level":
		return ["Using default name. Name the Level more descriptively"]
	return []