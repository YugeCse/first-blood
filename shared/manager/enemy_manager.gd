## 敌人管理器
class_name EnemyManager extends Node2D

## 要绑定视窗组件
@export
var factory_view: Control

## 敌人地图层
@export
var enemy_map_layer: TileMapLayer

@export
var drop_system: DropSystem

## 炮台场景资源
@onready
var turret_scene_packed = preload('res://sprites/tscns/turret.tscn')

## 敌人场景资源
@onready
var grunt_scene_packed = preload('res://sprites/tscns/grunt.tscn')

func _ready() -> void:
	set_process(true)
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	var visible_rect = _get_visible_rect()
	_create_enemies_from_map_tile_layer(visible_rect)
	_handle_enemy_state_in_viewport(visible_rect) #处理视窗范围内的敌人状态

## 获取可见范围的矩形信息
func _get_visible_rect() -> Rect2:
	var viewport_scale = get_viewport().get_parent().scale
	var target_scale = minf(viewport_scale.x, viewport_scale.y)
	var screen_position =\
		factory_view.get_screen_position() / target_scale
	var visible_rect = get_viewport().get_visible_rect()
	var visible_size = visible_rect.size * target_scale
	var active_margin = visible_size.x / 3.0 #边界处理
	var limit_min_x = (absf(screen_position.x) - active_margin)
	var target_size = visible_size + Vector2(active_margin * 2.0, 0.0)
	return Rect2(Vector2(limit_min_x, 0), target_size)

## 处理视窗范围内的敌人状态
func _handle_enemy_state_in_viewport(visible_rect: Rect2):
	if not factory_view: return #如果没有配置视窗，直接返回
	var enemy_nodes = get_tree().get_nodes_in_group('Enemy')
	if not enemy_nodes or enemy_nodes.is_empty(): return
	for enemy_node in enemy_nodes:
		var in_viewport = visible_rect\
			.has_point(enemy_node.global_position)
		if enemy_node is Turret: #设置炮台状态
			var turret = enemy_node as Turret
			turret.set_active(in_viewport)
		elif enemy_node is Grunt: #设置敌人的状态
			var enemy = enemy_node as Grunt
			enemy.set_active(in_viewport)

## 从敌人地图层创建敌人，限定于可见区域
func _create_enemies_from_map_tile_layer(visible_rect: Rect2):
	if not enemy_map_layer: return
	var cell_coords = enemy_map_layer.get_used_cells()
	if not cell_coords or cell_coords.is_empty(): return
	for cell_coord in cell_coords:
		var cell_local_pos = enemy_map_layer.map_to_local(cell_coord)
		var cell_global_pos = enemy_map_layer.to_global(cell_local_pos)
		if not visible_rect.has_point(cell_global_pos): 
			continue #如果不在可是区域，就不创建
		var data: TileData = enemy_map_layer.get_cell_tile_data(cell_coord)
		match data.get_custom_data('Type'): #匹配数据类型
			'Grunt': #敌人
				add_child(_create_grunt(cell_global_pos, data))
			'Turret': #炮台
				add_child(_create_turret(cell_global_pos, data))
		enemy_map_layer.erase_cell(cell_coord) #擦除这个表格数据

## 创建炮台[br]
## - location 创建位置，全局的
## - data 创建对象依赖的数据
func _create_turret(location: Vector2, data: TileData) -> Turret:
	var turret = turret_scene_packed.instantiate() as Turret
	turret.global_position = location
	if data.has_custom_data('SpyRadius'): #如果有巡逻距离
		turret.spy_radius = data.get_custom_data('SpyRadius')
	return turret

## 创建敌人[br]
## - location 创建位置，全局的
## - data 创建对象依赖的数据
func _create_grunt(location: Vector2, data: TileData) -> Node2D:
	var enemy = grunt_scene_packed.instantiate() as Grunt
	enemy.drop_system = drop_system
	var support_patrol = data.has_custom_data('PatrolAvailable')
	if support_patrol: #如果支持巡逻模式
		var curve = Curve2D.new()
		var patrol_target = data.get_custom_data('PatrolCenterIPos')
		if patrol_target.x == 0.0: 
			#这里对没有巡逻距离的做一个纠正行为
			patrol_target.x = randf_range(-10.0, -25.0)
		curve.add_point(data.get_custom_data('PatrolStartPos'))
		curve.add_point(patrol_target)
		curve.add_point(data.get_custom_data('PatrolCenterOPos'))
		curve.add_point(data.get_custom_data('PatrolEndPos'))
		var path2d = Path2D.new()
		path2d.curve = curve
		path2d.global_position = location
		var path_follow = PathFollow2D.new()
		path_follow.rotates = false
		path_follow.progress_ratio =\
			clampf(data.get_custom_data('PatrolProgressRatio'), 0, 1.0)
		path2d.add_child(path_follow)
		add_child(path2d)
		enemy.patrol_path = path2d
		enemy.patrol_path_follow = path_follow
		path_follow.add_child(enemy)
		return path2d
	enemy.global_position = location
	return enemy
	
