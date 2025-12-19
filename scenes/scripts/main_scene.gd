## 主场景组件
class_name MainScene extends Control

## 玩家对象
@onready
var player = $Player

func _ready() -> void:
	self.position.y = 0.0

func _physics_process(_delta: float) -> void:
	$HUDContainer.offset.x = absf(get_screen_position().x)

## 把子节点添加到相机中
func add_child_to_camera(child: Node) -> void:
	add_child(child)
