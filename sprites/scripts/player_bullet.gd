class_name PlayerBullet extends CharacterBody2D

@export
var speed: float = 200.0

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
	var fire_crack = 10.0
	if is_strong_fire:
		fire_crack = randf_range(20.0, 60.0)
	else: fire_crack = randf_range(10.0, 40.0)
	if collider is Turret: #如果是炮台
		collider.hurt(fire_crack)
	elif collider is Enemy: #如果是敌人
		if is_strong_fire:
			collider.hurt(fire_crack)
		else: collider.hurt(fire_crack)
	queue_free() #发生碰撞，需要删除
	print('玩家子弹与其他发生了碰撞💥')
