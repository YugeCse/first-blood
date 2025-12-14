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
@export_range(10, 1000)
var patrol_speed: float = 10.0

## 巡逻路径
@export
var patrol_path: Path2D

## 路径跟随
@export
var patrol_path_follow: PathFollow2D

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
	shoot_timer.paused = true
	_draw_life_blood_in_edit_mode()

func _enter_tree() -> void:
	_draw_life_blood_in_edit_mode()

func _physics_process(delta: float) -> void:
	_detect_position_clamp() #检测坐标越界处理
	_draw_life_blood_in_edit_mode()
	if Engine.is_editor_hint(): return #编辑模式下不处理逻辑
	if action == EnemyState.Action.idle:
		if (sprite.animation as StringName)\
			.get_basename() != 'idle':
			sprite.play('idle')
		if not spy_player:
			action = EnemyState.Action.patrol
	if action == EnemyState.Action.patrol: #巡逻
		patrol(delta) #执行巡逻
	elif action == EnemyState.Action.chase and spy_player: #追击玩家
		chase() #执行追击

## 执行巡逻， 沿着一定的区域范围进行行走
func patrol(delta: float):
	if not patrol_path or\
		not patrol_path_follow:
		sprite.play('idle')
		sprite.flip_h = true if direction.x < 0 else false
		return #没有设置巡逻路径，直接返回
	sprite.play('run') #执行动画
	if is_on_floor(): #如果是在地板上，就不受重力作用
		velocity.y = 0.0
	else: velocity.y += 980.0 * delta
	var patrol_progress = patrol_path_follow.progress_ratio
	#print(name, '执行巡逻中...', patrol_progress)
	patrol_path_follow.progress += patrol_speed * delta
	sprite.flip_h = true if patrol_progress <= 0.5 else false

## 执行追击，这个过程会执行射击
func chase():
	sprite.play('idle')
	_start_shoot_timer() #启动射击定时器
	var dir = global_position - spy_player.global_position
	if dir.x > 0:
		direction.x = 1.0
		sprite.flip_h = true
		print('玩家在他的前方: ', dir.x)
	elif dir.x < 0:
		sprite.flip_h = false
		direction.x = -1.0
		print('玩家在他的后方', dir.x)
	else: print('玩家在他的正侧方', dir.x)

## 执行射击
func shoot():
	# 使用 cos/sin 得到方向向量
	var dir = (spy_player.global_position\
		- global_position).normalized()
	dir.y = 0.0 #清理垂直方向的
	var offset = dir.normalized() * 15.0
	offset.y = 5.0 #调整枪与子弹的垂直坐标数据
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

## 启动射击定时器
func _start_shoot_timer():
	if not shoot_timer: return
	if shoot_timer.paused:
		shoot_timer.paused = false
	if not shoot_timer.is_stopped(): return
	shoot_timer.start() #启动射击定时器

## 停止射击定时器
func _stop_shoot_timer():
	if not shoot_timer: return
	if not shoot_timer.paused:
		shoot_timer.paused = true
	if not shoot_timer.is_stopped():
		shoot_timer.stop()

func _on_detector_area_2d_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is Player:
		spy_player = parent as Player
		action = EnemyState.Action.chase
		_stop_shoot_timer() #停止射击定时器
		print('玩家进入敌人({name})监视范围'.format({'name': name}))

func _on_detector_area_2d_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is Player and parent == spy_player:
		spy_player = null
		if shoot_timer and not shoot_timer.paused:
			shoot_timer.paused = true
			shoot_timer.stop()
		action = EnemyState.Action.idle
		print('玩家离开敌人({name})监视范围'.format({'name': name}))

func _on_shoot_timer_timeout() -> void:
	if shoot_timer:
		shoot_timer.wait_time = randf_range(1.0, 1.5)
	shoot() #发射子弹
