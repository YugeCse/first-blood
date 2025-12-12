## 敌人组件
@tool
class_name Enemy extends CharacterBody2D

## 当前行为
@export
var action = EnemyState.Action.idle

## 血量
@export_range(0, 1000)
var life_blood: float = 200.0

## 最大血量
@export_range(0, 1000)
var life_blood_max: float = 200.0

## 被监视的玩家
var spy_player: Player

@export
var sprite: AnimatedSprite2D

@export
var collision_shape: CollisionShape2D

func _ready() -> void:
	if life_blood_max < life_blood:
		life_blood_max = life_blood
	if life_blood_max < 0.0:
		life_blood_max = 100.0
	sprite.play("idle") #显示静止状态
	sprite.flip_h = true #朝玩家方向
	_draw_life_blood_in_edit_mode()

func _enter_tree() -> void:
	_draw_life_blood_in_edit_mode()

func _physics_process(delta: float) -> void:
	_detect_position_clamp() #检测坐标越界处理
	_draw_life_blood_in_edit_mode()
	if action == EnemyState.Action.potral: #巡逻
		potral() #执行巡逻
	elif action == EnemyState.Action.chase and spy_player: #追击玩家
		chase() #执行追击

## 执行巡逻， 沿着一定的区域范围进行行走
func potral():
	pass

## 执行追击，这个过程会执行射击
func chase():
	var angle = global_position\
		.dot(spy_player.global_position)
	if angle > 0:
		print('玩家在他的前方')
	elif angle < 0:
		print('玩家在他的后方')
	else: print('玩家在他的正侧方')

## 执行射击
func shoot():
	pass
	
## 受到伤害
## [br]
## - crack: 受到的伤害点数
func hurt(crack: float):
	var diff = life_blood - crack
	if diff <= 0.0:
		life_blood = 0.0
	if life_blood <= 0.0:
		destory() #敌人被毁坏

## 敌人被毁坏
func destory():
	action = EnemyState.Action.dead
	collision_shape.disabled = true
	sprite.play('dead')
	sprite.animation_finished.connect(queue_free)

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

## 绘制血条图形
func _draw() -> void:
	if action == EnemyState.Action.dead:
		return #如果已经死亡，不再绘制血条
	var size = _get_collision_rect().size
	var blood_width = 15.0
	var draw_position = Vector2(-7.5, -size.y/2.0)
	var life_percent = life_blood / life_blood_max
	draw_rect(Rect2(draw_position, Vector2(blood_width *  life_percent, 2.0)), Color.RED)
	draw_rect(Rect2(draw_position, Vector2(blood_width, 2.0)), Color.WEB_GRAY, false, 0.5)

## 在编辑模式中绘制血条请求
func _draw_life_blood_in_edit_mode():
	if Engine.is_editor_hint(): queue_redraw()

func _on_detector_area_2d_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is Player:
		spy_player = parent as Player
		print('玩家进入敌人{}监视范围'.format([name]))

func _on_detector_area_2d_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is Player and parent == spy_player:
		spy_player = null
		print('玩家离开敌人{}监视范围'.format([name]))
