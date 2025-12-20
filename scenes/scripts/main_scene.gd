## 主场景组件
class_name MainScene extends Control

var current_window_scale: float = 3.0

## 玩家对象
@onready
var player = $Player

## 玩家生命进度条
@onready
var player_life_progress_bar: TextureProgressBar = $HUDContainer/HBoxContainer/TextureProgressBar

func _ready() -> void:
	current_window_scale = ProjectSettings\
		.get_setting('display/window/stretch/scale')

func _physics_process(_delta: float) -> void:
	#var vr_size = get_viewport().get_visible_rect().size
	#var scale_value = vr_size.y / GlobalConfigs.DESIGN_MAP_HEIGHT
	#if current_window_scale != scale_value:
		#set_window_scale(scale_value)
		#current_window_scale = scale_value
	if player: #如果玩家还存在
		player_life_progress_bar.value =\
			(player.life_blood / player.life_blood_max) * 100.0
	$HUDContainer.offset.x = absf(get_screen_position().x)

## 把子节点添加到相机中
func add_child_to_camera(child: Node) -> void:
	add_child(child)

func set_window_scale(scale_value: float):
	var target_scale = clamp(scale_value, 0.5, 5.0)
	# 更新项目设置
	ProjectSettings.set_setting(\
		"display/window/stretch/scale", target_scale)
	# 应用缩放
	get_tree().root.content_scale_factor = target_scale
	print("窗口缩放设置为: ", target_scale)
