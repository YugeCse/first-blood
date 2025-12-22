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

# 方向名称映射
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
@export var simulate_keyboard: bool = true
@export var full_screen_touch: bool = true  # 是否全屏触摸

# 按钮设置
@export_group("按钮设置")
@export var button_size: Vector2 = Vector2(80, 80)  # 按钮大小
@export var button_margin: float = 20.0              # 按钮间距
@export var button_alpha: float = 0.7                # 按钮透明度
@export var button_active_alpha: float = 1.0         # 按下时透明度

# 按钮颜色
@export var jump_button_color: Color = Color(0.2, 0.8, 0.2)  # 绿色
@export var shoot_button_color: Color = Color(0.8, 0.2, 0.2)  # 红色
@export var button_border_color: Color = Color(1, 1, 1, 0.5)  # 按钮边框颜色
@export var button_border_width: float = 3.0

# 摇杆颜色
@export_group("摇杆颜色")
@export var bg_color: Color = Color(1, 1, 1, 0.3)
@export var border_color: Color = Color(1, 1, 1, 0.5)
@export var handle_color: Color = Color(1, 1, 1, 0.8)
@export var handle_active_color: Color = Color(0.8, 0.9, 1.0, 0.9)
@export var input_area_color: Color = Color(0.5, 0.5, 0.5, 0.1)
@export var border_width: float = 3.0

# 按键映射
@export_group("按键映射")
@export var jump_action: String = "ui_accept"      # 跳跃动作
@export var shoot_action: String = "ui_select"     # 射击动作

# 信号
#signal joystick_moved(direction: Vector2, direction_enum: JoystickDirection)
#signal joystick_released
#signal joystick_pressed
signal button_pressed(button_name: String)  # 按钮按下信号
signal button_released(button_name: String) # 按钮释放信号
signal jump_pressed                         # 跳跃按下
signal jump_released                        # 跳跃释放
signal shoot_pressed                        # 射击按下
signal shoot_released                       # 射击释放

# 内部变量
var is_pressed: bool = false
var touch_id: int = -1
var joystick_pos: Vector2
var input_vector: Vector2 = Vector2.ZERO
var current_direction: JoystickDirection = JoystickDirection.CENTER
var last_direction: JoystickDirection = JoystickDirection.CENTER
var pressed_actions: Array[String] = []  # 当前按下的动作

# 按钮状态
var is_jump_pressed: bool = false
var is_shoot_pressed: bool = false
var jump_touch_id: int = -1
var shoot_touch_id: int = -1
var last_mouse_state: bool = false  # 记录上次鼠标状态

# 节点引用
@onready var container: Control = $Container
@onready var input_area: ColorRect = $InputArea
@onready var right_buttons: Control = $RightButtons
@onready var jump_button: ColorRect = $RightButtons/JumpButtonArea
@onready var shoot_button: ColorRect = $RightButtons/ShootButtonArea
@onready var full_screen_area: ColorRect = $FullScreenArea  # 新增全屏触摸区域

func _ready():
	print("虚拟控制器初始化...")
	print("跳跃按键:", jump_action)
	print("射击按键:", shoot_action)
	print("全屏触摸:", full_screen_touch)
	
	setup_joystick()
	setup_input_area()
	setup_buttons()
	setup_full_screen_area()
	
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

func setup_full_screen_area():
	# 设置全屏触摸区域
	var viewport_size = get_viewport().get_visible_rect().size
	full_screen_area.position = Vector2.ZERO
	full_screen_area.size = viewport_size
	full_screen_area.color = Color(0, 0, 0, 0)  # 完全透明
	full_screen_area.mouse_filter = Control.MOUSE_FILTER_STOP
	
	print("全屏触摸区域大小:", viewport_size)

func setup_buttons():
	var viewport_size = get_viewport().get_visible_rect().size
	
	right_buttons.position = Vector2(
		viewport_size.x - button_size.x * 2 - button_margin * 2,
		viewport_size.y - button_size.y - button_margin
	)
	
	setup_colorrect_button(jump_button, jump_button_color, "跳")
	shoot_button.position = Vector2(button_size.x + button_margin, 0)
	setup_colorrect_button(shoot_button, shoot_button_color, "射")
	
	print("按钮已初始化")

func setup_colorrect_button(button: ColorRect, color: Color, label_text: String):
	button.custom_minimum_size = button_size
	button.size = button_size
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = create_button_shader()
	shader_material.set_shader_parameter("bg_color", color)
	shader_material.set_shader_parameter("border_color", button_border_color)
	shader_material.set_shader_parameter("border_width", button_border_width / button_size.x)
	shader_material.set_shader_parameter("radius", 0.5)
	
	button.material = shader_material
	button.modulate = Color(1, 1, 1, button_alpha)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var label = Label.new()
	label.name = "ButtonLabel"
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	
	button.add_child(label)

func create_button_shader() -> Shader:
	var shader_code = """
shader_type canvas_item;
uniform vec4 bg_color : source_color = vec4(0.2, 0.8, 0.2, 0.7);
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
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
		handle_touch_event(event)
	elif event is InputEventScreenDrag and event.index == touch_id:
		handle_drag_event(event)

func handle_touch_event(event: InputEventScreenTouch):
	var touch_pos = event.position
	
	# 检查是否在按钮区域
	if event.pressed:
		if is_point_in_colorrect(touch_pos, jump_button) and jump_touch_id == -1:
			jump_touch_id = event.index
			_on_button_down(jump_button, "jump")
			return
		elif is_point_in_colorrect(touch_pos, shoot_button) and shoot_touch_id == -1:
			shoot_touch_id = event.index
			_on_button_down(shoot_button, "shoot")
			return
	
	# 检查是否在全屏触摸区域
	if full_screen_touch and event.pressed and touch_id == -1:
		# 全屏模式：任意位置都可以触发摇杆
		touch_id = event.index
		is_pressed = true
		
		if dynamic_joystick:
			# 动态摇杆：在触摸位置显示
			container.position = touch_pos - Vector2(joystick_radius, joystick_radius)
			container.visible = true
		elif not visible_when_inactive:
			container.visible = true
		
		joystick_pos = container.global_position + Vector2(joystick_radius, joystick_radius)
		update_joystick(touch_pos)
		
	# 原有限制区域逻辑（保留用于非全屏模式）
	elif not full_screen_touch and event.pressed and touch_id == -1:
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
	
	# 触摸释放
	elif not event.pressed:
		if event.index == jump_touch_id:
			jump_touch_id = -1
			_on_button_up(jump_button, "jump")
		elif event.index == shoot_touch_id:
			shoot_touch_id = -1
			_on_button_up(shoot_button, "shoot")
		elif event.index == touch_id:
			release_joystick()

func is_point_in_colorrect(point: Vector2, colorrect: ColorRect) -> bool:
	var rect = Rect2(colorrect.global_position, colorrect.size)
	return rect.has_point(point)

func handle_drag_event(event: InputEventScreenDrag):
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
	
	update_handle_position(delta)
	update_handle_color()
	
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
	release_direction_keys(last_direction)
	
	if simulate_keyboard and input_vector.length() > 0.3:
		press_direction_keys(new_direction)
		last_direction = new_direction
	else:
		last_direction = JoystickDirection.CENTER

func get_actions_for_direction(direction: JoystickDirection) -> Array[StringName]:
	match direction:
		JoystickDirection.RIGHT:
			return [&"ui_right"]
		JoystickDirection.DOWN_RIGHT:
			return [&"ui_right", &"ui_down"]
		JoystickDirection.DOWN:
			return [&"ui_down"]
		JoystickDirection.DOWN_LEFT:
			return [&"ui_left", &"ui_down"]
		JoystickDirection.LEFT:
			return [&"ui_left"]
		JoystickDirection.UP_LEFT:
			return [&"ui_left", &"ui_up"]
		JoystickDirection.UP:
			return [&"ui_up"]
		JoystickDirection.UP_RIGHT:
			return [&"ui_right", &"ui_up"]
		_:
			return []

func press_direction_keys(direction: JoystickDirection):
	var actions = get_actions_for_direction(direction)
	for action in actions:
		if not action in pressed_actions:
			Input.action_press(action)
			pressed_actions.append(action)

func release_direction_keys(direction: JoystickDirection):
	var actions = get_actions_for_direction(direction)
	for action in actions:
		if action in pressed_actions:
			Input.action_release(action)
			pressed_actions.erase(action)

func release_all_keys():
	for action in pressed_actions.duplicate():
		Input.action_release(action)
		pressed_actions.erase(action)

func _on_button_down(button: ColorRect, button_name: String):
	button.modulate = Color(1, 1, 1, button_active_alpha)
	
	var shader_material = button.material as ShaderMaterial
	if shader_material:
		var current_color = shader_material.get_shader_parameter("bg_color")
		shader_material.set_shader_parameter("bg_color", current_color * 1.2)
	
	if button_name == "jump":
		is_jump_pressed = true
		Input.action_press(jump_action)
		button_pressed.emit("jump")
		jump_pressed.emit()
	elif button_name == "shoot":
		is_shoot_pressed = true
		Input.action_press(shoot_action)
		button_pressed.emit("shoot")
		shoot_pressed.emit()

func _on_button_up(button: ColorRect, button_name: String):
	button.modulate = Color(1, 1, 1, button_alpha)
	
	var shader_material = button.material as ShaderMaterial
	if shader_material:
		if button_name == "jump":
			shader_material.set_shader_parameter("bg_color", jump_button_color)
		elif button_name == "shoot":
			shader_material.set_shader_parameter("bg_color", shoot_button_color)
	
	if button_name == "jump":
		is_jump_pressed = false
		Input.action_release(jump_action)
		button_released.emit("jump")
		jump_released.emit()
	elif button_name == "shoot":
		is_shoot_pressed = false
		Input.action_release(shoot_action)
		button_released.emit("shoot")
		shoot_released.emit()

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
	if Input.is_action_just_pressed("ui_cancel"):
		var direction_name = DIRECTION_NAMES_CN.get(current_direction, "未知")
		print("=== 虚拟控制器状态 ===")
		print("摇杆方向:", direction_name)
		print("摇杆向量:", input_vector)
		print("跳跃按钮:", is_jump_pressed)
		print("射击按钮:", is_shoot_pressed)
		print("全屏触摸:", full_screen_touch)
	
	if not OS.has_feature("mobile"):
		handle_mouse_input()

func handle_mouse_input():
	var mouse_pos = get_viewport().get_mouse_position()
	var current_mouse_state = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	# 检查鼠标是否在按钮上
	var mouse_over_jump = is_point_in_colorrect(mouse_pos, jump_button)
	var mouse_over_shoot = is_point_in_colorrect(mouse_pos, shoot_button)
	
	# 鼠标按下处理
	if current_mouse_state and not last_mouse_state:
		if mouse_over_jump and not is_jump_pressed:
			_on_button_down(jump_button, "jump")
		elif mouse_over_shoot and not is_shoot_pressed:
			_on_button_down(shoot_button, "shoot")
	
	# 鼠标释放处理
	elif not current_mouse_state and last_mouse_state:
		if is_jump_pressed and (not mouse_over_jump or not current_mouse_state):
			_on_button_up(jump_button, "jump")
		if is_shoot_pressed and (not mouse_over_shoot or not current_mouse_state):
			_on_button_up(shoot_button, "shoot")
	
	# 摇杆的鼠标处理
	if current_mouse_state and touch_id == -1:
		# 在PC上，只有鼠标不在按钮区域时才触发摇杆
		if not mouse_over_jump and not mouse_over_shoot:
			var mouse_event = InputEventScreenTouch.new()
			mouse_event.pressed = true
			mouse_event.position = mouse_pos
			mouse_event.index = 0
			handle_touch_event(mouse_event)
	elif not current_mouse_state and touch_id == 0:
		var mouse_event = InputEventScreenTouch.new()
		mouse_event.pressed = false
		mouse_event.index = 0
		handle_touch_event(mouse_event)
	elif current_mouse_state and touch_id == 0:
		var mouse_event = InputEventScreenDrag.new()
		mouse_event.position = mouse_pos
		mouse_event.index = 0
		handle_drag_event(mouse_event)
	
	last_mouse_state = current_mouse_state

func _on_viewport_size_changed():
	if is_inside_tree():
		var viewport_size = get_viewport().get_visible_rect().size
		
		if not dynamic_joystick:
			container.position = Vector2(50, viewport_size.y - joystick_radius * 2 - 50)
		
		setup_input_area()
		setup_buttons()
		setup_full_screen_area()

func get_direction() -> Vector2:
	return input_vector

func get_direction_enum() -> JoystickDirection:
	return current_direction

func get_direction_name() -> String:
	return DIRECTION_NAMES_CN.get(current_direction, "未知")

func is_active() -> bool:
	return is_pressed

func is_jump_active() -> bool:
	return is_jump_pressed

func is_shoot_active() -> bool:
	return is_shoot_pressed
