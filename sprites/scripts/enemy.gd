## 敌人组件
@tool
class_name Enemy extends CharacterBody2D

## 当前行为
@export
var action = EnemyState.Action.idle

## 移动方向
var direction: Vector2 = Vector2.ZERO

## 血量
@export_range(0, 1000)
var life_blood: float = 200.0

## 最大血量
@export_range(0, 1000)
var life_blood_max: float = 200.0

## 巡逻速度
@export_range(100, 1000)
var potral_speed: float = 500.0

## 上次的巡逻点
var last_potral_posi: Vector2

## 巡逻距离
@export_range(0, 1000)
var potral_distance: float = 50.0

## 巡逻距离长度
var potral_dist_len: float = 0.0

## 是否巡逻到目的点
var is_potral_target: bool = false

## 被监视的玩家
var spy_player: Player

## 射击定时器
@export
var shoot_timer: Timer

@export
var sprite: AnimatedSprite2D

@export
var collision_shape: CollisionShape2D

## 子弹资源
@onready
var bullet_resource = preload("res://sprites/tscns/enemy_bullet.tscn")

func _ready() -> void:
	if life_blood_max < life_blood:
		life_blood_max = life_blood
	if life_blood_max < 0.0:
		life_blood_max = 100.0
	sprite.play("idle") #显示静止状态
	sprite.flip_h = true #朝玩家方向
	_draw_life_blood_in_edit_mode()

func _enter_tree() -> void:
	_draw_life_blood_in_edit_mode()

func _physics_process(delta: float) -> void:
	_detect_position_clamp() #检测坐标越界处理
	_draw_life_blood_in_edit_mode()
	if Engine.is_editor_hint(): return #编辑模式下不处理逻辑
	if action == EnemyState.Action.idle and not spy_player:
		action = EnemyState.Action.potral
	if action == EnemyState.Action.potral: #巡逻
		potral(delta) #执行巡逻
	elif action == EnemyState.Action.chase and spy_player: #追击玩家
		chase() #执行追击

## 执行巡逻， 沿着一定的区域范围进行行走
func potral(delta: float):
	sprite.play('run') #执行动画
	if is_on_floor():
		velocity.y = 0.0
	else: velocity.y += 980.0 * delta
	if not last_potral_posi:
		last_potral_posi = global_position
	else:
		var distance = global_position - last_potral_posi
		if not distance or\
			distance.x == null or\
			potral_distance == null: 
			return #不满足条件，直接返回
		if abs(distance.x) >= potral_distance:
			last_potral_posi = global_position
			is_potral_target = true
			direction.x = -direction.x
			sprite.flip_h = true if direction.x < 0 else false
	if is_potral_target:
		potral_dist_len = 0.0
		velocity.x = potral_speed * delta * direction.x
		is_potral_target = false #执行完操作，需要还原
	else:
		if direction == Vector2.ZERO:
			direction = Vector2.LEFT
		velocity.x = potral_speed * delta * direction.x
	move_and_slide() #进行移动操作

## 执行追击，这个过程会执行射击
func chase():
	sprite.play('idle')
	if shoot_timer:
		if shoot_timer.paused:
			shoot_timer.paused = false
		if not shoot_timer.is_processing():
			shoot_timer.start(1.0)
	var dir = global_position - spy_player.global_position
	if dir.x > 0:
		if direction.x > 0:
			direction.x = -1.0
			sprite.flip_h = true
		print('玩家在他的前方: ', dir.x)
	elif dir.x < 0:
		print('玩家在他的后方', dir.x)
	else: print('玩家在他的正侧方', dir.x)

## 执行射击
func shoot():
	# 使用 cos/sin 得到方向向量
	var dir = (spy_player.global_position\
		- global_position).normalized()
	dir.y = 0.0 #清理垂直方向的
	var offset = dir.normalized() * 15.0
	var bullet = bullet_resource.instantiate() as EnemyBullet
	bullet.direction = dir
	bullet.global_position = global_position + offset
	get_tree().current_scene.add_child_to_camera(bullet)
	
## 受到伤害
## [br]
## - crack: 受到的伤害点数
func hurt(crack: float):
	var diff = life_blood - crack
	if diff <= 0.0:
		life_blood = 0.0
	if life_blood <= 0.0:
		destory() #敌人被毁坏
	else:
		life_blood = diff #更新血量
		queue_redraw()
	print('血量：{value}'.format({'value': life_blood}))

## 敌人被毁坏
func destory():
	action = EnemyState.Action.dead
	collision_shape.disabled = true
	sprite.play('dead')
	sprite.animation_finished.connect(queue_free)

## 获取碰撞区域矩形大小(相对于全局坐标而言)
func _get_collision_rect()->Rect2:
	var shape = \
		collision_shape.shape as RectangleShape2D
	return Rect2(global_position, shape.size)

## 检测坐标越界处理
func _detect_position_clamp():
	var shape_size = _get_collision_rect().size
	var min_x = -shape_size.x / 2.0
	var max_x = GlobalConfigs.DESIGN_MAP_WIDTH + shape_size.x / 2.0
	var max_y = GlobalConfigs.DESIGN_MAP_HEIGHT + shape_size.y / 2.0
	if global_position.x < min_x or\
		global_position.x > max_x or\
		global_position.y > max_y:
		queue_free() #丛节点中删除这个敌人

## 绘制血条图形
func _draw() -> void:
	var life_percent = life_blood / life_blood_max
	if life_percent <= 0.2 or\
		action == EnemyState.Action.dead:
		return #如果已经死亡，不再绘制血条
	var size = _get_collision_rect().size
	var blood_width = 15.0
	var draw_position = Vector2(-7.5, -size.y/2.0)
	draw_rect(Rect2(draw_position, Vector2(blood_width *  life_percent, 2.0)), Color.RED)
	draw_rect(Rect2(draw_position, Vector2(blood_width, 2.0)), Color.WEB_GRAY, false, 0.5)

## 在编辑模式中绘制血条请求
func _draw_life_blood_in_edit_mode():
	if Engine.is_editor_hint(): queue_redraw()

func _on_detector_area_2d_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is Player:
		spy_player = parent as Player
		action = EnemyState.Action.chase
		if shoot_timer: #如果发射定时器可用
			if shoot_timer.paused:
				shoot_timer.paused = false
			if not shoot_timer.is_processing():
				shoot_timer.start()
		print('玩家进入敌人({name})监视范围'.format({'name': name}))

func _on_detector_area_2d_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is Player and parent == spy_player:
		spy_player = null
		if shoot_timer and not shoot_timer.paused:
			shoot_timer.paused = true
		action = EnemyState.Action.idle
		print('玩家离开敌人({name})监视范围'.format({'name': name}))

func _on_shoot_timer_timeout() -> void:
	shoot() #发射子弹
