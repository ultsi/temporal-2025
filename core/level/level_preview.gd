@tool

class_name LevelPreview extends Node3D

@export_tool_button("Go to scene", "Callable") var go_to_scene_btn := _go_to_scene_func

func _go_to_scene_func() -> void:
	if level_file:
		EditorInterface.call_deferred("open_scene_from_path", level_file)

@export_file("level_*.tscn") var level_file: String:
	set(value):
		if !value:
			level_file = value
			preview = null
		elif _check_level_preview(value):
			level_file = value
			if is_inside_tree():
				await update_preview()

@export_category("Easy Transform")
@export var up := false:
	set(value):
		if value && is_inside_tree():
			global_position.y += 44
			global_position.y = snappedi(global_position.y, 44)
@export var down := false:
	set(value):
		if value && is_inside_tree():
			global_position.y -= 44
			global_position.y = snappedi(global_position.y, 44)

@export var left := false:
	set(value):
		if value && is_inside_tree():
			global_position.x -= 80
			global_position.x = snappedi(global_position.x, 80)

@export var right := false:
	set(value):
		if value && is_inside_tree():
			global_position.x += 80
			global_position.x = snappedi(global_position.x, 80)

var preview: Resource

func _ready() -> void:
	if Engine.is_editor_hint():
		await update_preview()

func get_preview_file(filepath: String) -> String:
	return filepath + ".preview.png"

func update_preview() -> void:
	# try to load preview of the level as a correct sized sprite3D
	if preview == null:
		printerr("No preview resource loaded!")
		return

	if get_node_or_null("Preview") != null:
		var old_preview := get_node("Preview")
		old_preview.queue_free()
		await get_tree().create_timer(0.1).timeout

	var sprite := Sprite3D.new()
	sprite.texture = preview
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.pixel_size = 0.125

	add_child(sprite)
	sprite.owner = self
	sprite.name = "Preview"

func get_level_inst() -> Level:
	if !level_file:
		return
	
	var resource: Resource = load(level_file)
	if resource is not PackedScene:
		printerr("Level is not PackedScene!")
		return
	var scene: PackedScene = resource
	var inst := scene.instantiate()

	if inst is not Level:
		printerr("Level " + level_file + " is not of Level class")
		inst.queue_free()
		return

	return inst

func _check_level_preview(uid: String) -> bool:
	var filepath := ResourceUID.uid_to_path(uid)
	if !filepath || filepath.is_empty():
		return false
	
	var resource: Resource = load(filepath)
	if resource is not PackedScene:
		printerr("Level is not PackedScene!")
		return false
	var scene: PackedScene = resource
	var inst := scene.instantiate()

	var is_level := inst is Level
	inst.queue_free()

	if !is_level:
		printerr("Level is not of Level class")
		return false

	preview = load(get_preview_file(filepath))
	if preview == null:
		printerr("No level preview file exists for Level " + filepath)
		return false

	name = inst.name + "Preview"

	return true