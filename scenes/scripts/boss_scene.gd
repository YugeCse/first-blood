extends Node2D

## 玩家对象
@export
var player: Player

## 游戏是否结束，默认：false
var _is_game_over: bool = false

## 视窗设定大小
var _viewport_size = Vector2(416.0, 260.0)

@onready
var boss: Boss = $SubViewportContainer/SubViewport/Boss

@onready
var viewport: SubViewport = $SubViewportContainer/SubViewport

@onready
var viewport_container: SubViewportContainer = $SubViewportContainer

@onready
var life_container: HBoxContainer =\
	$SubViewportContainer/SubViewport/HudContainer/HeroProfileContainer/LifeContainer

@onready
var blood_progress: TextureProgressBar =\
	$SubViewportContainer/SubViewport/HudContainer/HeroProfileContainer/HeroBloodProgressBar

@onready
var player_packed_scene: PackedScene = preload('res://sprites/tscns/player.tscn')

func _ready() -> void:
	set_physics_process(true)
	_update_ui_display() #更新UI显示
	get_window().size_changed\
		.connect(_update_ui_display)
	GlobalSignals.on_game_over\
		.connect(_on_game_over)
	GlobalSignals.on_player_dead\
		.connect(_on_player_dead)
	boss.spy_player = player
	boss.on_boss_die.connect(_on_boss_die)

## 更新UI显示
func _update_ui_display() -> void:
	var visible_rect = get_viewport().get_visible_rect()
	var visible_size = visible_rect.size
	var scaler = minf(visible_size.x / _viewport_size.x,\
		visible_size.y / _viewport_size.y)
	var target_width = _viewport_size.x * scaler
	var target_height = _viewport_size.y * scaler
	var offset_x = (visible_size.x - target_width) /2.0
	var offset_y = (visible_size.y - target_height) / 2.0
	viewport_container.scale = Vector2(scaler, scaler)
	viewport_container.global_position = Vector2(offset_x, offset_y)

func _physics_process(_delta: float) -> void:
	if player: #如果玩家可用
		#region 设置玩家可行走的范围
		player.walk_area_x = viewport_container.size.x
		player.walk_area_y = viewport_container.size.y
		#endregion
		#region 更新血条信息
		blood_progress.value =\
			(player.life_blood / player.life_blood_max) * 100.0
		var life_count = life_container.get_child_count()
		var diff_count = GlobalConfigs.player_life_count - life_count
		if diff_count > 1:
			var texture = TextureRect.new()
			texture.texture =\
				load('res://assets/ui/ui_medal_life.png') as Texture2D
			life_container.add_child(texture)
		elif life_count > 0:
			var last_child = life_container.get_child(0)
			life_container.remove_child(last_child)
		#endregion

## 创建玩家
func _create_player(location: Vector2) -> Player:
	var _player = player_packed_scene.instantiate() as Player
	_player.global_position = location
	return _player

## boss被玩家消灭
func _on_boss_die() -> void:
	print('Boss被消灭！你赢了！')

## 玩家被消灭
func _on_player_dead(location: Vector2) -> void:
	var life_count =\
		GlobalConfigs.player_life_count
	if life_count >= 1:
		life_count = life_count - 1
	if life_count > 0:
		if player: 
			player.free()
			player = null
		player = _create_player(\
			Vector2(location.x, location.y - 60.0))
		viewport.add_child(player)
		if boss and not boss._is_die: #如果boss还存在
			get_tree().create_timer(0.5)\
				.timeout.connect(func(): boss.spy_player = player)
	GlobalConfigs.player_life_count = life_count
	if not _is_game_over: _on_game_over() #游戏结束

## 游戏结束了
func _on_game_over() -> void:
	if not _is_game_over: return
	_is_game_over = true #标记游戏已经结束
	print('游戏结束啦！😊')
