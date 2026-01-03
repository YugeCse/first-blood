## 红隼士兵
class_name GruntSoilder extends CharacterBody2D

@export
var action: EnemyState.Action = EnemyState.Action.idle

## 运动速度
@export
var speed: float = 40.0

## 是否正在射击
var _is_shooting: bool = false

## 射击随机时间
var _shoot_rand_time: float = 1.2

## 射击时间计数器
var _shoot_time_counter: float = 0.0

## 是否是爆炸状态
var _is_boom_state: bool = false

## 运动方向
@export
var direction: Vector2 = Vector2.LEFT

## 面向方向
var facing: int = -1

## 运动范围对象
@export
var run_area: Vector2

## 随机数对象
var _rng: RandomNumberGenerator

## 士兵精灵对象
@onready
var sprite: AnimatedSprite2D = $AnimatedSprite2D

## 身体范围对象
@onready
var body_area: Area2D = $BodyArea2D

## 身体范围矩形对象
@onready
var body_area_shape: CollisionShape2D = $BodyArea2D/CollisionShape2D

## 子弹资源打包对象
@onready
var bullet_packed_scene: PackedScene = preload('res://sprites/tscns/enemy_bullet.tscn')

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	sprite.play(&'run')
	action = EnemyState.Action.chase
	facing = -1 if direction == Vector2.LEFT else 1
	_shoot_rand_time = _rng.randf_range(1.2, 5.0)
	
func _physics_process(delta: float) -> void:
	if run_area: #如果运动范围设置了
		var rt = get_object_rect()
		if global_position.x < - rt.size.x or\
			global_position.y < - rt.size.y or\
			global_position.x >= run_area.x + rt.size.x or\
			global_position.y >= run_area.y + rt.size.y:
			action = EnemyState.Action.dead
	if action == EnemyState.Action.dead:
		#如果已经是dead状态，则直接从节点删除
		queue_free()
		return
	if _is_boom_state: return #如果是爆炸状态，则返回
	_shoot_time_counter += delta
	if not is_on_floor():
		velocity.y += 9.8
	else: #如果已经处于地面上了
		if _is_shooting: return #如果正在射击，直接发射
		if _shoot_time_counter >= _shoot_rand_time:
			_shoot() #射击事件
			return
	sprite.play(&'run') #播放run效果
	if action == EnemyState.Action.chase:
		velocity.x = direction.x * speed
	if direction != Vector2.ZERO: #如果向量方向不是0
		facing = -1 if direction == Vector2.LEFT else 1
		sprite.flip_h = facing == -1
	move_and_slide() #执行移动逻辑

## 射击事件
func _shoot() -> void:
	_is_shooting = true
	_shoot_time_counter = 0.0
	sprite.play(&'shoot')
	var bullet = bullet_packed_scene.instantiate() as EnemyBullet
	bullet.owner_type = EnemyBullet.OwnerType.grunt
	bullet.direction = Vector2.LEFT if facing == -1 else Vector2.RIGHT
	bullet.global_position = global_position + Vector2(facing * 15.0, 3.0)
	get_viewport().add_child(bullet)
	_shoot_rand_time = _rng.randf_range(1.2, 5.0)
	sprite.animation_finished.connect(func(): _is_shooting = false)

## 爆炸
func boom() -> void:
	if action == EnemyState.Action.dead: return
	_is_boom_state = true #标记为爆炸状态
	body_area.set_deferred(&'monitoring', false)
	body_area.set_deferred(&'monitorable', false)
	body_area_shape.set_deferred(&'disabled', true)
	sprite.play(&'boom')
	sprite.animation_finished.connect(func(): action = EnemyState.Action.dead)

## 获取对象的矩形范围
func get_object_rect() -> Rect2:
	var shape = $CollisionShape2D\
		.shape as RectangleShape2D
	return Rect2(Vector2.ZERO, shape.size)
