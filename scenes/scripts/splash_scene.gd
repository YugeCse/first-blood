## 启动界面
class_name SplashScene extends Control

## 最大加载时间，5.0s
var max_loading_time: float = 5.0

## 启动时的时间，单位：秒
var start_time_record: float = 0.0

## 主场景是否加载完成
var is_main_scene_loaded: bool = false

## 主场景
var main_scene_path = 'res://scenes/tscns/main_scene.tscn'

## 主场景加载进度条
@onready
var progress_bar: ProgressBar = $TextureRect/ProgressBar

func _ready() -> void:
	start_time_record = Time.get_unix_time_from_system()
	ResourceLoader.load_threaded_request(main_scene_path)

func _process(_delta: float) -> void:
	if is_main_scene_loaded: return #场景加载过了，不用再加载了
	var progress: Array[float] = [0.0]
	var status = ResourceLoader\
		.load_threaded_get_status(main_scene_path, progress)
	match status:
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
			print('场景加载中 ', progress_bar.value)
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			print('场景加载完成✅', progress_bar.value)
			is_main_scene_loaded = true
			await get_tree().process_frame
			_show_main_scene() #显示主场景

## 显示主场景
func _show_main_scene() -> void:
	var diff_time =\
		 (Time.get_unix_time_from_system() - start_time_record)
	diff_time = clampf(max_loading_time - diff_time, 0.0, max_loading_time)
	if diff_time > 0.0:
		await get_tree().create_timer(diff_time).timeout
	progress_bar.ratio = 1.0 #赋值已经达到100%
	var tween = get_tree().create_tween()
	tween.tween_property($".", 'modulate:a', 0.0, 0.9)
	var main_scene_packed = ResourceLoader\
		.load_threaded_get(main_scene_path)
	get_tree().change_scene_to_packed(main_scene_packed)
