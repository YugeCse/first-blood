class_name Player extends CharacterBody2D

@export
var state: int = PlayerState.Action.idle

@onready
var sprite = $AnimatedSprite

@onready
var collision_shape = $CollisionShape

func _ready() -> void:
	pass
