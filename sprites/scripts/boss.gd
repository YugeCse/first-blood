class_name Boss extends Node2D

## boss死亡通知事件
signal on_boss_die

## 血量设定对象
@export_range(10.0, 10000.0)
var life_blood: float = 800.0

## 角色最大血量设定
@export_range(10.0, 10000.0)
var life_blood_max: float = 800.0

## 是否已经死亡，默认：false
var _is_die: bool = false

## 被监视的玩家
var spy_player: Player

## 行为定时器对象
@onready
var action_timer: Timer = $ActionTimer

## 激光定时器
@onready
var laser_timer: Timer = $LaserTimer

## 左手臂标记点位
@onready
var arm_left_marker: Marker2D = $ArmLeftMarker2D

## 右手臂标记点位
@onready
var arm_right_marker: Marker2D = $ArmRightMarker2D2

## 头部的精灵对象
@onready
var head_sprite: AnimatedSprite2D = $HeadArea2D/HeadAnimSprite2D

## 身体的精灵对象
@onready
var body_sprite: AnimatedSprite2D = $BodyAnimSprite2D

## 头部的碰撞形状对象
@onready
var head_collision_shape: CollisionShape2D = $HeadArea2D/CollisionShape2D

## 子弹打包资源
@onready
var bullet_packed_scene: PackedScene = preload('res://sprites/tscns/boss_bullet.tscn')

@onready
var laser_packed_scene: PackedScene = preload('res://sprites/tscns/boss_laser.tscn')

func _ready() -> void:
	visible = false #可见性设置为false
	if life_blood <= 0.0:
		life_blood = 1000.0
	if life_blood_max < life_blood:
		life_blood_max = life_blood
	head_sprite.play(&'idle')
	body_sprite.play(&'static')
	print('左手坐标：{left_position}, 右手坐标:{right_position}'\
		.format({'left_position': arm_left_marker.global_position,\
			'right_position': arm_right_marker.global_position}))
	get_tree().create_timer(0.8).timeout.connect(_start_blink) #启动闪烁效果

## 启动行为定时器
func _start_action_timer() -> void:
	if not action_timer.is_stopped():	
		action_timer.stop()
	action_timer.paused = false
	action_timer.wait_time = randf_range(1.5, 5.0)
	action_timer.start()
	print('Boss已启动行为定时器！')

## 停止行为定时器
func _stop_action_timer() -> void:
	if not action_timer.paused:
		action_timer.paused = false
	if not action_timer.is_stopped():
		action_timer.stop()

## 启动激光定时器
func _start_laser_timer() -> void:
	_stop_laser_timer()
	laser_timer.wait_time = randf_range(3.0, 8.0)
	laser_timer.start()

## 停止激光定时器
func _stop_laser_timer() -> void:
	if not laser_timer.is_stopped():
		laser_timer.paused = true
	laser_timer.stop()

## 发射
func _shoot() -> void:
	if not spy_player or\
		spy_player.action == PlayerState.Action.dead: return
	var dir = (spy_player.global_position\
		- global_position).normalized()
	var bullet = bullet_packed_scene.instantiate()
	bullet.direction = dir
	bullet.position =\
		head_sprite.global_position + Vector2(1.5, 20.0)
	get_viewport().add_child(bullet)

## 发射激光
func _shoot_laser() -> void:
	var left_laser = laser_packed_scene.instantiate() as BossLaser
	left_laser.debug_mode = false
	left_laser.direction = Vector2.DOWN
	left_laser.global_position = arm_left_marker.global_position
	var right_laser = laser_packed_scene.instantiate() as BossLaser
	right_laser.debug_mode = false
	right_laser.direction = Vector2.DOWN
	right_laser.global_position = arm_right_marker.global_position
	get_viewport().add_child(left_laser)
	get_viewport().add_child(right_laser)

## 受到伤害
func hurt(crack: float) -> void:
	life_blood = clampf(\
		life_blood - crack, 0.0, life_blood_max)
	if life_blood <= 0 and not _is_die:
		_is_die = true
		_stop_laser_timer()
		_stop_action_timer()
		on_boss_die.emit()
		_destroy() #boss被消灭
		print('boss被打败了！')

## 被消灭
func _destroy() -> void:
	var tween = get_tree().create_tween()
	tween.set_loops(3)
	tween.tween_property(head_sprite, 'modulate:a', 0.2, 0.5)
	tween.tween_property(head_sprite, 'modulate:a', 1.0, 0.5)
	tween.play()
	tween.finished.connect(queue_free)

## 启动闪烁效果
func _start_blink() -> void:
	if not visible: visible = true
	print('Boss启动闪烁效果!')
	var tween = get_tree().create_tween()
	tween.set_loops(6)
	tween.tween_property(self, 'modulate:a', 0.2, 0.5)
	tween.tween_property(self, 'modulate:a', 1.0, 0.5)
	tween.play()
	tween.finished.connect(_start_shoot_timer)

## 启动子弹发射定时器
func _start_shoot_timer() -> void:
	_start_laser_timer()
	_start_action_timer()

## 行为定时器的逻辑
func _on_action_timer_timeout() -> void:
	head_sprite.play(&'anim')
	body_sprite.play(&'idle')
	_shoot() #发射子弹
	head_sprite.animation_finished.connect(\
		func(): head_sprite.play(&'idle'); body_sprite.play(&'static'))
	_start_action_timer()

func _on_laser_timer_timeout() -> void:
	_shoot_laser()
	
