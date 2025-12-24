## 主场景
class_name MainScene extends ColorRect

## 是否运行在手机中，默认：false
var _is_run_in_mobile: bool = false

## 视窗的默认大小
var _viewport_default_size: Vector2 = Vector2(380.0, 210.0)

## 是否调用了game-over
var is_game_over: bool = false

## 视窗对象
@onready
var viewport: SubViewport = $ViewportContainer/Viewport

## 视窗容器对象
@onready
var viewport_container: SubViewportContainer = $ViewportContainer

func _ready() -> void:
	match OS.get_name():
		'iOS': _is_run_in_mobile = true
		'Android': _is_run_in_mobile = true
	$VirtualJoystic.visible = _is_run_in_mobile
	_viewport_default_size = viewport.size #获取原有的默认大小
	_adjust_viewport_size() #调整视窗尺寸信息
	get_window().size_changed.connect(_adjust_viewport_size)
	if not _is_run_in_mobile: remove_child($VirtualJoystic) #移除虚拟游戏摇杆组件
	GlobalSignals.on_game_over.connect(_on_game_over)

## 调整视窗尺寸信息，非安卓/iOS的设备，需要根据主视窗调整大小
func _adjust_viewport_size() -> void:
	var visible_rect = get_viewport().get_visible_rect()
	var visible_size = visible_rect.size
	var default_x = _viewport_default_size.x
	var default_y = _viewport_default_size.y
	var require_scale =\
		minf(visible_size.x / default_x, visible_size.y / default_y)
	var target_width = require_scale * default_x
	var target_height = require_scale * default_y
	var offset_x = (visible_size.x - target_width) / 2.0
	var offset_y = (visible_size.y - target_height) / 2.0
	# viewport_container.size = Vector2(target_width, target_height)
	viewport_container.scale = Vector2(require_scale, require_scale)
	viewport_container.global_position = Vector2(offset_x, offset_y)

## 游戏结束时的监听方法
func _on_game_over() -> void:
	if is_game_over:
		return #已经调用过game_over操作了
	is_game_over = true #标记游戏已经结束
	print('游戏结束了，玩家角色生命已经用完！切换到defeat页面！')
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file('res://scenes/tscns/defeat_scene.tscn')
	
	
