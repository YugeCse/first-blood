class_name BossBullet extends Area2D

@export
var speed: float = 200.0

@export
var direction: Vector2 = Vector2.ZERO

@export
var position_min: Vector2 = Vector2.ZERO

@export
var position_max: Vector2 = Vector2(10000.0, 10000.0)

## 是否爆炸了
var _is_explosion: bool = false

@onready
var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready
var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	anim_sprite.play(&'default')

func _physics_process(delta: float) -> void:
	if _is_explosion: return #如果销毁了，直接返回
	if position.x <= position_min.x - 100.0\
		or position.x >= position_max.x + 100.0\
		or position.y <= position_min.y - 100.0\
		or position.y >= position_max.y + 100.0:
		_destory() #销毁这个子弹
		return
	position += direction * speed * delta

func _destory() -> void:
	if _is_explosion: return
	_is_explosion = true
	anim_sprite.play(&'explosion')
	anim_sprite.animation_finished\
		.connect(queue_free)
	self.set_deferred('monitoring', false)
	self.set_deferred('monitorable', false)

func _on_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if not parent: return
	if parent is Player: #如果与玩家发生碰撞
		_destory()
		parent.hurt(randf_range(30, 60))
	elif parent is PlayerBullet: #如果玩家子弹发生碰撞
		_destory()
		parent.boom()
