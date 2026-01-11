class_name BossLaser extends Node2D

## 是否是debug模式
@export
var debug_mode: bool = false

## 运行速度
@export
var speed: float = 80.0

## 运动方向
@export
var direction: Vector2 = Vector2.ZERO

@export
var dismiss_distance: float = 200.0

func _ready() -> void:
	if debug_mode or Engine.is_editor_hint():
		position = Vector2(150, 30)
	for index in range(0, 5, 1):
		_create_particles(index)

func _physics_process(delta: float) -> void:
	var viewport_size = get_viewport().get_visible_rect()
	if position.x > viewport_size.size.x + dismiss_distance or\
		position.x < -dismiss_distance or\
		position.y < -dismiss_distance or\
		position.y > viewport_size.size.y + dismiss_distance:
		queue_free()
		return
	position += direction * speed * delta

func _create_particles(type: int) -> void:
	var target_type = clampi(type, 0, 5)
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas =\
		preload('res://assets/boss/sparks.png')
	atlas_texture.region = Rect2(target_type * 16, 0, 16, 16)
	var gpu_particle = GPUParticles2D.new()
	var g_material = ParticleProcessMaterial.new()
	g_material.emission_shape =\
		ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	g_material.emission_sphere_radius = 8.0
	g_material.scale_min = 0.2 
	g_material.scale_max = 0.4
	g_material.initial_velocity_min = 10.0
	g_material.initial_velocity_max = 100.0
	g_material.emission_color_texture =\
		preload('res://assets/boss/sParticlesLaser.png')
	g_material.direction = Vector3(0, -1, 0)
	gpu_particle.emitting = true
	gpu_particle.amount = 3
	gpu_particle.lifetime = 0.5
	gpu_particle.texture = atlas_texture
	gpu_particle.position = Vector2.ZERO
	gpu_particle.process_material = g_material
	gpu_particle.position = Vector2(0.0, -8.0)
	add_child(gpu_particle)
