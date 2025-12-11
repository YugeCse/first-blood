## 炮台组件
class_name Turret extends StaticBody2D

@onready
var sprite = $Sprite2D

@onready
var collision_shape = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.play('left') #方向朝向玩家来的方向

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
