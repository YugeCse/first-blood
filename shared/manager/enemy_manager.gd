## 敌人管理器
class_name EnemyManager extends Node

@export
var viewport: Control

func _physics_process(_delta: float) -> void:
	if not viewport: return
	var screen_position = viewport.get_screen_position()
	var visible_rect = get_viewport().get_visible_rect()
	var limit_min_x = screen_position.x - 120.0
	var target_rect = Rect2(Vector2(limit_min_x, 0),\
		visible_rect.size + Vector2(120, 0))
	var enemy_nodes = get_tree().get_nodes_in_group('Enemy')
	if not enemy_nodes or enemy_nodes.is_empty(): return
	for enemy_node in enemy_nodes:
		if enemy_node is Turret:
			var turret = enemy_node as Turret
			if target_rect.has_point(turret.global_position):
				turret.set_active(true)
			else:
				print('没有激活A')
				turret.set_active(false)
		elif enemy_node is Enemy:
			var enemy = enemy_node as Enemy
			if target_rect.has_point(enemy.global_position):
				enemy.set_active(true)
			else: 
				print('没有激活B')
				enemy.set_active(false)
