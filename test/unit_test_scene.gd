@tool
extends Node2D

@export
var viewport_design_size: Vector2 = Vector2(416.0, 210.0)

@onready
var player: Player = $SubViewportContainer/SubViewport/Player

@onready
var viewport_container: SubViewportContainer = $SubViewportContainer

@onready
var viewport: SubViewport = $SubViewportContainer/SubViewport

const CommonUtils = preload('res://shared/utils/common_utils.gd')

func _ready() -> void:
	_initialize() #初始化
	if player: #如果玩家存在，就设置玩家对象的对应限制
		player.walk_area_x = 882
		player.walk_area_y = 210
		if not player.get_children()\
			.any(func(node): return node is Camera2D):
			player.add_child(_create_player_camera())
	test_drop_system() #测试物品掉落系统

## 初始化方法
func _initialize() -> void:
	viewport_design_size = viewport_container.size
	_adjust_controls_size()
	get_window().size_changed.connect(_adjust_controls_size)

## 调整控件大小适配窗口
func _adjust_controls_size() -> void:
	var visible_rect = get_viewport().get_visible_rect()
	var visible_rect_size = visible_rect.size
	var scaler = minf(visible_rect_size.x / viewport_design_size.x,\
		visible_rect_size.y / viewport_design_size.y)
	var final_width = viewport_design_size.x * scaler
	var final_height = viewport_design_size.y * scaler
	var offset_x = (visible_rect_size.x - final_width) / 2.0
	var offset_y = (visible_rect_size.y - final_height) / 2.0
	viewport_container.scale = Vector2(scaler, scaler)
	viewport_container.global_position = Vector2(offset_x, offset_y)

## 测试物品掉落系统
func test_drop_system() -> void:
	var drop_system = DropSystem.new()
	add_child(drop_system)
	var drop_result = drop_system.calculate_drops_weighted("grunt")
	if drop_result.size() > 0:
		for key in drop_result.keys():
			var prop_name = CommonUtils.enum_to_string(Prop.PropType, key)
			print('物品掉落结果：', prop_name, ', 数量：', drop_result.get(key))
	else: print('没有物品掉落！')

## 创建玩家跟随的相机对象
func _create_player_camera() -> Camera2D:
	var camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 882
	camera.limit_bottom = 210
	camera.position_smoothing_enabled = true
	return camera
