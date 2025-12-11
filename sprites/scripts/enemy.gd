## 敌人组件
class_name Enemy extends CharacterBody2D

@export
var action = EnemyState.Action.idle

@export
var sprite: AnimatedSprite2D

@export
var collision_shape: CollisionShape2D

func _ready() -> void:
	sprite.play("idle") #显示静止状态
	sprite.flip_h = true #朝玩家方向

func _physics_process(delta: float) -> void:
	_detect_position_clamp() #检测坐标越界处理

## 获取碰撞区域矩形大小(相对于全局坐标而言)
func _get_collision_rect()->Rect2:
	var shape = \
		collision_shape.shape as RectangleShape2D
	return Rect2(global_position, shape.size)

## 检测坐标越界处理
func _detect_position_clamp():
	var shape_size = _get_collision_rect().size
	var min_x = -shape_size.x / 2.0
	var max_x = GlobalConfigs.DESIGN_MAP_WIDTH + shape_size.x / 2.0
	var max_y = GlobalConfigs.DESIGN_MAP_HEIGHT + shape_size.y / 2.0
	if global_position.x < min_x or\
		global_position.x > max_x or\
		global_position.y > max_y:
		queue_free() #丛节点中删除这个敌人
