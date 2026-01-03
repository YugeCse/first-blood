## 生命数显示视图容器
@tool
class_name LifeMedalBox extends HBoxContainer

## 生命数
@export
var life_count: int = 3

var _medal_texture_width: float = 0.0

var _medal_red_texture_width: float = 0.0

func _ready() -> void:
	_render_medal_life() #渲染生命数勋章数据

func _enter_tree() -> void:
	_render_medal_life() #渲染生命数勋章数据

func _physics_process(_delta: float) -> void:
	_render_medal_life() #渲染生命数勋章数据

## 创建texture-rect对象
func _create_texture2d(is_red: bool = false) -> TextureRect:
	var medal_texture =\
		load('res://assets/ui/ui_medal_life{color}.png'\
			.format({'color': ''  if not is_red else '_red'})) as Texture2D
	if _medal_texture_width == 0.0 and not is_red:
		_medal_texture_width = medal_texture.get_width()
	elif _medal_red_texture_width == 0.0 and is_red:
		_medal_red_texture_width = medal_texture.get_width()
	var ttr = TextureRect.new()
	ttr.set_meta('is_red', is_red)
	ttr.texture = medal_texture
	ttr.stretch_mode = TextureRect.STRETCH_KEEP
	return ttr

## 渲染生命数勋章数据
func _render_medal_life():
	var child_count = get_child_count()
	if child_count == 0: #如果还没有children
		if life_count < 3:
			for i in range(0, life_count - 1):
				add_child(_create_texture2d(false))
		elif life_count == 4:
			for i in range(0, 3):
				add_child(_create_texture2d(false))
		else:
			for i in range(0, 3):
				add_child(_create_texture2d(i == 2))
	else: #如果已经有chilren了
		if life_count > 4:
			var diff_count = 3 - child_count
			if diff_count > 0:
				for i in range(0, diff_count):
					add_child(_create_texture2d(i == diff_count - 1))
			else:
				var last_child = get_child(2)
				if last_child and\
					last_child.has_meta('is_red') and\
					last_child.get_meta('is_red') != true:
					remove_child(last_child)
					add_child(_create_texture2d(true))
		elif life_count == 4:
			var diff_count = 3 - child_count
			if diff_count > 0:
				for i in range(0, diff_count):
					add_child(_create_texture2d(false))
			else:
				var last_child = get_child(2)
				if last_child and\
					last_child.has_meta('is_red') and\
					last_child.get_meta('is_red') == true:
					remove_child(last_child)
					add_child(_create_texture2d(false))
		else:
			var diff_count = life_count - child_count - 1
			if diff_count > 0:
				for i in range(0, diff_count):
					add_child(_create_texture2d(false))
			else:
				for i in range(diff_count, 0, 1):
					remove_child(get_child(child_count - 1))
	if Engine.is_editor_hint(): return
	var total_width = 0.0
	for child in get_children():
		var is_red = child.has_meta('is_red') and\
			child.get_meta('is_red') == true
		total_width += (_medal_texture_width\
			if not is_red else _medal_red_texture_width)
	self.size = Vector2(total_width, 13.0)
