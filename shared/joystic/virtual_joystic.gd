extends CanvasLayer
class_name VirtualJoystick

# 方向枚举
enum JoystickDirection {
	RIGHT,      # 右
	DOWN_RIGHT, # 右下
	DOWN,       # 下
	DOWN_LEFT,  # 左下
	LEFT,       # 左
	UP_LEFT,    # 左上
	UP,         # 上
	UP_RIGHT,   # 右上
	CENTER      # 中心
}

# 方向名称映射（常量）
const DIRECTION_NAMES_CN = {
	JoystickDirection.RIGHT: "右",
	JoystickDirection.DOWN_RIGHT: "右下", 
	JoystickDirection.DOWN: "下",
	JoystickDirection.DOWN_LEFT: "左下",
	JoystickDirection.LEFT: "左",
	JoystickDirection.UP_LEFT: "左上",
	JoystickDirection.UP: "上",
	JoystickDirection.UP_RIGHT: "右上",
	JoystickDirection.CENTER: "中心"
}

# 导出属性
@export var joystick_radius: float = 75.0
@export var handle_radius: float = 30.0
@export var deadzone: float = 0.2
@export var dynamic_joystick: bool = false
@export var visible_when_inactive: bool = false
@export var input_area_size: Vector2 = Vector2(300, 200)
@export var snap_to_8_directions: bool = true
@export var simulate_keyboard: bool = true  # 是否模拟键盘按键

# 颜色
@export var bg_color: Color = Color(1, 1, 1, 0.3)
@export var border_color: Color = Color(1, 1, 1, 0.5)
@export var handle_color: Color = Color(1, 1, 1, 0.8)
@export var handle_active_color: Color = Color(0.8, 0.9, 1.0, 0.9)
@export var input_area_color: Color = Color(0.5, 0.5, 0.5, 0.1)

@export var border_width: float = 3.0

# 内部变量
var is_pressed: bool = false
var touch_id: int = -1
var joystick_pos: Vector2
var input_vector: Vector2 = Vector2.ZERO
var current_direction: JoystickDirection = JoystickDirection.CENTER
var last_direction: JoystickDirection = JoystickDirection.CENTER
var pressed_actions: Array[String] = []  # 当前按下的动作

@onready var container: Control = $Container
@onready var input_area: ColorRect = $InputArea

func _ready():
	print("虚拟摇杆初始化...")
	setup_joystick()
	setup_input_area()
	
	if not visible_when_inactive:
		container.visible = false

func setup_joystick():
	container.custom_minimum_size = Vector2(joystick_radius * 2, joystick_radius * 2)
	container.size = Vector2(joystick_radius * 2, joystick_radius * 2)
	
	create_joystick_background()
	create_joystick_handle()
	
	if not dynamic_joystick:
		var viewport_size = get_viewport().get_visible_rect().size
		container.position = Vector2(50, viewport_size.y - joystick_radius * 2 - 50)

func setup_input_area():
	var viewport_size = get_viewport().get_visible_rect().size
	
	input_area.size = input_area_size
	if dynamic_joystick:
		input_area.position = Vector2(0, viewport_size.y - input_area_size.y)
	else:
		input_area.position = container.position - Vector2(
			(input_area_size.x - joystick_radius * 2) * 0.5,
			(input_area_size.y - joystick_radius * 2) * 0.5
		)
	
	input_area.color = input_area_color

func create_joystick_background():
	var background = ColorRect.new()
	background.name = "Background"
	background.color = bg_color
	background.custom_minimum_size = Vector2(joystick_radius * 2, joystick_radius * 2)
	background.size = Vector2(joystick_radius * 2, joystick_radius * 2)
	container.add_child(background)
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = create_circle_shader()
	shader_material.set_shader_parameter("bg_color", bg_color)
	shader_material.set_shader_parameter("border_color", border_color)
	shader_material.set_shader_parameter("border_width", border_width / (joystick_radius * 2))
	shader_material.set_shader_parameter("radius", 0.5)
	background.material = shader_material

func create_joystick_handle():
	var handle = ColorRect.new()
	handle.name = "Handle"
	handle.color = handle_color
	handle.custom_minimum_size = Vector2(handle_radius * 2, handle_radius * 2)
	handle.size = Vector2(handle_radius * 2, handle_radius * 2)
	
	var center_x = joystick_radius - handle_radius
	var center_y = joystick_radius - handle_radius
	handle.position = Vector2(center_x, center_y)
	
	container.add_child(handle)
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = create_circle_shader()
	shader_material.set_shader_parameter("bg_color", handle_color)
	shader_material.set_shader_parameter("border_color", border_color)
	shader_material.set_shader_parameter("border_width", border_width * 0.5 / (handle_radius * 2))
	shader_material.set_shader_parameter("radius", 0.5)
	handle.material = shader_material

func create_circle_shader() -> Shader:
	var shader_code = """
shader_type canvas_item;
uniform vec4 bg_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float border_width = 0.05;
uniform float radius = 0.5;
void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float distance_from_center = distance(UV, center);
    if (distance_from_center <= radius) {
        if (distance_from_center <= radius - border_width) {
            COLOR = bg_color;
        } else {
            COLOR = border_color;
        }
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
"""
	var shader = Shader.new()
	shader.code = shader_code
	return shader

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			var touch_pos = event.position
			var input_area_rect = Rect2(input_area.global_position, input_area.size)
			
			if dynamic_joystick or input_area_rect.has_point(touch_pos):
				touch_id = event.index
				is_pressed = true
				
				if dynamic_joystick:
					container.position = touch_pos - Vector2(joystick_radius, joystick_radius)
					container.visible = true
				elif not visible_when_inactive:
					container.visible = true
				
				joystick_pos = container.global_position + Vector2(joystick_radius, joystick_radius)
				update_joystick(touch_pos)
				
		elif not event.pressed and event.index == touch_id:
			release_joystick()
			
	elif event is InputEventScreenDrag and event.index == touch_id:
		update_joystick(event.position)

func update_joystick(touch_position: Vector2):
	if not is_pressed:
		return
	
	var delta = touch_position - joystick_pos
	var distance = delta.length()
	var max_distance = joystick_radius - handle_radius
	
	if distance > max_distance:
		delta = delta.normalized() * max_distance
		distance = max_distance
	
	input_vector = Vector2.ZERO
	var new_direction = JoystickDirection.CENTER
	
	if distance > deadzone * max_distance:
		input_vector = delta.normalized()
		var strength = (distance - deadzone * max_distance) / (max_distance * (1 - deadzone))
		input_vector *= strength
		
		if snap_to_8_directions:
			input_vector = get_8_direction_vector(input_vector)
			new_direction = get_direction_from_vector(input_vector)
		else:
			new_direction = get_direction_from_angle(input_vector.angle())
	
	# 更新手柄位置
	update_handle_position(delta)
	update_handle_color()
	
	# 处理方向变化和按键模拟
	if new_direction != current_direction:
		handle_direction_change(new_direction)
		current_direction = new_direction

func get_8_direction_vector(vector: Vector2) -> Vector2:
	if vector.length() < 0.01:
		return Vector2.ZERO
	
	var angle = atan2(vector.y, vector.x)
	if angle < 0:
		angle += TAU
	
	var angle_step = TAU / 8.0
	var nearest_sector = round(angle / angle_step)
	var snapped_angle = nearest_sector * angle_step
	
	return Vector2(cos(snapped_angle), sin(snapped_angle)) * vector.length()

func get_direction_from_vector(vector: Vector2) -> JoystickDirection:
	if vector.length() < 0.1:
		return JoystickDirection.CENTER
	
	var angle = atan2(vector.y, vector.x)
	if angle < 0:
		angle += TAU
	
	var index = int(round(angle / (TAU / 8))) % 8
	
	match index:
		0: return JoystickDirection.RIGHT
		1: return JoystickDirection.DOWN_RIGHT
		2: return JoystickDirection.DOWN
		3: return JoystickDirection.DOWN_LEFT
		4: return JoystickDirection.LEFT
		5: return JoystickDirection.UP_LEFT
		6: return JoystickDirection.UP
		7: return JoystickDirection.UP_RIGHT
		_: return JoystickDirection.CENTER

func get_direction_from_angle(angle: float) -> JoystickDirection:
	if angle < 0:
		angle += TAU
	
	var normalized_angle = fposmod(angle, TAU)
	var angle_step = TAU / 8.0
	var nearest_sector = round(normalized_angle / angle_step) % 8
	
	match nearest_sector:
		0: return JoystickDirection.RIGHT
		1: return JoystickDirection.DOWN_RIGHT
		2: return JoystickDirection.DOWN
		3: return JoystickDirection.DOWN_LEFT
		4: return JoystickDirection.LEFT
		5: return JoystickDirection.UP_LEFT
		6: return JoystickDirection.UP
		7: return JoystickDirection.UP_RIGHT
		_: return JoystickDirection.CENTER

func handle_direction_change(new_direction: JoystickDirection):
	# 释放旧方向的按键
	release_direction_keys(last_direction)
	
	# 按下新方向的按键
	if simulate_keyboard and input_vector.length() > 0.3:
		press_direction_keys(new_direction)
		last_direction = new_direction
	else:
		# 强度不足，不触发按键
		last_direction = JoystickDirection.CENTER

func get_actions_for_direction(direction: JoystickDirection) -> Array[StringName]:
	# 返回对应方向的按键动作
	match direction:
		JoystickDirection.RIGHT:
			return [&"ui_right"]
		JoystickDirection.DOWN_RIGHT:
			return [&"ui_right", &"ui_down"]  # 同时按下两个键！
		JoystickDirection.DOWN:
			return [&"ui_down"]
		JoystickDirection.DOWN_LEFT:
			return [&"ui_left", &"ui_down"]  # 同时按下两个键！
		JoystickDirection.LEFT:
			return [&"ui_left"]
		JoystickDirection.UP_LEFT:
			return [&"ui_left", &"ui_up"]    # 同时按下两个键！
		JoystickDirection.UP:
			return [&"ui_up"]
		JoystickDirection.UP_RIGHT:
			return [&"ui_right", &"ui_up"]   # 同时按下两个键！
		_:
			return []

func press_direction_keys(direction: JoystickDirection):
	var actions = get_actions_for_direction(direction)
	for action in actions:
		if not action in pressed_actions:
			Input.action_press(action)  # 触发按键按下
			pressed_actions.append(action)
			print("按下按键:", action)

func release_direction_keys(direction: JoystickDirection):
	var actions = get_actions_for_direction(direction)
	for action in actions:
		if action in pressed_actions:
			Input.action_release(action)  # 触发按键释放
			pressed_actions.erase(action)
			print("释放按键:", action)

func release_all_keys():
	for action in pressed_actions.duplicate():
		Input.action_release(action)
		pressed_actions.erase(action)
		print("释放所有按键:", action)

func update_handle_position(delta: Vector2):
	var handle = container.get_node("Handle")
	if handle:
		var center_x = joystick_radius - handle_radius
		var center_y = joystick_radius - handle_radius
		handle.position = Vector2(center_x, center_y) + delta

func update_handle_color():
	var handle = container.get_node("Handle")
	if handle:
		var shader_material = handle.material as ShaderMaterial
		if shader_material:
			if is_pressed and input_vector.length() > 0.1:
				shader_material.set_shader_parameter("bg_color", handle_active_color)
			else:
				shader_material.set_shader_parameter("bg_color", handle_color)

func reset_handle_position():
	var handle = container.get_node("Handle")
	if handle:
		var center_x = joystick_radius - handle_radius
		var center_y = joystick_radius - handle_radius
		handle.position = Vector2(center_x, center_y)

func release_joystick():
	touch_id = -1
	is_pressed = false
	
	# 释放所有按键
	release_all_keys()
	
	last_direction = JoystickDirection.CENTER
	current_direction = JoystickDirection.CENTER
	input_vector = Vector2.ZERO
	
	reset_handle_position()
	
	var handle = container.get_node("Handle")
	if handle:
		var shader_material = handle.material as ShaderMaterial
		if shader_material:
			shader_material.set_shader_parameter("bg_color", handle_color)
	
	if not visible_when_inactive:
		container.visible = false

func _process(_delta):
	# 调试信息
	if Input.is_action_just_pressed("ui_accept"):
		var direction_name = DIRECTION_NAMES_CN.get(current_direction, "未知")
		print("摇杆状态:")
		print("  方向:", direction_name)
		print("  向量:", input_vector)
		print("  强度:", input_vector.length())
		print("  按下按键:", pressed_actions)
	
	# PC鼠标测试
	if not OS.has_feature("mobile"):
		handle_mouse_input()

func handle_mouse_input():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and touch_id == -1:
		var mouse_event = InputEventScreenTouch.new()
		mouse_event.pressed = true
		mouse_event.position = get_viewport().get_mouse_position()
		mouse_event.index = 0
		_input(mouse_event)
	elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and touch_id == 0:
		var mouse_event = InputEventScreenTouch.new()
		mouse_event.pressed = false
		mouse_event.index = 0
		_input(mouse_event)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and touch_id == 0:
		var mouse_event = InputEventScreenDrag.new()
		mouse_event.position = get_viewport().get_mouse_position()
		mouse_event.index = 0
		_input(mouse_event)

func _on_viewport_size_changed():
	if is_inside_tree() and not dynamic_joystick:
		var viewport_size = get_viewport().get_visible_rect().size
		container.position = Vector2(50, viewport_size.y - joystick_radius * 2 - 50)
		setup_input_area()

# 公共方法
func get_direction() -> Vector2:
	return input_vector

func get_direction_enum() -> JoystickDirection:
	return current_direction

func get_direction_name() -> String:
	return DIRECTION_NAMES_CN.get(current_direction, "未知")

func is_active() -> bool:
	return is_pressed
