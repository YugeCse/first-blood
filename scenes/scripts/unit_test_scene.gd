@tool
extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var path2d = Path2D.new()
	path2d.curve = _create_bom_road()
	var line2d = draw_curve_with_line2d( _create_bom_road())
	line2d.position = Vector2(200, 200)
	
	line2d.width = 3
	line2d.default_color = Color.YELLOW
	
	line2d.points = path2d.curve.get_baked_points()
	
	#var start_pos = global_position
	#var contrl_pos = _get_bom_high_coord()
	#var dist_x = contrl_pos.x - start_pos.x
	#var final_pos = Vector2(contrl_pos.x + dist_x, start_pos.y)
	#
	## 采样显示
	#var points: PackedVector2Array = []
	#var sample_count = 100
	#for i in range(sample_count + 1):
		#var t = i / float(sample_count)
		## 二次贝塞尔公式
		#var point = (1.0 - t) * (1.0 - t) * start_pos + \
				   #2.0 * (1.0 - t) * t * contrl_pos + \
				   #t * t * final_pos
		#points.append(point)
	#line2d.points = points
	add_child(path2d)
	add_child(line2d)
	print('hello')

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
## 获取爆炸最高点
func _get_bom_high_coord() -> Vector2:
	var d_x = randf_range(15, 60)
	var d_h = randf_range(30, 80)
	var dir = -1 if randi_range(0, 1) == 0 else 1
	return Vector2(global_position.x + dir * d_x, global_position.y - d_h)

func _create_bom_road() -> Curve2D:
	var start_pos = global_position
	var contrl_pos = _get_bom_high_coord()
	var dist_x = contrl_pos.x - start_pos.x
	var final_pos = Vector2(contrl_pos.x + dist_x, start_pos.y)
	var curve = Curve2D.new()
	curve.add_point(start_pos)
	# 中间控制点（二次贝塞尔的控制点）
	# 计算控制柄，使点成为三次贝塞尔的中间点
	var in_vec = (contrl_pos - start_pos) * 0.5
	var out_vec = (final_pos - contrl_pos) * 0.5
	
	curve.add_point(contrl_pos, -in_vec, out_vec)
	
	curve.add_point(final_pos)
	prints(start_pos, contrl_pos, final_pos)
	return curve

func draw_curve_with_line2d(curve: Curve2D) -> Line2D:
	var line2d = Line2D.new()
	line2d.width = 2.0
	line2d.default_color = Color.RED
	
	# 采样曲线点
	var points: PackedVector2Array = curve.get_baked_points()
	line2d.points = points
	return line2d
