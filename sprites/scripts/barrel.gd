class_name Barrel extends Area2D

enum State {
	idle,
	bom,
	destroy
}

## 是否是红色的
@export
var is_red: bool = false

## 基础精灵对象
@export
var sprite: Sprite2D

## 基础碰撞shape对象
@export
var default_collision_shape: CollisionShape2D

## 爆炸精灵对象
@export
var bom_sprite: AnimatedSprite2D

## 爆炸范围检测对象
@export
var bom_area_detector: Area2D

## 爆炸碰撞shape对象
@export
var bom_collision_shape: CollisionShape2D

## 当前状态
var state: Barrel.State = Barrel.State.idle

## 是否把邻居激活了
var _is_neigbor_active: bool = false

## 已经飞行了的时间
var _fly_time: float = 0.0

## 下落爆炸等待时间
var _fall_bom_time: float = 0.15

## 飞行速度
var _fly_speed: float = 100.0

## 最大飞行距离
var _max_fly_distance: float

## 飞行方向
var _fly_direction: Vector2

## 开始飞行的坐标
var _start_fly_position: Vector2

## 是否到达最大距离了
var _is_attach_max_distance: bool = false

## 爆炸声的音频数据
@onready
var bom_effect_audio_stream = preload('res://assets/audio/explosion_effect.ogg')

func _ready() -> void:
	bom_sprite.animation_finished\
		.connect(func(): state = State.destroy)
	bom_area_detector.set_deferred(&'monitoring', false)
	bom_area_detector.set_deferred(&'monitorable', false)
	bom_sprite.frame_changed.connect(_on_bom_sprite_frame_changed)

func _process(delta: float) -> void:
	if state == State.idle:
		sprite.visible = true
		bom_sprite.visible = false
	elif state == State.bom:
		sprite.visible = false
		bom_sprite.visible = true
	else: #已经被销毁
		queue_free()
		return
	if _fly_direction: #如果已经在飞行了，执行抛物线
		_fly_time += delta #累计计算飞行了的时间
		var distance = global_position\
			.distance_to(_start_fly_position)
		if distance < _max_fly_distance:
			global_position += _fly_direction * _fly_speed * delta
		else:
			if state == State.bom: return #已经爆炸了，直接返回
			if not _is_attach_max_distance:
				_is_attach_max_distance = true
				_fall_bom_time = randf_range(0.1, 0.3)
				_fly_direction.x = 1 if randi_range(0, 1) == 1 else -1
			if state == State.idle and\
				_fall_bom_time and _fly_time > _fall_bom_time:
				_show_bom_effect() #显示爆炸效果
				return #爆炸了就不能继续飞行了，要返回
			_fly_direction.y = 1.0 #重力加速度计算
			var velocity = Vector2(_fly_speed * _fly_direction.x, 0.0)
			velocity.y += 98.0 #使用重力加速度
			global_position += velocity * delta #重新更新坐标位置

## 获取爆炸影响矩形数据
func _get_bom_effect_area_rect() -> Rect2:
	var shape = bom_collision_shape\
		.shape as RectangleShape2D
	return Rect2(global_position, shape.size)

## 显示爆炸效果
func _show_bom_effect() -> void:
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = bom_effect_audio_stream
	audio_player.autoplay = true
	audio_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(audio_player) #添加到树节点中
	
	state = State.bom
	self.set_deferred(&'monitoring', false)
	self.set_deferred(&'monitorable', false)
	bom_sprite.play(&'default')
	bom_area_detector.set_deferred(&'monitoring', true)
	bom_area_detector.set_deferred(&'monitorable', true)

## 爆炸帧的变更事件
func _on_bom_sprite_frame_changed():
	var cur_rect = _get_bom_effect_area_rect()
	if bom_sprite.frame_progress < 0.9:
		if not _is_neigbor_active:
			_is_neigbor_active = true
			var barrel_nodes = get_tree()\
				.get_nodes_in_group('Barrel')
			var neigbors = barrel_nodes.filter(func(n): \
				return n != self and\
					n.state == State.idle and\
					n._get_bom_effect_area_rect()\
					.intersects(cur_rect))
			if not neigbors or neigbors.size() == 0: return
			for neigbor in neigbors:
				neigbor._max_fly_distance = randf_range(35, 80)
				neigbor._fly_speed = randf_range(100.0, 200.0)
				neigbor._fly_direction = Vector2.from_angle(\
					deg_to_rad(randf_range(190, 350)))
				neigbor._start_fly_position = neigbor.global_position
				neigbor._fly_time = 0.0
				neigbor._is_attach_max_distance = false
		return
	bom_area_detector.set_deferred(&'monitoring', false)
	bom_area_detector.set_deferred(&'monitorable', false)
	
## 本地与其他物品发生碰撞，一般特指与子弹碰撞
func _on_area_entered(area: Area2D) -> void:
	if area is PlayerBullet: #如果与子弹发生碰撞，跳转为爆炸模式
		area.boom() #子弹也发生爆炸
		_show_bom_effect() #显示爆炸效果
		
## 爆炸物与其他发生碰撞，一般值得把敌人或者玩家炸死
func _on_bom_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
