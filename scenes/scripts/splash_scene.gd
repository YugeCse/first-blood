## 启动界面
class_name SplashScene extends Control

## 最大加载时间，5.0s
var max_loading_time: float = 5.0

## 启动时的时间，单位：秒
var start_time_record: float = 0.0

## 主场景是否加载完成
var is_main_scene_loaded: bool = false

## 当前启动图的缩放比例
var _current_splash_img_scale: float

## 启动图的大小
var _splash_image_size = Vector2(320.0, 180.0)

## 是否进入了主场景
var _is_enter_main_scene: bool = false

## 主场景
var main_scene_path = 'res://scenes/tscns/main_scene.tscn'

## 主场景加载进度条
@onready
var progress_bar: ProgressBar = $ProgressBar

## 期待图的动态精灵对象
@onready
var animated_sprite: AnimatedSprite2D = $SplashAnimatedSprite

func _ready() -> void:
	_update_splash_image_display()
	get_window().size_changed\
		.connect(_update_splash_image_display)
	start_time_record = Time.get_unix_time_from_system()
	ResourceLoader.load_threaded_request(main_scene_path)

func _process(_delta: float) -> void:
	if Input.is_anything_pressed(): #点击任何按键，继续游戏
		_show_main_scene() #显示主场景
		return
	_preload_main_scene() #预加载主场景内容

## 更新启动图的显示
func _update_splash_image_display() -> void:
	var visible_rect_size = get_viewport().get_visible_rect().size
	var target_scale = minf(visible_rect_size.x /_splash_image_size.x,\
		visible_rect_size.y /_splash_image_size.y)
	if not _current_splash_img_scale or\
		_current_splash_img_scale != target_scale:
		_current_splash_img_scale = target_scale
		var img_x = _splash_image_size.x * target_scale
		var img_y = _splash_image_size.y * target_scale
		var offset_x = (visible_rect_size.x - img_x) / 2.0
		var offset_y = (visible_rect_size.y - img_y) / 2.0
		animated_sprite.position = Vector2(offset_x, offset_y)
		animated_sprite.scale = Vector2(target_scale, target_scale)
		if progress_bar: #如果进度条可用，设置进度条属性
			progress_bar.scale = animated_sprite.scale
			progress_bar.position = Vector2(\
				(visible_rect_size.x - progress_bar.size.x * target_scale) / 2.0,\
				visible_rect_size.y - offset_y - progress_bar.size.y * target_scale * 2.0)

## 预加载主场景内容
func _preload_main_scene() -> void:
	if is_main_scene_loaded: return #场景加载过了，不用再加载了
	var progress: Array[float] = [0.0]
	var status = ResourceLoader\
		.load_threaded_get_status(main_scene_path, progress)
	match status: #根据状态处理逻辑
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
			print('场景不存在 ')
			is_main_scene_loaded = true
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
			print('场景加载失败 ')
			is_main_scene_loaded = true
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
			var new_progress = progress[0]
			if new_progress >= 1.0:
				new_progress = 0.999999
			progress_bar.value = new_progress * 100.0
			print('场景加载中 ', progress_bar.value, progress)
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			print('场景加载完成✅', progress_bar.value)
			is_main_scene_loaded = true
			_hide_progress_bar() #隐藏progressbar

## 隐藏progressbar
func _hide_progress_bar() -> void:
	progress_bar.value = 100.0
	var tween = get_tree().create_tween()
	tween.tween_property(progress_bar, 'modulate:a', 0.0, 0.8)
	tween.play() #执行透明度动画
	tween.finished.connect(progress_bar.queue_free)

## 显示主场景
func _show_main_scene() -> void:
	if _is_enter_main_scene: return
	_is_enter_main_scene = true
	var main_scene_packed = ResourceLoader\
		.load_threaded_get(main_scene_path)
	if not main_scene_packed: return
	get_tree().change_scene_to_packed(main_scene_packed)
