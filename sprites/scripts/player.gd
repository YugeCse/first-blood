## 玩家组件
class_name Player extends CharacterBody2D

## 玩家状态
@export
var action: PlayerState.Action = PlayerState.Action.idle

## 玩家移动速度
@export_range(30, 300)
var speed: float = 46.0

## 玩家是否在跳跃中
var is_jumping: bool = false

## 玩家跳跃计数器
var jump_counter: int = 0

## 玩家射击角度
var shoot_degress: float = 0.0

## 朝向, 1-向右；-1-向右
var facing: int = 1

## 移动方向
var move_dir: Vector2 = Vector2.ZERO

## 玩家关联的精灵节点
@onready
var sprite = $AnimatedSprite

## 玩家的碰撞形状
@onready
var collision_shape = $CollisionShape

## 子弹资源
@onready
var bullet_resource = preload("res://sprites/tscns/player_bullet.tscn")

func _ready() -> void:
	set_process_input(true)
	$FollowCamera2D.make_current() #设置相机跟随

func _physics_process(delta: float) -> void:
	_set_position_clamp() #设置坐标限制
	_handle_control_move(delta) #处理控制移动

## 处理控制移动
func _handle_control_move(delta: float):
	#region 控制重力逻辑
	# 把 velocity 当作像素/秒来管理：水平速度不乘 delta，重力乘 delta
	var gravity: float = 9.8
	if not is_on_floor():
		#有重力加速度
		velocity.y += gravity
	else:
		# 当在地面上时，把垂直速度清零，避免累积
		velocity.y = 0.0
		jump_counter = 0
		is_jumping = false
	#endregion
	#region 处理用户输入
	var is_moving = false #是否正在移动
	move_dir = Vector2(
		Input.get_action_strength(&'ui_right') -\
		Input.get_action_strength(&'ui_left'),
		Input.get_action_strength(&'ui_down') -\
		Input.get_action_strength(&'ui_up'))
	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
		if move_dir.x != 0:
			facing = sign(move_dir.x)
	is_moving = move_dir.x != 0 #被按下时表示正在移动
	#处理跳跃逻辑
	if Input.is_action_just_pressed(&'ui_jump'):
		if is_on_floor(): #如果在地面上，可以执行跳跃
			if jump_counter == 0:
				jump_counter = 1 #标记已经跳过一次了
			velocity.y = -250.0
			is_jumping = true #标记正在跳跃
		else: #此时在天空中，判断是否能够二次跳跃
			if not(jump_counter == 1 and is_jumping):
				return #已经完成第二次跳跃，直接返回
			velocity.y = -200.0
			jump_counter = -1 #标记此时不能再跳了
	#region 处理子弹发射的相关逻辑
	var is_shoot: bool = false
	if Input.is_action_just_pressed(&'ui_shoot'):
		is_shoot = true
		shoot() #发射子弹
	if is_jumping: #如果正在跳跃
		sprite.play(&'jump') #播放跳的动画
	elif not is_shoot: #如果没有射击
		if not is_moving:
			sprite.play(&'idle')
		else: sprite.play(&'run')
	else:
		if is_moving:
			sprite.play(&'run_shoot')
		else: sprite.play(&'stand_shoot')
	#endregion
	velocity.x = move_dir.x * speed
	sprite.flip_h = false if facing == 1 else true
	move_and_slide() #开始进入玩家移动
	# 如果需要调试碰撞，可以检查上一次滑动碰撞
	var collider = get_last_slide_collision()
	if collider: #发生了碰撞
		pass # print('玩家与其他实体发生了碰撞💥')
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
		print('玩家已经跳崖了，Go Die!')

## 发射子弹
func shoot():
	var degress = 0.0 if facing == 1 else 180.0
	var angle_radians = deg_to_rad(degress)
	# 使用 cos/sin 得到方向向量
	var dir = Vector2(cos(angle_radians),\
		sin(angle_radians)).normalized()
	var bullet = bullet_resource.instantiate() as PlayerBullet
	var offset = Vector2.ZERO
	if degress == 0.0:
		offset = Vector2(15.0, 5.0)
	elif degress == 180.0:
		offset = Vector2(-15.0, 5.0)
	bullet.direction = dir
	bullet.global_position = global_position + offset
	get_tree().current_scene.add_child_to_camera(bullet)
