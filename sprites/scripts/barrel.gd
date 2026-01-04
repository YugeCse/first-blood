class_name Barrel extends Area2D

## 状态
enum State { idle, bom, destroy }

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

## 爆炸伤害
@export_range(10, 50)
var bom_attack: float = 50.0

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

## 爆炸路线
var _bom_path: Path2D

## 爆炸的点位跟随
var _bom_path_follow: PathFollow2D

## 爆炸路径总长度
var _bom_path_total_len: float = 0.0

## 爆炸声的音频数据
@onready
var bom_effect_audio_stream = preload('res://assets/audio/explosion_effect.ogg')

func _ready() -> void:
	sprite.visible = true
	bom_sprite.visible = false
	bom_attack = randf_range(10.0, 50.0)
	bom_sprite.animation_finished\
		.connect(func(): state = State.destroy; queue_free())
	bom_area_detector.set_deferred(&'monitoring', false)
	bom_area_detector.set_deferred(&'monitorable', false)
	bom_sprite.frame_changed.connect(_on_bom_sprite_frame_changed)

func _process(delta: float) -> void:
	if _bom_path_follow and state != State.bom: #如果已经在飞行了，执行抛物线
		_fly_time += delta #累计计算飞行了的时间
		if state == State.idle and\
			_fall_bom_time and _fly_time > _fall_bom_time:
			_show_bom_effect() #显示爆炸效果
			return #爆炸了就不能继续飞行了，要返回
		_bom_path_follow.progress_ratio +=\
			(_fly_speed * delta) / _bom_path_total_len
		global_position = _bom_path.curve.sample_baked(_bom_path_follow.progress)

## 设置激活飞行模式
func _set_active_fly_mode() -> void:
	var bom_path2d = _create_bom_path2d()
	add_child(bom_path2d)
	_bom_path = bom_path2d
	_bom_path_total_len = bom_path2d.curve.get_baked_length()
	_bom_path_follow = PathFollow2D.new()
	_bom_path_follow.loop = false
	bom_path2d.add_child(_bom_path_follow)

## 获取爆炸影响矩形数据
func _get_bom_effect_area_rect() -> Rect2:
	var shape = bom_collision_shape\
		.shape as RectangleShape2D
	return Rect2(global_position, shape.size)

## 显示爆炸效果
func _show_bom_effect() -> void:
	if state == State.bom: return
	AudioManager.play_barrel_explosion() #播放爆炸声音
	# 设置当前状态为爆炸状态
	state = State.bom
	sprite.visible = false
	bom_sprite.visible = true
	self.set_deferred(&'monitoring', false)
	self.set_deferred(&'monitorable', false)
	bom_sprite.play(&'default')
	bom_area_detector.set_deferred(&'monitoring', true)
	bom_area_detector.set_deferred(&'monitorable', true)

## 获取爆炸最高点
func _get_bom_high_coord() -> Vector2:
	var d_x = randf_range(15, 80)
	var d_h = randf_range(15, 80)
	var dir = -1 if randi_range(0, 1) == 0 else 1
	return Vector2(global_position.x + dir * d_x, global_position.y - d_h)

## 创建爆炸运行曲线
func _create_bom_path2d() -> Path2D:
	var start_pos = global_position
	var contrl_pos = _get_bom_high_coord()
	var dist_x = contrl_pos.x - start_pos.x
	var final_pos = Vector2(contrl_pos.x + dist_x + sign(dist_x) * randf() * 30, start_pos.y)
	var curve = Curve2D.new()
	curve.add_point(start_pos)
	# 中间控制点（二次贝塞尔的控制点）
	# 计算控制柄，使点成为三次贝塞尔的中间点
	var in_vec = (contrl_pos - start_pos) * 0.5
	var out_vec = (final_pos - contrl_pos) * 0.5
	curve.add_point(contrl_pos, -in_vec, out_vec)
	curve.add_point(final_pos)
	
	var path2d = Path2D.new()
	path2d.curve = curve
	return path2d

## 爆炸帧的变更事件
func _on_bom_sprite_frame_changed():
	var cur_rect = _get_bom_effect_area_rect()
	#如果爆炸进度超过60%了，就不会造成伤害了
	#在小于60%这个阶段会对周边物品/人造成伤害
	if bom_sprite.frame_progress < 0.38:
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
				neigbor._fly_time = 0.0
				neigbor._fly_speed = randf_range(100.0, 200.0)
				neigbor._fall_bom_time = randf_range(0.15, 0.5)
				neigbor._set_active_fly_mode() #设置激活飞行模式
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
	var distance = global_position\
		.distance_to(body.global_position)
	var bom_effect_radius = _get_bom_effect_area_rect().size.x
	var percent = absf(distance) / absf(bom_effect_radius)
	var hurt = clampf(percent * bom_attack, 0, bom_attack)
	if body is Turret: #炮台被炸伤
		body.hurt(hurt)
	elif body is Grunt: #敌人受伤
		body.hurt(hurt)
	elif body is Player:
		body.hurt(hurt) #玩家受伤
