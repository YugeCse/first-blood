## 玩家子弹组件
class_name PlayerBullet extends Area2D

@export
var speed: float = 200.0

@export
var direction: Vector2 = Vector2.RIGHT

@export
var is_strong_fire: bool = false

@onready
var sprite = $AnimatedSprite2D  

@onready
var collision_shape = $CollisionShape2D

@onready
var shoot_effect_audio_stream = preload('res://assets/audio/shoot_effect.ogg')

func _ready() -> void:
	_play_shoot_effect_audio() #播放射击音频效果
	if is_strong_fire:
		sprite.play(&'level2')
	else: sprite.play(&'default')
	sprite.rotate(direction.angle())
	sprite.animation_finished.connect(queue_free)

func _physics_process(delta: float) -> void:
	var collision_radius = _get_collision_cirle().radius
	if global_position.x - collision_radius < 0 or\
		global_position.x - collision_radius > GlobalConfigs.DESIGN_MAP_WIDTH or\
		global_position.y - collision_radius < 0 or\
		global_position.y - collision_radius > GlobalConfigs.DESIGN_MAP_WIDTH:
		queue_free() #销毁这个子弹组件
		return
	if collision_shape.disabled: return
	position += direction * speed * delta

## 获取碰撞区域的矩形信息
func _get_collision_cirle() -> CircleShape2D:
	return collision_shape.shape as CircleShape2D

## 发生碰撞，需要删除
func boom():
	if collision_shape.disabled:
		return #已经是待销毁状态了
	collision_shape.set_deferred(&'disabled', true)
	sprite.animation_finished.disconnect(queue_free)
	sprite.play(&'boom')
	sprite.animation_finished.connect(queue_free)

## 播放射击音频效果
func _play_shoot_effect_audio() -> void:
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = shoot_effect_audio_stream
	audio_player.pitch_scale = 1.0
	audio_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	audio_player.mix_target = AudioStreamPlayer.MIX_TARGET_SURROUND
	audio_player.autoplay = true
	add_child(audio_player) #添加到树节点中
	audio_player.finished.connect(audio_player.queue_free)

func _on_area_entered(area: Area2D) -> void:
	if area is EnemyBullet: #如果与敌方子弹碰撞
		boom(); area.boom()
		return
	#如果碰撞来自其他包含它的父类对象
	var parent = area.get_parent()
	if not parent: return
	var fire_crack = 10.0
	if is_strong_fire: #如果是强大活力
		fire_crack = randf_range(30.0, 60.0)
	else: fire_crack = randf_range(10.0, 30.0)
	if parent is Turret: #如果是炮台
		parent.hurt(fire_crack)
		boom() #发生碰撞，需要删除
	elif parent is Grunt: #如果是敌人
		parent.hurt(fire_crack)
		boom() #发生碰撞，需要删除
	elif parent is GruntSoilder: #如果是红衣士兵
		parent.boom()
		boom() #发生碰撞，需要删除
	elif parent is Boss: #如果是boss
		parent.hurt(fire_crack)
		boom() #发生碰撞，需要删除
		
