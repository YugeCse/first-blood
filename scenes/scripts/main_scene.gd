## 主场景
class_name MainScene extends ColorRect

## 是否运行在手机中，默认：false
var _is_run_in_mobile: bool = false

## 视窗对象
@onready
var viewport: SubViewport = $ViewportContainer/Viewport

## 视窗容器对象
@onready
var viewport_container: SubViewportContainer = $ViewportContainer

func _ready() -> void:
	_is_run_in_mobile =\
		OS.get_name() in ['Android', 'iOS']
	if not _is_run_in_mobile: 
		_adjust_viewport_size() #调整视窗尺寸信息
		get_window().size_changed.connect(_adjust_viewport_size)

## 调整视窗尺寸信息
func _adjust_viewport_size() -> void:
	var visible_rect = get_viewport().get_visible_rect()
	var visible_size = visible_rect.size
	viewport_container.size = visible_size
