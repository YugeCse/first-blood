## 炮台组件
class_name Turret extends StaticBody2D

## 被检测的玩家
var spy_player: Player

@onready
var sprite = $Sprite2D

@onready
var collision_shape = $CollisionShape2D


func _ready() -> void:
	sprite.play('left')  #方向朝向玩家来的方向


func _physics_process(delta: float) -> void:
	#region 检测到玩家，进行旋转处理
	if spy_player:  #检测到玩家
		var dir = spy_player.global_position \
			.direction_to(global_position)
		var degress = wrapf(rad_to_deg(dir.angle()), 0, 360)  #计算角度值，方便计算方位
		if degress > 22.5 and degress <= 67.5:  #左上
			sprite.play('left_up')
		elif degress > 67.5 and degress <= 112.5:  #上
			sprite.play('up')
		elif degress > 112.5 and degress <= 157.5:  #右上
			sprite.play('right_up')
		elif degress > 157.5 and degress <= 202.5:  #右
			sprite.play('right')
		elif degress > 202.5 and degress <= 247.5:  #右下
			sprite.play('right_down')
		elif degress > 247.5 and degress <= 292.5:  #下
			sprite.play('down')
		elif degress > 292.5 and degress <= 337.5:  #左下
			sprite.play('left_down')
		elif degress > 337.5 or degress <= 22.5:  #左
			sprite.play('left')
		print(name, '-玩家在坦克的角度：', degress, ', ', dir)
	#endregion


func _on_detector_area_2d_area_entered(area: Area2D) -> void:
	var area_parent = area.get_parent()
	if not area_parent: return
	if area_parent is Player and \
		not spy_player:  #发现玩家
			spy_player = area_parent
		print('玩家进入监控范围！')


func _on_detector_area_2d_area_exited(area: Area2D) -> void:
	var area_parent = area.get_parent()
	if not area_parent: return
	if area_parent is Player and spy_player:  #发现玩家
		if area_parent == spy_player:
			spy_player = null
		print('玩家离开了监控范围！')
