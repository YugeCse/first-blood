## 启动界面
class_name SplashScene extends Control

## 主场景是否加载完成
var is_main_scene_loaded: bool = false

## 主场景
var main_scene_path = 'res://scenes/tscns/main_scene.tscn'

## 主场景加载进度条
@onready
var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
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
			progress_bar.ratio = progress[0]
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			print('场景加载完成✅')
			is_main_scene_loaded = true
			_show_main_scene() #显示主场景

## 显示主场景
func _show_main_scene() -> void:
	await get_tree().create_timer(1.0).timeout
	var main_scene_packed = ResourceLoader\
		.load_threaded_get(main_scene_path)
	get_tree().change_scene_to_packed(main_scene_packed)
