## 道具管理类，应当是全局的
extends Node

const CommonUtils = preload('res://shared/utils/common_utils.gd')

## 物品道具掉落概率
const PropDropRatio: Dictionary[Prop.PropType, float] = {
	Prop.PropType.nade: 0.48,
	Prop.PropType.ammo : 0.8,
	Prop.PropType.crate : 0.8,
	Prop.PropType.big_crate : 0.4
}

## 最大道具掉落数量，默认：10
@export
var max_drop_props_count: int = 10

## 总共掉落道具数量
var _total_drop_props_count: int = 0

## 道具场景对象
@onready
var prop_scene_packed: PackedScene = preload("res://sprites/tscns/prop.tscn")

## 随机掉落道具[br]
## - auto_dismiss_time: 自动消失的时间，默认15秒[br]
## - prop_choices: 道具生成的可选项[br]
## @return 生成的道具，可能为null
func rand_drop_prop(\
	auto_dismiss_time: float = 15.0,
	prop_choices: Array = Prop.PropType.values()
) -> Prop:
	var prop_types = prop_choices as Array[int]
	if prop_types.size() == 0: return null
	var rand_type: int
	if prop_types.size() == 1:
		rand_type = prop_types[0]
	else:
		rand_type = randi_range(0, prop_types.size() - 1)
	var target_type = prop_types.get(rand_type)
	if not PropDropRatio.has(target_type):
		print('道具配置中没有指定的道具类型: ', target_type)
		return null
	var compute_radio = randf()
	var drop_ratio = PropDropRatio[target_type]
	var prop_name = CommonUtils\
		.enum_to_string(Prop.PropType, target_type)
	if compute_radio >= drop_ratio:
		print('道具[', prop_name, ']生成失败，道具掉落概率是： ',\
			drop_ratio, ' 当前随机值：', compute_radio)
		return null #超过概率范围
	var prop = prop_scene_packed.instantiate()
	prop.prop_type = target_type
	prop.auto_dismiss_time = auto_dismiss_time
	_total_drop_props_count += 1 #每次掉落增加一次记录
	print('道具[', prop_name, ']生成成功, 概率：', drop_ratio)
	return prop
