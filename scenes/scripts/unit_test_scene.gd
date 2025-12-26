@tool
extends Control

const CommonUtils = preload('res://shared/utils/common_utils.gd')

func _ready() -> void:
	#var project_scale = ProjectSettings\
		#.get_setting('display/window/stretch/scale') as float
	#print('项目设置的缩放比例：{scale}'.format({'scale': project_scale}))
	#var viewport_rect = get_window().get_visible_rect()
	#var viewport_size = viewport_rect.size
	#var origin_size = self.size
	#var require_scale = minf(\
		#viewport_size.x / origin_size.x,\
		#viewport_size.y / origin_size.y)
	#var target_width = origin_size.x * require_scale
	#var target_height = origin_size.y * require_scale
	#var offset_x = (viewport_size.x - target_width) / 2.0
	#var offset_y = (viewport_size.y - target_height) / 2.0
	#self.scale = Vector2(require_scale, require_scale)
	#self.size = Vector2(target_width, target_height)
	#self.global_position = Vector2(offset_x, offset_y)
	#$ColorRect.scale = Vector2(require_scale, require_scale)
	#$TileMapLayer.scale = Vector2(require_scale, require_scale)
	#
	#var prop = DropPropManager.rand_drop_prop()
	#if prop:
		#prop.global_position = Vector2.ZERO
		#add_child(prop)
		#print('添加了一个道具：', \
			#CommonUtils.enum_to_string(Prop.PropType, prop.prop_type))
	#$UiPropTextureRect._update_texture(UiPropTextureRect.PropType.fire_strong)
	
	var drop_system = DropSystem.new()
	add_child(drop_system)
	var drop_result = drop_system.calculate_drops_weighted("grunt")
	if drop_result.size() > 0:
		for key in drop_result.keys():
			var prop_name = CommonUtils.enum_to_string(Prop.PropType, key)
			print('物品掉落结果：', prop_name, ', 数量：', drop_result.get(key))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.RED)
