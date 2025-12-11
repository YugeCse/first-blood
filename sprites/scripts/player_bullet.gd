class_name PlayerBullet extends CharacterBody2D

@export
var speed: float = 120.0

@export
var direction: Vector2 = Vector2.RIGHT

@export
var is_strong_fire: bool = false

@onready
var sprite = $AnimatedSprite2D

@onready
var collision_shape = $CollisionShape2D

func _ready() -> void:
	if is_strong_fire:
		sprite.play("level2")
	else: sprite.play("default")
	sprite.animation_finished.connect(queue_free)

func _physics_process(delta: float) -> void:
	velocity = direction * speed * delta
	var collider = move_and_collide(velocity)
	if not collider: return #未发生碰撞
	print('发生了碰撞💥')
