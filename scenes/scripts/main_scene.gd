## 主场景组件
class_name MainScene extends Control

## 玩家对象
@onready
var player = $Camera2D/Player

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	$Camera2D/HUDContainer.offset.x = absf(get_screen_position().x)

## 把子节点添加到相机中
func add_child_to_camera(child: Node):
	$Camera2D.add_child(child)
