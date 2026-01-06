extends Node2D

func _ready() -> void:
	global_position = Vector2(150, 150)
	$GPUParticles2D.texture = _create_atlas_texture(0)
	$GPUParticles2D.process_material = _create_material()
	$GPUParticles2D2.texture = _create_atlas_texture(1)
	$GPUParticles2D2.process_material = _create_material()
	$GPUParticles2D3.texture = _create_atlas_texture(2)
	$GPUParticles2D3.process_material = _create_material()
	$GPUParticles2D4.texture = _create_atlas_texture(3)
	$GPUParticles2D4.process_material = _create_material()
	$GPUParticles2D5.texture = _create_atlas_texture(4)
	$GPUParticles2D5.process_material = _create_material()
	$GPUParticles2D6.texture = _create_atlas_texture(5)
	$GPUParticles2D6.process_material = _create_material()
	#await get_tree().create_timer(0.2).timeout
	#var tween = get_tree().create_tween()
	#tween.set_loops()
	#tween.tween_property(self, 'rotation_degrees', 360, 1.0)
	#tween.tween_property(self, 'rotation_degrees', 0, 1.0)
	#tween.play()

func _physics_process(delta: float) -> void:
	global_position.x += delta * 100.0

func _create_material() -> ParticleProcessMaterial:
	@warning_ignore('shadowed_variable_base_class')
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
	material.emission_sphere_radius = 10.0
	material.emission_box_extents = Vector3(3,3,0)
	material.scale_min = 0.2
	material.scale_max = 0.5
	material.angle_min = 0.0
	material.angle_max = 25.0
	material.gravity = Vector3(0, 0, 0)
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 5.0
	material.direction = Vector3(-1, 0, 0)
	material.spread = 25.0
	return material

func _create_atlas_texture(offset: int = 0) -> Texture2D:
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload('res://assets/boss/sparks.png')
	atlas_texture.region = Rect2(Vector2(offset * 16, 0),\
		Vector2(16, 16))
	return atlas_texture
