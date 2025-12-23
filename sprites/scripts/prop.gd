## 道具组件
@tool
class_name Prop extends Area2D

## 道具类型
enum PropType {
	## 弹药
	ammo,
	## 木箱
	crate,
	## 大木箱
	big_crate,
}

## 道具类型
@export
var prop_type: PropType = PropType.crate

func _ready() -> void:
	_update_prop_sprite(prop_type)

func _enter_tree() -> void:
	_update_prop_sprite(prop_type)

## 更新道具精灵
func _update_prop_sprite(type: PropType) -> void:
	var sprite_size: Vector2
	var sprite_texture: Resource
	match type:
		PropType.ammo:
			sprite_size = Vector2(16.0, 13.0)
			sprite_texture = load('res://assets/props/ammo.png')
		PropType.crate:
			sprite_size = Vector2(16.0, 16.0)
			sprite_texture = load('res://assets/props/crate.png')
		PropType.big_crate:
			sprite_size = Vector2(32.0, 16.0)
			sprite_texture = load('res://assets/props/bigcrate.png')
	if not sprite_texture or not sprite_size: return
	$Sprite2D.texture = sprite_texture
	_update_collision_shape(sprite_size) #更新碰撞矩形形状

## 更新碰撞矩形形状
func _update_collision_shape(size: Vector2) -> void:
	var shape = RectangleShape2D.new()
	shape.size = size
	$CollisionShape2D.shape = shape

## 道具与玩家发生碰撞判断
func _on_body_entered(body: Node2D) -> void:
	if not body is Player: return
	(body as Player).get_prop(prop_type) #玩家获得道具
	if prop_type == PropType.ammo: #如果是弹药道具，直接从视图删除
		queue_free()
		return
	#停用道具的碰撞检测
	set_deferred(&'monitoring', false)
	set_deferred(&'monitorable', false)
	$CollisionShape2D.set_deferred(&'disabled', true)
