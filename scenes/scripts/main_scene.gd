## 主场景组件
class_name MainScene extends Control

@onready
var player = $Camera2D/Player

func _ready() -> void:
	pass

## 把子节点添加到相机中
func add_child_to_camera(child: Node):
	$Camera2D.add_child(child)
