## 玩家子弹组件
class_name PlayerBullet extends Area2D

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
		sprite.play(&'level2')
	else: sprite.play(&'default')
	sprite.rotate(direction.angle())
	sprite.animation_finished.connect(boom)

func _physics_process(delta: float) -> void:
	var collision_radius = _get_collision_cirle().radius
	if global_position.x - collision_radius < 0 or\
		global_position.x - collision_radius > GlobalConfigs.DESIGN_MAP_WIDTH or\
		global_position.y - collision_radius < 0 or\
		global_position.y - collision_radius > GlobalConfigs.DESIGN_MAP_WIDTH:
		queue_free() #销毁这个子弹组件
		return
	if collision_shape.disabled: return
	position += direction * speed * delta

## 获取碰撞区域的矩形信息
func _get_collision_cirle() -> CircleShape2D:
	return collision_shape.shape as CircleShape2D

## 发生碰撞，需要删除
func boom():
	if collision_shape.disabled:
		return #已经是待销毁状态了
	collision_shape.disabled = true
	sprite.animation_finished.disconnect(boom)
	sprite.play(&'boom')
	sprite.animation_finished.connect(queue_free)

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if not parent: 
		if area is EnemyBullet:
			boom()
			area.boom()
		return
	var fire_crack = 10.0
	if is_strong_fire:
		fire_crack = randf_range(20.0, 60.0)
	else: fire_crack = randf_range(10.0, 40.0)
	if parent is Turret: #如果是炮台
		parent.hurt(fire_crack)
		boom() #发生碰撞，需要删除
	elif parent is Enemy: #如果是敌人
		if is_strong_fire:
			parent.hurt(fire_crack)
		else: parent.hurt(fire_crack)
		boom() #发生碰撞，需要删除
