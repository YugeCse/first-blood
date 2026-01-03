class_name Boss extends Node2D

## boss死亡通知事件
signal on_boss_die

## 血量设定对象
@export_range(10.0, 10000.0)
var life_blood: float = 800.0

@export_range(10.0, 10000.0)
var life_blood_max: float = 800.0

## 是否已经死亡，默认：false
var _is_die: bool = false

## 被监视的玩家
var spy_player: Player

## 行为定时器对象
@onready
var action_timer: Timer = $ActionTimer

## 左手臂标记点位
@onready
var arm_left_marker: Marker2D = $BodyAnimSprite2D/ArmLeftMarker2D

## 右手臂标记点位
@onready
var arm_right_marker: Marker2D = $BodyAnimSprite2D/ArmRightMarker2D2

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

func _ready() -> void:
	visible = false #可见性设置为false
	if life_blood <= 0.0:
		life_blood = 1000.0
	if life_blood_max < life_blood:
		life_blood_max = life_blood
	head_sprite.play(&'idle')
	body_sprite.play(&'static')
	get_tree().create_timer(0.8).timeout.connect(_start_blink) #启动闪烁效果

## 启动行为定时器
func _start_action_timer() -> void:
	if action_timer.is_stopped():
		action_timer.paused = false
		action_timer.start()
	print('Boss已启动行为定时器！')

## 停止行为定时器
func _stop_action_timer() -> void:
	if not action_timer.paused:
		action_timer.paused = false
	if not action_timer.is_stopped():
		action_timer.stop()

## 发射
func _shoot() -> void:
	if not spy_player: return
	var dir = (spy_player.global_position\
		- global_position).normalized()
	var bullet = bullet_packed_scene.instantiate()
	bullet.direction = dir
	bullet.position =\
		head_sprite.global_position + Vector2(1.5, 20.0)
	get_viewport().add_child(bullet)

## 受到伤害
func hurt(crack: float) -> void:
	life_blood = clampf(\
		life_blood - crack, 0.0, life_blood_max)
	if life_blood <= 0 and not _is_die:
		_is_die = true
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
	tween.finished.connect(func(): head_sprite.queue_free())

## 启动闪烁效果
func _start_blink() -> void:
	if not visible: visible = true
	print('Boss启动闪烁效果!')
	var tween = get_tree().create_tween()
	tween.set_loops(6)
	tween.tween_property(self, 'modulate:a', 0.2, 0.5)
	tween.tween_property(self, 'modulate:a', 1.0, 0.5)
	tween.play()
	tween.finished.connect(_start_action_timer)

## 行为定时器的逻辑
func _on_action_timer_timeout() -> void:
	head_sprite.play(&'anim')
	body_sprite.play(&'idle')
	_shoot() #发射子弹
	head_sprite.animation_finished.connect(\
		func(): head_sprite.play(&'idle'); body_sprite.play(&'static'))
	action_timer.paused = true
	action_timer.stop()
	action_timer.wait_time = randf_range(1.5, 3.0)
	action_timer.paused = false
	action_timer.start()

## 发射子弹的定时器对象
func _on_shoot_timer_timeout() -> void:
	pass
	#_shoot()
	#if not shoot_timer.is_stopped():
		#shoot_timer.paused = true
		#shoot_timer.stop()
	#shoot_timer.wait_time = randf_range(2.0, 3.0)
	#shoot_timer.paused = false
	#shoot_timer.start()
