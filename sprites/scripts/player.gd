## 玩家组件
class_name Player extends CharacterBody2D

## 玩家状态
@export
var action: PlayerState.Action = PlayerState.Action.idle

## 玩家移动速度
@export
var speed: float = 60.0

## 玩家是否在跳跃中
var is_jumping: bool = false

## 玩家跳跃计数器
var jump_counter: int = 0

## 玩家射击角度
var shoot_degress: float = 0.0

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
	# 把 velocity 当作像素/秒来管理：水平速度不乘 delta，重力乘 delta
	var gravity: float = 980.0
	if not is_on_floor():
		#有重力加速度
		velocity.y += gravity * delta
	else:
		# 当在地面上时，把垂直速度清零，避免累积
		velocity.y = 0.0
		jump_counter = 0
		is_jumping = false
		sprite.play('idle') #播放跳的动画
	# 处理用户输入
	var is_moving = false #是否正在移动
	var move_dir = Vector2.ZERO #移动方向
	if Input.is_action_pressed('ui_left'):
		is_moving = true
		shoot_degress = 180.0
		move_dir.x = Vector2.LEFT.x
		_play_sprite_run() #播放run的动画
		if sprite: sprite.flip_h = true
	if Input.is_action_pressed('ui_right'):
		is_moving = true
		shoot_degress = 0.0
		move_dir.x = Vector2.RIGHT.x
		_play_sprite_run() #播放run的动画
		if sprite: sprite.flip_h = false
	if Input.is_action_just_pressed('ui_jump'):
		if is_on_floor(): #如果在地面上，可以执行跳跃
			if jump_counter == 0:
				jump_counter = 1 #标记已经跳过一次了
			velocity.y = -300.0
			is_jumping = true #标记正在跳跃
			sprite.play('jump') #播放跳的动画
		else: #此时在天空中，判断是否能够二次跳跃
			if not(jump_counter == 1 and is_jumping):
				return #已经完成第二次跳跃，直接返回
			velocity.y = -260.0
			jump_counter = -1 #标记此时不能再跳了
	velocity.x = speed * move_dir.x
	if move_dir.x == 0.0:
		sprite.play('idle') #如果没有移动，则使用idle动画
	move_and_slide() # 使用 CharacterBody2D 的无参 move_and_slide() 来处理地面接触与滑动
	# 如果需要调试碰撞，可以检查上一次滑动碰撞
	var collider = get_last_slide_collision()
	if collider: #发生了碰撞
		pass # print('玩家与其他实体发生了碰撞💥')
	# 处理子弹发射的相关逻辑
	if Input.is_action_just_pressed('ui_shoot'):
		if not is_moving:
			print('玩家未发生移动，直接发射子弹')
		shoot(shoot_degress) #发射子弹

## 播放玩家run动画
func _play_sprite_run():
	var anim_name = sprite.animation as StringName
	if anim_name.get_basename() != 'run':
		sprite.play('run') #播放run的动画

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
## [br]
## - degress: 发射角度
func shoot(degress: float):
	# 角度转弧度
	var angle_radians = deg_to_rad(degress)
	# 使用 cos/sin 得到方向向量
	var direction = Vector2(cos(angle_radians),\
		sin(angle_radians)).normalized()
	print('玩家发射的方向数据是：', direction)
	print('玩家输入的角度是：', degress, ', ', angle_radians)
	var bullet = bullet_resource.instantiate() as PlayerBullet
	var offset = Vector2.ZERO
	if degress == 0.0:
		offset = Vector2(15.0, 5.0)
	elif degress == 180.0:
		offset = Vector2(-15.0, 5.0)
	bullet.direction = direction
	bullet.global_position = global_position + offset
	get_tree().current_scene.add_child_to_camera(bullet)
