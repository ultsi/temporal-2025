class_name AnimAction extends RefCounted
var anim := ""
var playtime := 0.0

func _init(p_anim := "", p_playtime := 0.0) -> void:
    anim = p_anim
    playtime = p_playtime
