class_name EnemyBullet extends CharacterBody2D

@export
var speed: float = 120.0

@export
var direction: Vector2 = Vector2.LEFT

@onready
var sprite = $AnimatedSprite2D

@onready
var collision_shape = $CollisionShape2D

func _ready() -> void:
	sprite.rotate(direction.angle())
	sprite.play('default')
	sprite.animation_finished.connect(queue_free)

func _physics_process(delta: float) -> void:
	velocity = direction * speed * delta
	var collider = move_and_collide(velocity)
	if not collider: return #未发生碰撞
	collision_shape.disabled = true
	queue_free() #发生碰撞，需要删除
	print('敌方子弹与其他发生了碰撞💥')
