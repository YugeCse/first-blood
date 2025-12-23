## 玩家组件
class_name Player extends CharacterBody2D

## 玩家状态
@export
var action: PlayerState.Action = PlayerState.Action.idle

## 开枪射击的时间限制
@export_range(0.02, 1.0)
var shoot_time_limit: float = 0.3

## 血量
@export_range(100, 10000)
var life_blood: float = 200.0

## 最大血量
@export_range(100, 10000)
var life_blood_max: float = 200.0

## 玩家移动速度
@export_range(30, 300)
var speed: float = 46.0

## 重力加速度
@export_range(1.0, 1000)
var gravity_speed: float = 500.0

## 玩家是否在跳跃中
var is_jumping: bool = false

## 玩家跳跃计数器
var jump_counter: int = 0

## 第一跳跃高度
@export_range(10, 1000)
var jump_height: float = 200.0

## 第二跳跃高度
@export_range(10, 1000)
var jump_secondary_height: float = 180.0

## 朝向, 1-向右；-1-向右
var facing: int = 1

## 移动方向
var move_dir: Vector2 = Vector2.ZERO

## 是否是趴下
var _is_move_down: bool = false

## 玩家射击角度
var shoot_degress: float = 0.0

## 上一次的射击时间
var _last_shoot_time: float = 0.0

## 是否变成了灵魂
var _is_changed_soul: bool = false

## 变成了灵魂的时间点
var _changed_soul_time: float = 0.0

## 玩家关联的精灵节点
@onready
var sprite: AnimatedSprite2D = $AnimatedSprite

## 玩家的碰撞形状
@onready
var collision_shape: CollisionShape2D = $CollisionShape

## 子弹资源
@onready
var bullet_resource = preload("res://sprites/tscns/player_bullet.tscn")

func _ready() -> void:
	set_process_input(true)
	$FollowCamera2D.make_current() #设置相机跟随

func _physics_process(delta: float) -> void:
	_handle_control_move(delta) #处理控制移动

## 处理控制移动
func _handle_control_move(_delta: float):
	#region 变成了灵魂
	if _is_changed_soul: #如果变成了灵魂
		if _changed_soul_time > 0.15:
			velocity = Vector2.ZERO
			return
		velocity.x = 0.0
		velocity.y -= gravity_speed * _delta
		move_and_slide()
		_changed_soul_time += _delta
		return
	#endregion
	_set_position_clamp() #设置坐标限制
	#region 控制重力逻辑
	# 把 velocity 当作像素/秒来管理：水平速度不乘 delta，重力乘 delta
	if is_on_floor(): #当在地面上时，把垂直速度清零，避免累积
		velocity.y = 0.0
		jump_counter = 0
		is_jumping = false
	else:
		velocity.y += gravity_speed * _delta #有重力加速度
	#endregion
	# 当玩家角色已经死亡，则直接返回，不能继续下面的操作
	if action == PlayerState.Action.dead:
		velocity.x = 0.0 #没有水平速度
		move_and_slide() #要执行落地的操作
		return
	#region 处理用户输入
	var is_moving = false #是否正在移动
	move_dir = Input.get_vector(\
		&'ui_left', &'ui_right', &'ui_up', &'ui_down')
	if move_dir != Vector2.ZERO:
		if move_dir.x != 0:
			facing = sign(move_dir.x)
	#玩家面向的角度
	var facing_degress = \
		roundi(wrapf(rad_to_deg(move_dir.angle()), 0, 360))
	is_moving = move_dir.x != 0.0 #被按下时表示正在移动
	var is_get_down = move_dir == Vector2.DOWN
	#处理跳跃逻辑
	if (facing_degress in [0, 180] or is_get_down) and\
		Input.is_action_just_pressed(&'ui_jump'):
		if is_on_floor(): #如果在地面上，可以执行跳跃
			if not is_get_down: #如果不是趴下状态
				if jump_counter == 0:
					jump_counter = 1 #标记已经跳过一次了
				velocity.y = -jump_height
				is_jumping = true #标记正在跳跃
				sprite.play(&'jump') #播放跳的动画
			else: #禁用当前的碰撞行形状
				collision_shape.set_deferred(&'disabled', true)
				get_tree().create_timer(0.1)\
					.timeout.connect(func():\
					collision_shape.set_deferred(&'disabled', false))
		else: #此时在天空中，判断是否能够二次跳跃
			if is_get_down: 
				return #已经是趴下状态，不能在空中跳了
			if not(jump_counter == 1 and is_jumping):
				return #已经完成第二次跳跃，直接返回
			velocity.y = -jump_secondary_height
			jump_counter = -1 #标记此时不能再跳了
			sprite.play(&'jump') #播放跳的动画
	_update_body_area_shape(is_get_down) #更新碰撞区域
	#region 处理子弹发射的相关逻辑
	var allow_shoot = \
		Time.get_unix_time_from_system() -\
		 _last_shoot_time > shoot_time_limit
	var is_shoot = allow_shoot and\
		 (facing_degress != 90 or \
			move_dir == Vector2.DOWN) and\
		Input.is_action_just_pressed(&'ui_shoot')
	if not is_shoot: #如果没有射击
		if facing_degress in [225, 315]:
			sprite.play(&'aim_up')
		elif facing_degress in [45, 135]:
			sprite.play(&'aim_down')
		elif facing_degress == 270:
			sprite.play(&'stand_aim_up')
		elif move_dir == Vector2.DOWN:
			sprite.play(&'crouch_aim')
		elif not is_moving:
			sprite.play(&'idle')
		else: sprite.play(&'run')
	else: #如果射击了
		if facing_degress in [225, 315]:
			sprite.play(&'aim_up')
		elif facing_degress in [45, 135]:
			sprite.play(&'aim_down')
		elif facing_degress == 270:
			sprite.play(&'stand_aim_up')
		elif move_dir == Vector2.DOWN:
			sprite.play(&'crouch_aim')
		elif is_moving:
			sprite.play(&'run_shoot')
		else: sprite.play(&'stand_shoot')
	if is_shoot: 
		shoot() #发射子弹
		_last_shoot_time = Time.get_unix_time_from_system()
	#endregion
	velocity.x = move_dir.x * speed
	sprite.flip_h = false if facing == 1 else true
	move_and_slide() #开始进入玩家移动
	#endregion

## 设置坐标限制，超出范围就还原到特定位置
func _set_position_clamp():
	var shape_size = (collision_shape.shape as RectangleShape2D).size
	var min_x = shape_size.x / 2.0
	var max_x = GlobalConfigs.DESIGN_MAP_WIDTH - shape_size.x / 2.0
	var max_y = GlobalConfigs.DESIGN_MAP_HEIGHT + shape_size.y / 2.0
	if global_position.x < min_x:
		global_position.x = min_x
	elif global_position.x >= max_x:
		global_position.x = max_x
	if global_position.y >= max_y:
		#print('玩家已经跳崖了，Go Die!')
		GlobalSignals.on_player_dead.emit(global_position)

## 玩家角色发射子弹
func shoot():
	var target_dir = move_dir if(move_dir != Vector2.ZERO)\
		else Vector2(float(facing), 0)
	var facing_degress = \
		roundi(wrapf(rad_to_deg(target_dir.angle()), 0, 360))
	var bullet = bullet_resource.instantiate() as PlayerBullet
	var dir = ((Vector2.LEFT if facing == -1 else Vector2.RIGHT)\
		if target_dir == Vector2.DOWN\
		else Vector2.from_angle(deg_to_rad(facing_degress)))
	var offset = dir * 18.0
	if target_dir == Vector2.DOWN:
		offset.y += 10.0
	elif facing_degress in [0, 180]:
		offset.y += 4.0
	elif facing_degress == 315:
		offset.x += 5.0
	elif facing_degress in [45, 135]:
		offset += dir * 8.0
	bullet.direction =\
		dir if target_dir == Vector2.DOWN else target_dir
	bullet.global_position = global_position + offset
	get_parent().add_child(bullet) #让他的容器来添加这个控件

## 玩家角色受到伤害
func hurt(crack: float):
	life_blood = clampf(\
		life_blood - crack, 0, life_blood_max)
	if life_blood <= 0.0:
		dead() #玩家角色死亡
		return
	sprite.play(&'hit_hurt') #播放受伤的动画

## 玩家角色死亡
func dead():
	if action != PlayerState.Action.dead:
		action = PlayerState.Action.dead
	else: return #玩家角色已经死亡了
	$BodyArea2D/CollisionShape2D\
		.set_deferred(&'disabled', true)
	$BodyArea2D.set_deferred(&'monitoring', false)
	$BodyArea2D.set_deferred(&'monitorable', false)
	$DetectorArea2D/CollisionShape2D\
		.set_deferred(&'disabled', true)
	$DetectorArea2D.set_deferred(&'monitoring', false)
	$DetectorArea2D.set_deferred(&'monitorable', false)
	sprite.play(&'defeated')
	await sprite.animation_finished	
	sprite.play(&'dead')
	await sprite.animation_finished
	sprite.play(&'dead_soul')
	_is_changed_soul = true #变成了灵魂
	collision_shape.set_deferred(&'disabled', true)
	await sprite.animation_finished
	await get_tree().create_timer(1.2).timeout
	GlobalSignals.on_player_dead.emit(global_position)

## 更新身体与子弹碰撞的矩形形状
func _update_body_area_shape(is_move_down: bool):
	if _is_move_down == is_move_down:\
		return #状态没变，不需要操作
	var body_area_collision_shape =\
		$BodyArea2D/CollisionShape2D
	_is_move_down = is_move_down #更新趴着状态
	var shape = RectangleShape2D.new()
	if not is_move_down: #未趴下的时候，高度不减，无偏移
		shape.size = Vector2(16.0, 20.0)
		body_area_collision_shape.position = Vector2.ZERO
	else:
		shape.size = Vector2(20.0, 8.0)
		body_area_collision_shape.position = Vector2(0, 6.5)
	body_area_collision_shape.shape = shape

## 获取碰撞区域的矩形大小
func _get_collision_shape_rect() -> Rect2:
	var collider_shape = \
		collision_shape.shape as RectangleShape2D
	return Rect2(Vector2.ZERO, collider_shape.size)

## 获得道具
func get_prop(prop_type: Prop.PropType) -> void:
	pass
	
