## 主场景组件
class_name StageForest extends Control

## 玩家对象
var player: Player

## 是否调用了game-over
var is_game_over: bool = false

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
var life_container: HBoxContainer

## 玩家生命进度条对象
@export
var player_life_progress_bar: TextureProgressBar

## 玩家场景资源包
@onready
var player_scene_packed = preload('res://sprites/tscns/player.tscn')

func _ready() -> void:
	#joystick.visible = true
	var is_run_in_mobilde =\
		OS.get_name() in ['Android', 'iOS']
	joystick.visible = is_run_in_mobilde
	#joystick.shoot_pressed\
		#.connect(func(): Input.action_press(&'ui_shoot'))
	#joystick.shoot_released\
		#.connect(func(): Input.action_release(&'ui_shoot'))
	#joystick.jump_pressed\
		#.connect(func(): Input.action_press(&'ui_jump'))
	#joystick.jump_released\
		#.connect(func(): Input.action_release(&'ui_jump'))
	hud_container.custom_viewport = game_viewport
	get_tree().root.size_changed\
		.connect(joystick._on_viewport_size_changed)
	_create_player_hero(Vector2(0, 50.0)) #创建玩家角色
	GlobalSignals.on_game_over.connect(_on_game_over)
	GlobalSignals.on_player_dead.connect(_on_player_dead)

func _physics_process(_delta: float) -> void:
	#region 用户生命值显示
	if not player: return #如果玩家不存在，则直接返回
	var life_percent =\
		(player.life_blood / player.life_blood_max) * 100.0
	player_life_progress_bar.value = life_percent #当前声明百分值
	#endregion

## 游戏结束时的监听方法
func _on_game_over() -> void:
	if is_game_over:
		return #已经调用过game_over操作了
	is_game_over = true #标记游戏已经结束
	print('游戏结束了，玩家角色生命已经用完！切换到defeat页面！')
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file('res://scenes/tscns/defeat_scene.tscn')

## 玩家角色死亡时的监听方法
func _on_player_dead(location: Vector2) -> void:
	var origin_life_count = GlobalConfigs.player_life_count
	var life_count = clampi(origin_life_count - 1, 0, 999)
	var diff_count = origin_life_count - life_count
	if diff_count == 1: #如果少了一条生命
		if player and origin_life_count > 1: #防止结束时的视角变化
			player.queue_free()
			player = null
	GlobalConfigs.player_life_count = life_count
	if life_count <= 0: #生命数目为0
		_on_game_over() #调用游戏结束的方法
		return
	_create_player_hero(location, true) #创建玩家角色

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
	add_child(player) #添加玩家到数据节点
	var child_count = life_container.get_child_count()
	if child_count > 0: #如果还有子组件，则执行删除
		life_container.remove_child(\
			life_container.get_child(0))
	player_life_progress_bar.value = 100.0 #生命数恢复100%

## 添加1个用户生命值
func _add_player_life() -> void:
	pass
	#var child_count = life_container.get_child_count()
	#if child_count < 3: #如果还有子组件，则执行删除
		#var texture = Texture2D.new()
		#texture.resource_path = 'res://'
		#var life_texture_rect = TextureRect.new()
		#life_texture_rect.texture = texture
		#life_container.add_child()
