## 主场景组件
class_name MainScene extends Control

@onready
var player = $Camera2D/Player

@onready
var camera = $Camera2D

@onready
var hud_container = $Camera2D/HUDContainer

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	hud_container.offset.x = absf(get_screen_position().x)

## 把子节点添加到相机中
func add_child_to_camera(child: Node):
	camera.add_child(child)
