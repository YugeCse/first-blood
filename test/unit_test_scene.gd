@tool
extends Control

const CommonUtils = preload('res://shared/utils/common_utils.gd')

func _ready() -> void:
	_initialize() #初始化
	test_drop_system() #测试物品掉落系统

## 初始化方法
func _initialize() -> void:
	_adjust_controls_size()
	get_window().size_changed.connect(_adjust_controls_size)

## 调整控件大小适配窗口
func _adjust_controls_size() -> void:
	var visible_rect = get_viewport().get_visible_rect()
	var visible_rect_size = visible_rect.size
	var sub_viewport_size = $SubViewportContainer.size
	var require_scale = visible_rect_size.y / sub_viewport_size.y
	$SubViewportContainer.position = Vector2.ZERO
	$SubViewportContainer.scale = Vector2(require_scale, require_scale)

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
