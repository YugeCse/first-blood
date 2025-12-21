## 敌人子弹组件
class_name EnemyBullet extends Area2D

enum OwnerType { turret, grunt }

## 子弹移动速度
@export
var speed: float = 200.0

## 子弹移动方向
@export
var direction: Vector2 = Vector2.LEFT

## 子弹拥有者类型
var owner_type: OwnerType

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
	sprite.animation_finished.connect(queue_free)

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

## 发生爆炸
func boom():
	if collision_shape.disabled:
		return #已经是待销毁状态了
	collision_shape.set_deferred(&'disabled', true)
	if sprite.animation_finished.is_connected(queue_free):
		sprite.animation_finished.disconnect(queue_free)
	sprite.play(&'boom') #播放爆炸效果
	sprite.animation_finished.connect(queue_free) #设置从节点删除
	sprite.set(&'modulate',Color(0.907, 0.588, 0.86, 0.929))

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if not parent: #如果是子弹间发生的盆装
		if area is PlayerBullet:
			boom(); area.boom()
		return
	if parent is Player: #如果碰到玩家了
		boom() #销毁这个子弹组件
		if not owner_type: return
		if owner_type == OwnerType.turret:
			parent.hurt(randf_range(10, 20))
		else: parent.hurt(randf_range(5, 15))
