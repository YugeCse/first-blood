## 主场景组件
class_name StageForest extends Control

## 玩家对象
var player: Player

## 游戏摇杆
@export
var joystick: VirtualJoystick

## 游戏视窗
@export
var game_viewport: SubViewport

## 游戏视窗容器
@export
var game_viewport_container: SubViewportContainer

## HUD显示控件对象
@export
var hud_container: CanvasLayer

## 玩家生命数容器对象
@export
var life_medal_box: LifeMedalBox

## 道具显示容器对象
@export
var prop_container: HBoxContainer

## 玩家生命进度条对象
@export
var player_life_progress_bar: TextureProgressBar

var _is_attach_stage_tag: bool = false

## 玩家场景资源包
@onready
var player_scene_packed: PackedScene = preload('res://sprites/tscns/player.tscn')

func _ready() -> void:
	get_tree().create_timer(3.0).timeout\
		.connect($HUDContainer/TipMessageContainer.queue_free)
	hud_container.custom_viewport = game_viewport
	if joystick: #如果游戏摇杆可用
		get_tree().root.size_changed\
			.connect(joystick._on_viewport_size_changed)
	_create_player_hero(Vector2(0, 50.0)) #创建玩家角色
	GlobalSignals.on_player_dead.connect(_on_player_dead)
	GlobalSignals.on_player_get_prop.connect(_on_player_get_prop)

func _physics_process(_delta: float) -> void:
	#region 用户生命值显示
	if not player: return #如果玩家不存在，则直接返回
	var life_percent =\
		(player.life_blood / player.life_blood_max) * 100.0
	player_life_progress_bar.value = life_percent #当前声明百分值
	#endregion
	#region 如果到达下一个的触发点, 执行关卡切换
	if player.global_position.x >=\
		GlobalConfigs.DESIGN_MAP_WIDTH - 12.0 and\
		player.is_on_floor(): #如果到达进入下一关的触发点
		if _is_attach_stage_tag: return
		_is_attach_stage_tag = true
		get_tree().change_scene_to_file('res://scenes/tscns/boss_scene.tscn')
	#endregion

## 玩家角色死亡时的监听方法
func _on_player_dead(location: Vector2) -> void:
	#region 处理玩家生命数减少显示
	var origin_life_count = GlobalConfigs.player_life_count
	var life_count = clampi(origin_life_count - 1, 0, 999)
	var diff_count = origin_life_count - life_count
	if diff_count == 1: #如果少了一条生命
		if player and origin_life_count > 1: #防止结束时的视角变化
			player.queue_free()
			player = null
	GlobalConfigs.player_life_count = life_count
	if life_count <= 0: #生命数目为0
		GlobalSignals.on_game_over.emit() #调用游戏结束的方法
		return
	#endregion
	_create_player_hero(location, true) #创建玩家角色
	#region 修改火力类型展示
	var fire_type_ui = _find_player_fire_type_ui_prop()
	if not fire_type_ui:
		var ui = UiPropTextureRect.new()
		ui.type = UiPropTextureRect.PropType.fire_normal
		prop_container.add_child(ui)
	elif fire_type_ui.type != UiPropTextureRect.PropType.fire_normal:
		fire_type_ui.type = UiPropTextureRect.PropType.fire_normal
	#endregion

## 玩家获得道具[br]
## - prop_type: 道具类型
func _on_player_get_prop(prop_type: Prop.PropType) -> void:
	if prop_type == Prop.PropType.nade: #如果是纳豆(食物)
		pass
	elif prop_type == Prop.PropType.ammo: #如果是获取弹药道具
		#region 修改火力类型展示
		var fire_type_ui = _find_player_fire_type_ui_prop()
		if not fire_type_ui:
			var ui = UiPropTextureRect.new()
			ui.type = UiPropTextureRect.PropType.fire_strong
			prop_container.add_child(ui)
		elif fire_type_ui.type != UiPropTextureRect.PropType.fire_strong:
			fire_type_ui.type = UiPropTextureRect.PropType.fire_strong
		#endregion
	elif prop_type == Prop.PropType.crate: #如果是木箱
		pass
	elif prop_type == Prop.PropType.big_crate: #如果是大木箱
		pass

## 创建玩家角色[br]
## - location 创建的位置[br]
## - from_sky 是否是从天而降，默认：false
func _create_player_hero(\
	location: Vector2,\
	from_sky: bool = false) -> void:
	if from_sky: location.y = 0.0
	if not player: #如果玩家已经不存在了，则创建一个
		player = player_scene_packed.instantiate()
	player.z_index = 1000 #玩家的绘制层index
	player.global_position = location
	player.add_child(_create_player_camera()) #添加玩家相机
	add_child(player) #添加玩家到数据节点
	life_medal_box.life_count = GlobalConfigs.player_life_count
	player_life_progress_bar.value = 100.0 #生命数恢复100%

## 创建玩家相机
func _create_player_camera() -> Camera2D:
	var camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2000
	camera.limit_bottom = 210
	camera.limit_smoothed = true
	return camera

## 查找玩家火力类型的显示组件
func _find_player_fire_type_ui_prop() -> UiPropTextureRect:
	var fire_props =\
		[UiPropTextureRect.PropType.fire_strong, UiPropTextureRect.PropType.fire_normal]
	var props = prop_container.get_children()\
		.filter(func(child):\
			return fire_props.any(func(v): return v == (child as UiPropTextureRect).type))
	return props[0] if props.size() >= 1 else null

## 查找玩家火力强度的显示组件
func _find_player_fire_power_ui_prop() -> UiPropTextureRect:
	#TODO 2025.12.25 查找玩家火力展示组件
	return null
