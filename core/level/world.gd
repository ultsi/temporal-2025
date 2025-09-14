@tool
class_name World extends Node3D


func load_levels() -> void:
	for child in get_children():
		if child is not LevelPreview:
			continue
		
		var level_preview: LevelPreview = child
		var level := level_preview.get_level_inst()
		if !level:
			continue
		add_child(level)
		level.global_position = level_preview.global_position
		level_preview.queue_free()


func _ready() -> void:
	if !Engine.is_editor_hint():
		load_levels()
		#Game.map.set_map_filename(get_map_filename())

	
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	for n in get_children():
		if n is LevelPreview:
			var level := n as LevelPreview
			if level.global_position.x < 0:
				warnings.append("Level {0} position is too far left (x<0)".format([level]))
			if level.global_position.y < 0:
				warnings.append("Level {0} position is too far down (y<0)".format([level]))
			if int(level.global_position.x) % C.LEVEL_WORLD_WIDTH != 0:
				warnings.append("Level {0} x position is not multiple of {1}".format([level, C.LEVEL_WORLD_WIDTH]))
			if int(level.global_position.y) % C.LEVEL_WORLD_HEIGHT != 0:
				warnings.append("Level {0} y position is not multiple of {1}".format([level, C.LEVEL_WORLD_HEIGHT]))

	return warnings
