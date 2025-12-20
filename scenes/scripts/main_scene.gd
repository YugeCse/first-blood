## 主场景组件
class_name MainScene extends Control

## 玩家对象
var player: Player

## HUD显示控件对象
@export
var hud_container: CanvasLayer

@export
var life_container: HBoxContainer

## 玩家生命进度条对象
@export
var player_life_progress_bar: TextureProgressBar

## 玩家场景资源包
@onready
var player_scene_packed = preload('res://sprites/tscns/player.tscn')

func _ready() -> void:
	_create_player_hero(Vector2(0, 50.0)) #创建玩家角色
	GlobalSignals.on_game_over.connect(_on_game_over)
	GlobalSignals.on_player_dead.connect(_on_player_dead)

func _physics_process(_delta: float) -> void:
	if player: #如果玩家还存在
		player_life_progress_bar.value =\
			(player.life_blood / player.life_blood_max) * 100.0
	hud_container.offset.x = absf(get_screen_position().x)

## 游戏结束时的监听方法
func _on_game_over() -> void:
	print('游戏结束了，玩家角色生命已经用完！切换到提示页面！')
	get_tree().change_scene_to_file('res://scenes/tscns/defeat_scene.tscn')

## 玩家角色死亡时的监听方法
func _on_player_dead(location: Vector2) -> void:
	var origin_life_count = GlobalConfigs.player_life_count
	var life_count = clampi(origin_life_count - 1, 0, 999)
	var diff_count = origin_life_count - life_count
	if diff_count == 1: #如果少了一条生命
		var child_count = life_container.get_child_count()
		if child_count > 0: #如果还有子组件，则执行删除
			life_container.remove_child(\
				life_container.get_child(0))
		if player and origin_life_count > 1: #防止结束时的视角变化
			player.queue_free()
			player = null
	GlobalConfigs.player_life_count = life_count
	if life_count <= 0: #生命数目为0
		_on_game_over() #调用游戏借宿的方法
		return
	_create_player_hero(location, true) #创建玩家角色

## 创建玩家角色
func _create_player_hero(\
	location: Vector2,\
	from_sky: bool = false) -> void:
	if from_sky: location.y = 0.0
	if not player:
		player = player_scene_packed.instantiate()
	player.global_position = location
	add_child_to_camera(player) #添加玩家到数据节点
	player_life_progress_bar.value = 100.0 #生命数恢复100%

## 把子节点添加到相机中
func add_child_to_camera(child: Node) -> void: add_child(child)
