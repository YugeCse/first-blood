@tool
extends Control

const CommonUtils = preload('res://shared/utils/common_utils.gd')

func _ready() -> void:
	var prop = PropManager.rand_drop_prop()
	if prop:
		prop.global_position = Vector2(280, 100)
		prop.scale = Vector2(5.0, 5.0)
		add_child(prop)
		print('添加了一个道具：', \
			CommonUtils.enum_to_string(Prop.PropType, prop.prop_type))
