## 敌人组件
@tool
class_name Grunt extends CharacterBody2D

## 当前行为
@export
var action = EnemyState.Action.idle

## 移动方向
var direction: Vector2 = Vector2.ZERO

## 是否正在射击
var is_shooting: bool = false

## 血量
@export_range(0, 1000)
var life_blood: float = 200.0

## 最大血量
@export_range(0, 1000)
var life_blood_max: float = 200.0

## 是否绘制血条，默认：false
@export
var is_draw_blood: bool = false

## 巡逻速度
@export_range(10, 1000)
var patrol_speed: float = 10.0

## 重力加速度
@export_range(9.8, 1000)
var gravity_speed: float = 98.0

## 是否被激活，默认：false
@export
var is_active: bool = false

## 巡逻路径对西那个
@export
var patrol_path: Path2D

## 路径跟随对象
@export
var patrol_path_follow: PathFollow2D

## 被监视的玩家
var spy_player: Player

## 敌人的图像显示对象
@export
var sprite: AnimatedSprite2D

## 敌人的基础碰撞矩形对象
@export
var collision_shape: CollisionShape2D

## 射击定时器对象
@onready
var shoot_timer: Timer = $ShootTimer

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
	set_active(false) #设置为未激活模式

func _enter_tree() -> void:
	_draw_life_blood_in_edit_mode()

func _physics_process(delta: float) -> void:
	_detect_position_clamp() #检测坐标越界处理
	_draw_life_blood_in_edit_mode()
	if Engine.is_editor_hint(): return #编辑模式下不处理逻辑
	handle_grunt_state(delta) #处理敌人状态

## 处理敌人状态
func handle_grunt_state(delta: float) -> void:
	if is_on_floor(): #如果在地板上，没有纵向速度
		velocity.y = 0.0
	elif action != EnemyState.Action.dead:
		velocity.y += gravity_speed * delta #受重力加速度影响
		move_and_slide() #执行行走逻辑
	match action:
		EnemyState.Action.idle: #休闲状态
			sprite.play(&'idle')
			#如果没有发现敌人且属可巡逻的，修改为巡逻模式
			if not spy_player and patrol_path:
				action = EnemyState.Action.patrol
		EnemyState.Action.patrol: #巡逻状态
			patrol(delta) #执行巡逻
		EnemyState.Action.chase: #追击玩家
			handle_chase_state() #处理追击状态

## 处理敌人的追击状态，需要根据距离判断是否可以真实追击
func handle_chase_state() -> void:
	if spy_player: #如果玩家还在监视范围内，根据距离计算是否要攻击
		var distance = global_position - spy_player.global_position
		#获取垂直距离，如果垂直距离大于自身高度，判断为无效追击状态
		if absf(distance.y) > _get_collision_rect().size.y:
			if patrol_path: #支持巡逻的，才能继续巡逻
				action = EnemyState.Action.patrol
			else: action = EnemyState.Action.idle
		else: chase() #执行追击
	else: #如果监视玩家丢失，则根据情况修改状态
		if patrol_path: #支持巡逻的，才能继续巡逻
			action = EnemyState.Action.patrol
		else: action = EnemyState.Action.idle

## 执行巡逻， 沿着一定的区域范围进行行走
func patrol(delta: float) -> void:
	if not patrol_path or\
		not patrol_path_follow:
		sprite.play(&'idle')
		sprite.flip_h = true if direction.x <= 0 else false
		return #没有设置巡逻路径，直接返回
	if spy_player: #如果玩家还被监视
		var shape_height = _get_collision_rect().size.y
		var dy = absf((global_position - spy_player.global_position).y)
		if dy <= shape_height:
			chase() #巡逻中发现满足条件的要求，要发起追击
			return
	_stop_shoot_timer() #巡逻模式下，不能射击
	sprite.play(&'run') #执行动画
	var patrol_progress = patrol_path_follow.progress_ratio
	#print(name, '执行巡逻中...', patrol_progress)
	patrol_path_follow.progress += patrol_speed * delta
	sprite.flip_h = true if patrol_progress <= 0.5 else false

## 执行追击，这个过程会执行射击
func chase():
	var distance: Vector2 =\
		global_position - spy_player.global_position #获得距离向量
	var dir = distance.normalized() #获得单位向量
	if dir.x >= 0:
		direction.x = 1.0
		sprite.flip_h = true
		#print('玩家在他的前方: ', dir.x)
	elif dir.x < 0:
		sprite.flip_h = false
		direction.x = -1.0
		#print('玩家在他的后方', dir.x)
	#else: print('玩家在他的正侧方', dir.x)
	_start_shoot_timer(randf_range(1.0, 1.5)) #开启射击定时器
	if not is_shooting: #非射击状态，执行idle
		sprite.play(&'idle')
	else: 
		sprite.play(&'shoot') #播放射击动画
		sprite.animation_finished.connect(func(): is_shooting = false)

## 执行射击
func shoot():
	is_shooting = true #标记正在射击
	# 使用 cos/sin 得到方向向量
	var dir = Vector2(-direction.x, 0.0)
	var offset = dir.normalized() * 15.0
	offset.y = 5.0 #调整枪与子弹的垂直坐标数据
	var bullet = bullet_resource.instantiate() as EnemyBullet
	bullet.direction = dir
	bullet.owner_type = EnemyBullet.OwnerType.grunt
	bullet.global_position = global_position + offset
	if not patrol_path:
		get_parent().add_child(bullet) #让他的容器来添加这个控件
	else: patrol_path.get_parent().add_child(bullet) #让他的容器来添加这个控件
	
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
	collision_shape.set_deferred(&'disabled', true)
	sprite.play('dead')
	sprite.animation_finished.connect(_remove_from_tree)

## 从树节点中删除自己
func _remove_from_tree():
	var location = global_position\
		- Vector2(0, _get_collision_rect().size.y)
	var parent: Node
	if patrol_path:
		parent = patrol_path.get_parent()
		patrol_path.queue_free()
	else:
		parent = get_parent()
		queue_free()
	var prop = DropPropManager\
		.rand_drop_prop(randf_range(10.0, 15.0))
	if not prop: return
	prop.global_position = location
	parent.add_child(prop) #把道具添加到界面中

## 获取碰撞区域矩形大小(相对于全局坐标而言)
func _get_collision_rect()->Rect2:
	var shape = \
		collision_shape.shape as RectangleShape2D
	return Rect2(Vector2.ZERO, shape.size)

## 检测坐标越界处理
func _detect_position_clamp():
	var shape_size = _get_collision_rect().size
	var min_x = -shape_size.x / 2.0
	var max_x = GlobalConfigs.DESIGN_MAP_WIDTH + shape_size.x / 2.0
	var max_y = GlobalConfigs.DESIGN_MAP_HEIGHT + shape_size.y / 2.0
	if global_position.x < min_x or\
		global_position.x > max_x or\
		global_position.y > max_y:
		collision_shape.disabled = true
		action = EnemyState.Action.dead
		queue_free() #丛节点中删除这个敌人

## 绘制血条图形
func _draw() -> void:
	if not is_draw_blood: return #不绘制血条
	var life_percent = life_blood / life_blood_max
	if life_percent <= 0.2 or\
		action == EnemyState.Action.dead:
		return #如果已经死亡，不再绘制血条
	var size = _get_collision_rect().size
	var blood_width = 15.0
	var draw_position = Vector2(-7.5, -size.y/2.0)
	draw_rect(Rect2(draw_position, Vector2(blood_width, 2.0)), Color.WEB_GRAY)
	draw_rect(Rect2(draw_position, Vector2(blood_width *  life_percent, 2.0)), Color.RED)
	draw_rect(Rect2(draw_position, Vector2(blood_width, 2.0)), Color.WEB_GRAY, false, 0.5)

## 在编辑模式中绘制血条请求
func _draw_life_blood_in_edit_mode():
	if not is_draw_blood: return
	if Engine.is_editor_hint(): queue_redraw()

## 启动射击定时器
func _start_shoot_timer(shoot_wait_time: float = 1.0):
	if not shoot_timer: return
	if shoot_timer.paused:
		shoot_timer.paused = false
	if not shoot_timer.is_stopped(): return
	shoot_timer.wait_time = shoot_wait_time
	shoot_timer.start() #启动射击定时器

## 随机不定时射击
func _start_shoot_timer_random() -> void:
	if not shoot_timer: return
	#如果发射子弹的定时器存在
	if shoot_timer.paused:
		shoot_timer.paused = true
	shoot_timer.stop()
	shoot_timer.wait_time = randf_range(1.0, 1.5) #生成一个随机时间
	shoot_timer.paused = false
	shoot_timer.start()

## 停止射击定时器
func _stop_shoot_timer():
	if not shoot_timer: return
	if not shoot_timer.paused:
		shoot_timer.paused = true
	if not shoot_timer.is_stopped():
		shoot_timer.stop()

## 设置是否激活
func set_active(value: bool):
	if is_active == value: return
	if not value:
		_stop_shoot_timer()
		if sprite.is_playing(): 
			sprite.stop()
	self.is_active = value
	set_process(value)
	set_physics_process(value)

func _on_detector_area_2d_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is Player: #玩家进入敌人监视范围
		spy_player = parent as Player
		action = EnemyState.Action.chase
		#_start_shoot_timer_random() #启动射击定时器
		print('玩家进入敌人({name})监视范围'.format({'name': name}))

func _on_detector_area_2d_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is Player:
		if parent == spy_player:
			spy_player = null
		_stop_shoot_timer() #停止射击定时器
		action = EnemyState.Action.idle
		print('玩家离开敌人({name})监视范围'.format({'name': name}))

func _on_shoot_timer_timeout() -> void:
	if action == EnemyState.Action.dead:
		if shoot_timer:
			shoot_timer.stop()
		return
	if shoot_timer:
		if not shoot_timer.paused:
			shoot_timer.stop()
	shoot() #发射子弹
	_start_shoot_timer_random() #随机不定时射击
