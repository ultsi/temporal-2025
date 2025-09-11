@tool
extends Node3D

@export_range(0.1, 100.0, 0.1) var radius := 5.0:
    set(value):
        radius = value
        form_circle()

func _ready() -> void:
    form_circle()

func form_circle() -> void:
    var node3d_childs: Array[Node3D] = []
    for child: Node in get_children():
        if child is Node3D:
            node3d_childs.append(child)

    for i in range(0, node3d_childs.size()):
        var ang := 2.0 * PI * i / float(node3d_childs.size())
        var x := sin(ang) * radius
        var y := cos(ang) * radius
        var node := node3d_childs[i]
        node.position = Vector3(x, y, 0)
