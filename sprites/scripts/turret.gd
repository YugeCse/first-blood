## 炮台组件
class_name Turret extends StaticBody2D

## 被检测的玩家
var spy_player: Player

@onready
var sprite = $Sprite2D

@onready
var collision_shape = $CollisionShape2D

func _ready() -> void:
	sprite.play('left') #方向朝向玩家来的方向

func _physics_process(delta: float) -> void:
	if spy_player: #检测到玩家
		var dir = spy_player.global_position\
			.direction_to(global_position)
		var degress = rad_to_deg(dir.angle())
		if abs(dir.x) > abs(dir.y):
			var x = dir.x
			if x > 0:
				if degress > 25:
					sprite.play('left_up')
				elif degress < -25:
					sprite.play('left_down')
				else: sprite.play('left')
			else:
				if degress < 110:
					sprite.play('right_down')
				elif degress < 160:
					sprite.play('right_up')
				else: sprite.play('right')
		else:
			var y = dir.y
			if y > 0:
				if degress > 25:
					sprite.play('left_up')
				elif degress < -25:
					sprite.play('right_up')
				else: sprite.play('up')
			else:
				print('位置： ', y, ', ', degress)
				if degress < -110:
					sprite.play('right_down')
				elif degress > -70:
					sprite.play('left_down')
				else: sprite.play('down')
		print(name, '-玩家在坦克的角度：', degress, ', ', dir)

func _on_detector_area_2d_area_entered(area: Area2D) -> void:
	var area_parent = area.get_parent()
	if not area_parent: return
	if area_parent is Player and\
		not spy_player: #发现玩家
		spy_player = area_parent
		print('玩家进入监控范围！')
		
func _on_detector_area_2d_area_exited(area: Area2D) -> void:
	var area_parent = area.get_parent()
	if not area_parent: return
	if area_parent is Player and spy_player: #发现玩家
		if area_parent == spy_player:
			spy_player = null
		print('玩家离开了监控范围！')
