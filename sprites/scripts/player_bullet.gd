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
	sprite.rotate(direction.angle())
	sprite.animation_finished.connect(queue_free)

func _physics_process(delta: float) -> void:
	velocity = direction * speed * delta
	var collider = move_and_collide(velocity)
	if not collider: return #未发生碰撞
	collision_shape.disabled = true
	collider = collider.get_collider()
	if collider is Turret:
		collider.destroy()
	elif collider is Enemy:
		if is_strong_fire:
			collider.hurt(randf_range(20.0, 60.0))
		else: collider.hurt(randf_range(10.0, 40.0))
	queue_free() #发生碰撞，需要删除
	print('玩家子弹与其他发生了碰撞💥')
