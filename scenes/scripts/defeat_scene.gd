## 失败后的显示页面
class_name DefeatScene extends Control

## 结束画面的缩放比例 
var _current_img_scale: float

## 结束画面的尺寸
var _image_size = Vector2(320.0, 180.0)

## 是否进入了启动页面
var _is_enter_splash_scene: bool = false

## 结束画面的图像
@onready
var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process_input(true)
	_update_defeat_image_display()
	get_window().size_changed\
		.connect(_update_defeat_image_display)
	sprite.play(&'default', 0.25)
	sprite.animation_finished.connect(_show_continue_game)

func _process(_delta: float) -> void:
	if Input.is_anything_pressed(): #点击任何按键，继续游戏
		_show_splash_scene() #显示启动页面
		return

## 更新失败图像的显示
func _update_defeat_image_display() -> void:
	var visible_rect_size = get_viewport().get_visible_rect().size
	var target_scale = minf(visible_rect_size.x /_image_size.x,\
		visible_rect_size.y /_image_size.y)
	if not _current_img_scale or _current_img_scale != target_scale:
		_current_img_scale = target_scale
		var img_x = _image_size.x * target_scale
		var img_y = _image_size.y * target_scale
		var offset_x = (visible_rect_size.x - img_x) / 2.0
		var offset_y = (visible_rect_size.y - img_y) / 2.0
		sprite.position = Vector2(offset_x, offset_y)
		sprite.scale = Vector2(target_scale, target_scale)

## 显示继续游戏的提示界面
func _show_continue_game() -> void:
	if sprite.animation_finished\
		.is_connected(_show_continue_game):
		sprite.animation_finished.disconnect(_show_continue_game)
	sprite.play(&'still') #显示等待用户操作

## 显示启动页面
func _show_splash_scene() -> void:
	if _is_enter_splash_scene: return
	_is_enter_splash_scene = true
	GlobalConfigs.reset_player_data() #还原用户数据
	get_tree().change_scene_to_file('res://scenes/tscns/splash_scene.tscn')
