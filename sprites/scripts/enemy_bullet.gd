class_name EnemyBullet extends CharacterBody2D

## 子弹移动速度
@export
var speed: float = 200.0

## 子弹移动方向
@export
var direction: Vector2 = Vector2.LEFT

## 记录子弹的起始位置
var start_position: Vector2

## 子弹动画图帧元素
@onready
var sprite: AnimatedSprite2D = $AnimatedSprite2D

## 子弹碰撞体
@onready
var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	start_position = global_position
	sprite.rotate(direction.angle())
	sprite.play('default')

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	var collider = move_and_collide(velocity * delta)
	if not collider: 
		return
	print('子弹发生了碰撞')
	_destory() #销毁这个子弹组件

## 销毁这个子弹组件
func _destory():
	collision_shape.disabled = true
	queue_free()
	
func _on_animated_sprite_2d_animation_finished() -> void:
	_destory()
