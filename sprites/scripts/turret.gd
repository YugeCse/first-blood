## 炮台组件
class_name Turret extends StaticBody2D

@onready
var sprite = $Sprite2D

@onready
var collision_shape = $CollisionShape2D

func _ready() -> void:
	sprite.play('left') #方向朝向玩家来的方向

func _physics_process(delta: float) -> void:
	pass

func _on_detector_area_2d_area_entered(area: Area2D) -> void:
	var area_parent = area.get_parent()
	if not area_parent: return
	if area_parent is Player: #发现玩家
		print('玩家进入监控范围！')
		
func _on_detector_area_2d_area_exited(area: Area2D) -> void:
	var area_parent = area.get_parent()
	if not area_parent: return
	if area_parent is Player: #发现玩家
		print('玩家离开了监控范围！')
