## 道具组件
@tool
class_name Prop 
extends CharacterBody2D

## 道具类型
enum PropType {
	## 纳豆(食物)
	nade,
	## 弹药
	ammo,
	## 木箱
	crate,
	## 大木箱
	big_crate
}

## 道具类型
@export
var prop_type: PropType = PropType.crate

## 数据包
@export
var bundle: Dictionary[String, Variant]

## 道具自动消失时间，默认：15s
@export
var auto_dismiss_time: float = 15.0

@onready
var sprite: Sprite2D = $PickArea2D/Sprite2D

@onready
var collision_shape: CollisionShape2D = $PickArea2D/CollisionShape2D

## 执行自动消失的定时器对象
var _auto_dismiss_timer: Timer

func _ready() -> void:
	if auto_dismiss_time > 0:
		_create_auto_dismiss_timer()
	_update_prop_sprite(prop_type)

func _physics_process(_delta: float) -> void:
	if auto_dismiss_time > 0:
		if is_on_floor():
			velocity.y = 0.0
		else: velocity.y += 9.8
		move_and_slide() #执行移动逻辑
	else: _stop_auto_dismiss_timer()

## 创建自动消失的定时器
func _create_auto_dismiss_timer():
	_auto_dismiss_timer = Timer.new()
	_auto_dismiss_timer.wait_time = auto_dismiss_time
	_auto_dismiss_timer.timeout.connect(_start_blink)
	_auto_dismiss_timer.autostart = true
	add_child(_auto_dismiss_timer) #添加到树节点中国呢

## 停止自动消息的定时器
func _stop_auto_dismiss_timer() -> void:
	if not _auto_dismiss_timer: return
	if not _auto_dismiss_timer.is_stopped():
		_auto_dismiss_timer.paused = true
		_auto_dismiss_timer.stop()
	remove_child(_auto_dismiss_timer)

## 更新道具精灵
func _update_prop_sprite(type: PropType) -> void:
	var sprite_texture: Resource
	var is_nade_prop: bool = false
	match type: #根据道具类型，做不同处理
		PropType.nade: #纳豆
			set_collision_layer_value(9, false)
			set_collision_layer_value(11, false)
			set_collision_layer_value(12, false)
			set_collision_layer_value(13, true)
			var is_red = randi_range(0, 1) == 0
			if not bundle:
				bundle = {} #如果没有初始化，先初始化
			#红色增加50血量，蓝色增加30血量
			bundle['blood'] = 50 if is_red else 30
			sprite_texture = load('res://assets/ui/ui_nade_{color}.png'\
				.format({'color': 'red' if is_red else 'blue'}))
			is_nade_prop = true #标记是纳豆的道具
		PropType.ammo: #弹药
			set_collision_layer_value(9, true)
			set_collision_layer_value(11, false)
			set_collision_layer_value(12, false)
			set_collision_layer_value(13, false)
			sprite_texture = load('res://assets/props/ammo.png')
		PropType.crate: #木箱
			set_collision_layer_value(9, false)
			set_collision_layer_value(11, true)
			set_collision_layer_value(12, false)
			set_collision_layer_value(13, false)
			sprite_texture = load('res://assets/props/crate.png')
		PropType.big_crate: #大木箱
			set_collision_layer_value(9, false)
			set_collision_layer_value(11, false)
			set_collision_layer_value(12, true)
			set_collision_layer_value(13, false)
			sprite_texture = load('res://assets/props/bigcrate.png')
	if not sprite_texture: return
	if sprite_texture is Texture2D:
		sprite.texture = sprite_texture
	sprite.scale = Vector2(1.0, 1.0) if is_nade_prop else Vector2(0.6, 0.6)
	var sprite_size = sprite.texture.get_size() * sprite.scale.x
	_update_collision_shape(sprite_size) #更新碰撞矩形形状

## 更新碰撞矩形形状
func _update_collision_shape(size: Vector2) -> void:
	var shape = RectangleShape2D.new()
	shape.size = size
	collision_shape.shape = shape
	$CollisionShape2D.shape = shape #最外面的形状也是通内部的一样

## 执行闪烁动画
func _start_blink() -> void:
	_stop_auto_dismiss_timer() #先停止这个定时器
	var tween = get_tree().create_tween()
	tween.set_loops(3)
	tween.tween_property(self, 'modulate:a', 0.2, 0.5)
	tween.tween_property(self, 'modulate:a', 1.0, 0.5)
	tween.play()
	tween.finished.connect(_dismiss_prop) #闪烁完成后，移除该节点

## 让道具消失
func _dismiss_prop(hide_time: float = 1.0) -> void:
	var tween = get_tree().create_tween()
	tween.set_loops(1)
	tween.set_parallel(true)
	tween.tween_property(self, 'scale', 0.0, hide_time)
	tween.tween_property(self, 'modulate:a', 0.0, hide_time)
	tween.play()
	tween.finished.connect(queue_free) #动画完成从节点删除

## 道具与玩家发生碰撞判断
func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return #如果不是与玩家碰撞，直接返回
	_stop_auto_dismiss_timer() #先停止这个定时器
	(body as Player).get_prop(prop_type, bundle) #玩家获得道具
	if prop_type == PropType.ammo: #如果是弹药道具，直接从视图删除
		queue_free()
		return
	_dismiss_prop(0.2) #0.2s后隐藏并删除道具
	#停用道具的碰撞检测
	$PickArea2D.set_deferred(&'monitoring', false)
	$PickArea2D.set_deferred(&'monitorable', false)
	collision_shape.set_deferred(&'disabled', true)
