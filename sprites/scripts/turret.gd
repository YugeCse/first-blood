## 炮台组件
class_name Turret extends StaticBody2D

## 被检测的玩家
var spy_player: Player

## 炮台射击的角度
var shoot_degress: float = 180.0

@onready
var sprite = $Sprite2D

@onready
var collision_shape = $CollisionShape2D

@onready
var shoot_timer = $ShootTimer

## 子弹资源
@onready
var bullet_resource = preload("res://sprites/tscns/enemy_bullet.tscn")

func _ready() -> void:
	sprite.play('left')  #方向朝向玩家来的方向

func _physics_process(delta: float) -> void:
	#region 检测到玩家，进行旋转处理
	if spy_player:  #检测到玩家存在，处理旋转精灵图像
		# dir: 从炮台指向玩家（炮台要面向玩家）
		var dir = global_position\
			.direction_to(spy_player.global_position)
		var degrees = wrapf(rad_to_deg(dir.angle()), 0, 360)  # 0=右,90=上,180=左,270=下
		if degrees > 22.5 and degrees <= 67.5:  # 右上
			sprite.play('right_down')
			shoot_degress = 45.0 #获取当前的射击角度
		elif degrees > 67.5 and degrees <= 112.5:  # 上
			sprite.play('down')
			shoot_degress = 90.0 #获取当前的射击角度
		elif degrees > 112.5 and degrees <= 157.5:  # 左上
			sprite.play('left_down')
			shoot_degress = 135.0 #获取当前的射击角度
		elif degrees > 157.5 and degrees <= 202.5:  # 左
			sprite.play('left')
			shoot_degress = 180.0 #获取当前的射击角度
		elif degrees > 202.5 and degrees <= 247.5:  # 左下
			sprite.play('left_up')
			shoot_degress = 225.0 #获取当前的射击角度
		elif degrees > 247.5 and degrees <= 292.5:  # 下
			sprite.play('up')
			shoot_degress = 270.0 #获取当前的射击角度
		elif degrees > 292.5 and degrees <= 337.5:  # 右下
			sprite.play('right_up')
			shoot_degress = 325.0 #获取当前的射击角度
		else:  # 包括 <=22.5 和 >337.5 区域：右
			sprite.play('right')
			shoot_degress = 0.0 #获取当前的射击角度
	#endregion

## 发射子弹
## [br]
## - degress: 发射角度
func shoot(degress: float):
	# 角度转弧度
	var angle_radians = deg_to_rad(degress)
	# 使用 cos/sin 得到方向向量
	var dir = Vector2.from_angle(angle_radians)
	var bullet = bullet_resource.instantiate() as EnemyBullet
	var offset = Vector2.ZERO
	bullet.direction = dir
	bullet.global_position = global_position + dir.normalized() * 15.0
	get_tree().current_scene.add_child_to_camera(bullet)

func _on_detector_area_2d_area_entered(area: Area2D) -> void:
	var area_parent = area.get_parent()
	if not area_parent: return
	if area_parent is Player and \
		not spy_player:  #发现玩家
		spy_player = area_parent
		if shoot_timer.paused:
			shoot_timer.paused = false
		shoot_timer.start() #设置射击

func _on_detector_area_2d_area_exited(area: Area2D) -> void:
	var area_parent = area.get_parent()
	if not area_parent: return
	if area_parent is Player and\
		area_parent == spy_player:
		spy_player = null
		shoot_timer.paused = true

func _on_shoot_timer_timeout() -> void:
	if not spy_player: return
	shoot(shoot_degress) #开始射击
