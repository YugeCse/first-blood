extends Node2D

func _ready() -> void:
	position = Vector2(150, 30)
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload('res://assets/boss/sParticlesLaser.png')
	atlas_texture.region = Rect2(0, 0, 2, 2)
	var gpu_particle = GPUParticles2D.new()
	var g_material = ParticleProcessMaterial.new()
	g_material.emission_shape =\
		ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	g_material.emission_sphere_radius = 20.0
	g_material.initial_velocity_min = 10.0
	g_material.initial_velocity_max = 100.0
	g_material.direction = Vector3(0, -1, 0)
	gpu_particle.emitting = true
	gpu_particle.amount = 10
	gpu_particle.lifetime = 0.5
	gpu_particle.texture = atlas_texture
	gpu_particle.position = Vector2.ZERO
	gpu_particle.process_material = g_material
	add_child(gpu_particle)
	

func _physics_process(delta: float) -> void:
	position.y += 80 * delta
