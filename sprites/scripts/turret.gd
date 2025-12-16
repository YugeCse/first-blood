## 炮台组件
class_name Turret extends StaticBody2D

## 生命血量
@export_range(100, 500)
var life_blood: float = 300

## 生命最大血量
@export_range(100, 500)
var life_boold_max: float = 300

## 监视范围
@export_range(100, 1000)
var spy_radius: float = 100.0

## 被检测的玩家
var spy_player: Player

## 炮台射击的角度
var shoot_degress: float = 180.0

## 是否损坏
var is_destory: bool = false

@onready
var shoot_timer = $ShootTimer

@onready
var sprite = $Sprite2D

@onready
var collision_shape = $CollisionShape2D

@onready
var detector_area: Area2D = $DetectorArea2D

## 子弹资源
@onready
var bullet_resource = preload("res://sprites/tscns/enemy_bullet.tscn")

func _ready() -> void:
	if life_boold_max < life_blood:
		life_boold_max = life_blood
	_update_spy_area() #更新监视范围
	sprite.play('left')  #方向朝向玩家来的方向

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or\
		is_destory: return
	_update_spy_area() #更新监视范围
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
	var offset = dir.normalized() * 15.0
	var bullet = bullet_resource.instantiate() as EnemyBullet
	bullet.direction = dir
	bullet.global_position = global_position + offset
	get_tree().current_scene.add_child_to_camera(bullet)

## 被打击
## [br]
## - crack: 收到的伤害
func hurt(crack: float):
	var diff = life_blood - crack
	if diff <= 0.0:
		life_blood = 0.0
	if life_blood <= 0.0:
		destroy() #敌人被毁坏
	else:
		life_blood = diff #更新血量
	print('血量：{value}'.format({'value': life_blood}))

## 被损坏
func destroy():
	is_destory = true
	collision_shape.disabled = true
	shoot_timer.stop()
	sprite.play('dead')
	print('炮台(', name , ')被损坏')

## 更新监视范围
func _update_spy_area():
	var spy_shape: CircleShape2D
	var origin_shape = \
		null if detector_area.get_child_count() <= 0\
		else detector_area.get_child(0)
	if origin_shape and\
		origin_shape is CircleShape2D:
		spy_shape = origin_shape as CircleShape2D
		if spy_shape.radius == spy_radius: return
	detector_area.remove_child(origin_shape)
	spy_shape = CircleShape2D.new()
	var detector_shape = CollisionShape2D.new()
	spy_shape.radius = spy_radius
	detector_shape.shape = spy_shape
	detector_area.add_child(detector_shape)

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
	if not spy_player or\
		collision_shape.disabled: return
	shoot(shoot_degress) #开始射击
