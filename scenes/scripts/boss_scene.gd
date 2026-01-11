extends Node2D

## 玩家对象
@export
var player: Player

## 游戏是否结束，默认：false
var _is_game_over: bool = false

## 视窗设定大小
var _viewport_size = Vector2(416.0, 260.0)

@onready
var _grunt_soilder_timer: Timer =\
	$SubViewportContainer/SubViewport/GruntSoliderTimer

@onready
var boss: Boss = $SubViewportContainer/SubViewport/Boss

@onready
var viewport: SubViewport = $SubViewportContainer/SubViewport

@onready
var viewport_container: SubViewportContainer = $SubViewportContainer

@onready
var life_medal_box: LifeMedalBox =\
	$SubViewportContainer/SubViewport/HudContainer/HeroProfileContainer/LifeMedalBox

@onready
var blood_progress: TextureProgressBar =\
	$SubViewportContainer/SubViewport/HudContainer/HeroProfileContainer/HeroBloodProgressBar

## 玩家打包资源对象
@onready
var player_packed_scene: PackedScene = preload('res://sprites/tscns/player.tscn')

## 敌方士兵打包资源对象
@onready
var grunt_solider_packed_scene: PackedScene = preload('res://sprites/tscns/grunt_soilder.tscn')

func _ready() -> void:
	set_physics_process(true)
	_update_ui_display() #更新UI显示
	get_window().size_changed\
		.connect(_update_ui_display)
	GlobalSignals.on_game_over\
		.connect(_on_game_over)
	GlobalSignals.on_player_dead\
		.connect(_on_player_dead)
	life_medal_box.life_count = GlobalConfigs.player_life_count
	_grunt_soilder_timer\
		.wait_time = randf_range(5.0, 15.0)
	boss.spy_player = player
	boss.on_boss_die.connect(_on_boss_die)
	_grunt_soilder_timer.timeout.connect(_generate_grunt_soilder)
	get_tree().create_timer(3.0).timeout.connect(_generate_grunt_soilder)

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
		#endregion

## 创建玩家
func _create_player(location: Vector2) -> Player:
	var _player = player_packed_scene\
		.instantiate() as Player
	_player.global_position = location
	return _player

## 启动生成红隼士兵的定时器
func _start_generate_grunt_soilder_timer() -> void:
	if not _grunt_soilder_timer: return
	_grunt_soilder_timer\
		.wait_time = randf_range(5.0, 15.0)
	if _grunt_soilder_timer.paused:
		_grunt_soilder_timer.paused = false
	if _grunt_soilder_timer.is_stopped():
		_grunt_soilder_timer.start()

## 停止生成红隼士兵的定时器
func _stop_generate_grunt_soilder_timer() -> void:
	if not _grunt_soilder_timer: return
	if not _grunt_soilder_timer.paused:
		_grunt_soilder_timer.paused = true
	if not _grunt_soilder_timer.is_stopped():
		_grunt_soilder_timer.stop()

## 生成敌方的敌人对象
func _generate_grunt_soilder() -> void:
	_stop_generate_grunt_soilder_timer() #停止生成红隼士兵的定时器
	var count = randi_range(1, 2)
	for i in range(0, count):
		var soilder = grunt_solider_packed_scene\
			.instantiate() as GruntSoilder
		soilder.run_area = _viewport_size +\
			Vector2(randf_range(25.0, 35.0), 0.0)
		soilder.global_position =\
			Vector2(_viewport_size.x + 20.0, _viewport_size.y / 2.0)
		viewport.add_child(soilder) #添加士兵对象
	_start_generate_grunt_soilder_timer() #启动生成红隼士兵的定时器

## boss被玩家消灭
func _on_boss_die() -> void:
	if _grunt_soilder_timer and\
		not _grunt_soilder_timer.is_stopped():
		_grunt_soilder_timer.paused = false
		_grunt_soilder_timer.stop()
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
	if life_count < 0: life_count = 0
	GlobalConfigs.player_life_count = life_count
	if life_count == 0 and not _is_game_over: 
		GlobalSignals.on_game_over.emit() #玩家生命数为0且未标记游戏结束时，执行游戏结束
	life_medal_box.life_count = GlobalConfigs.player_life_count

## 游戏结束了
func _on_game_over() -> void:
	if _is_game_over: return
	_is_game_over = true #标记游戏已经结束
	print('游戏结束啦！😊')
	get_tree().change_scene_to_file('res://scenes/tscns/defeat_scene.tscn')

## 声音播放按钮的操作事件
func _on_music_button_toggled(toggled_on: bool) -> void:
	AudioManager.set_play_sounds(toggled_on)
