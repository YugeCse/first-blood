## 主场景组件
class_name MainScene extends Control

## 玩家对象
var player: Player

## HUD显示控件对象
@export
var hudContainer: CanvasLayer

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
	hudContainer.offset.x = absf(get_screen_position().x)

## 游戏结束时的监听方法
func _on_game_over() -> void:
	pass

## 玩家角色死亡时的监听方法
func _on_player_dead(location: Vector2) -> void:
	_create_player_hero(location) #创建玩家角色

## 创建玩家角色
func _create_player_hero(location: Vector2) -> void:
	player = player_scene_packed.instantiate()
	player.global_position = location
	add_child_to_camera(player) #添加玩家到数据节点

## 把子节点添加到相机中
func add_child_to_camera(child: Node) -> void: add_child(child)
