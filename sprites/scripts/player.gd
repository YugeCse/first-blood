## 玩家组件
class_name Player extends CharacterBody2D

## 玩家状态
@export
var action: PlayerState.Action = PlayerState.Action.idle

## 玩家移动速度
var speed: float = 120.0

## 玩家是否在跳跃中
var is_jumping: bool = false

## 玩家跳跃计数器
var jump_counter: int = 0

## 玩家关联的精灵节点
@onready
var sprite = $AnimatedSprite

## 玩家的碰撞形状
@onready
var collision_shape = $CollisionShape

func _ready() -> void:
	set_process_input(true)
	$Camera2D.make_current()

func _physics_process(delta: float) -> void:
	var shape_size = (collision_shape.shape as RectangleShape2D).size
	if position.x < shape_size.x / 2.0:
		position.x = shape_size.x / 2.0
	# 把 velocity 当作像素/秒来管理：水平速度不乘 delta，重力乘 delta
	var gravity: float = 980.0
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# 当在地面上时，把垂直速度清零，避免累积
		velocity.y = 0.0
		jump_counter = 0
		is_jumping = false
		sprite.play('idle') #播放跳的动画
	# 处理用户输入
	var dir = Vector2.ZERO
	if Input.is_action_pressed('ui_left'):
		dir.x = Vector2.LEFT.x
		_play_sprite_run() #播放run的动画
		if sprite: sprite.flip_h = true
	if Input.is_action_pressed('ui_right'):
		dir.x = Vector2.RIGHT.x
		_play_sprite_run() #播放run的动画
		if sprite: sprite.flip_h = false
	if Input.is_action_just_pressed('ui_jump'):
		if is_on_floor():
			if jump_counter == 0:
				jump_counter = 1
			velocity.y = -300.0
			is_jumping = true
			sprite.play('jump') #播放跳的动画
		else:
			if not(jump_counter == 1 and is_jumping):
				return
			velocity.y = -260.0
			jump_counter = -1 #不能再跳了
	velocity.x = speed * dir.x
	if dir.x == 0.0: sprite.play('idle') #如果没有移动，则使用idle动画
	move_and_slide() # 使用 CharacterBody2D 的无参 move_and_slide() 来处理地面接触与滑动
	# 如果需要调试碰撞，可以检查上一次滑动碰撞
	var col = get_last_slide_collision()
	if not col: return #未发生碰撞，直接返回

## 播放玩家run动画
func _play_sprite_run():
	var anim_name = sprite.animation as StringName
	if anim_name.get_basename() != 'run':
		sprite.play('run') #播放run的动画
