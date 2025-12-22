extends Control

var _current_img_scale: float

var _image_size = Vector2(320, 180)

@onready
var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.play(&'default', 0.25)
	sprite.animation_finished.connect(_show_continue_game)

func _show_continue_game():
	if sprite.animation_finished\
		.is_connected(_show_continue_game):
		sprite.animation_finished.disconnect(_show_continue_game)
	sprite.play(&'still') #显示等待用户操作

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_anything_pressed(): #点击任何按键，继续游戏
		GlobalConfigs.reset_player_data()
		get_tree().change_scene_to_file('res://scenes/tscns/splash_scene.tscn')
		return
	var visible_rect_size = get_window().get_visible_rect().size
	var target_scale = minf(visible_rect_size.x /_image_size.x,\
		visible_rect_size.y /_image_size.y)
	if not _current_img_scale or _current_img_scale != target_scale:
		_current_img_scale = target_scale
		var img_x = _image_size.x * target_scale
		var img_y = _image_size.y * target_scale
		var offset_x = (visible_rect_size.x - img_x) / 2.0
		var offset_y = (visible_rect_size.y - img_y) / 2.0
		sprite.position = Vector2(offset_x, offset_y)
		sprite.apply_scale(Vector2(target_scale, target_scale))
