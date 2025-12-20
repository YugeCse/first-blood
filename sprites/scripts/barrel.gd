class_name Barrel extends Area2D

enum State {
	idle,
	bom,
	destroy
}

## 是否是红色的
@export
var is_red: bool = false

## 基础精灵对象
@export
var sprite: Sprite2D

## 基础碰撞shape对象
@export
var default_collision_shape: CollisionShape2D

## 爆炸精灵对象
@export
var bom_sprite: AnimatedSprite2D

## 爆炸范围检测对象
@export
var bom_area_detector: Area2D

## 爆炸碰撞shape对象
@export
var bom_collision_shape: CollisionShape2D

## 当前状态
var state: Barrel.State = Barrel.State.idle

func _ready() -> void:
	bom_sprite.animation_finished\
		.connect(func(): state = State.destroy)
	bom_area_detector.monitoring = false
	bom_area_detector.monitorable = false

func _process(delta: float) -> void:
	if state == State.idle:
		sprite.visible = true
		bom_sprite.visible = false
	elif state == State.bom:
		sprite.visible = false
		bom_sprite.visible = true
	else: queue_free()
	
## 本地与其他物品发生碰撞，一般特指与子弹碰撞
func _on_area_entered(area: Area2D) -> void:
	if area is PlayerBullet: #如果与子弹发生碰撞，跳转为爆炸模式
		state = State.bom
		self.monitoring = false
		self.monitorable = false
		bom_sprite.play(&'default')
		bom_area_detector.monitoring = true
		bom_area_detector.monitorable = true
		

## 爆炸物与其他发生碰撞，一般值得把敌人或者玩家炸死
func _on_bom_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
