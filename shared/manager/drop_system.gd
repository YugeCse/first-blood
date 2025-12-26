## 道具掉落系统类
class_name DropSystem extends Node

const CommonUtils = preload('res://shared/utils/common_utils.gd')

## 敌人掉落配置数据库
var drop_tables: Dictionary[String, DropTable] = {}

## 掉落限制设定，比如：某个东西只能掉落几次, child-type[Prop.PropType, int]
var drop_limits: Dictionary[String, Variant] = {}

## 掉落统计数据，比如：某个角色掉落了多少次了, child-type[Prop.PropType, int]
var drop_statistics: Dictionary[String, Variant] = {}

## 随机数生成对象
var rng: RandomNumberGenerator

## 道具场景对象
@onready
var prop_scene_packed: PackedScene = preload("res://sprites/tscns/prop.tscn")

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()
	_initialize_drop_limits() #初始化掉落限制数据
	_initialize_drop_tables() #初始化物品掉落表
	
## 初始化掉落限制数据
func _initialize_drop_limits():
	drop_limits["grunt"] = { 
		Prop.PropType.ammo : 2,
		Prop.PropType.nade: 5,
		Prop.PropType.crate: 3,
		Prop.PropType.big_crate: 2 
	} #没局中设置的某类角色的最大掉落数据限制

## 初始化掉落表
func _initialize_drop_tables():
	var grunt_table = DropTable.new("grunt")
	grunt_table.base_drops.append(\
		DropItem.new(Prop.PropType.nade, 0.3, 1, 1, 5.0))
	grunt_table.base_drops.append(\
		DropItem.new(Prop.PropType.ammo, 0.18, 1, 1, 2.0))
	grunt_table.base_drops.append(\
		DropItem.new(Prop.PropType.crate, 0.15, 1, 1, 3.0))
	grunt_table.base_drops.append(\
		DropItem.new(Prop.PropType.big_crate, 0.20, 1, 1, 2.5))
	drop_tables["grunt"] = grunt_table #针对敌人类型赋值掉落表

## 独立概率（每个物品独立计算）
func calculate_drops_independent(enemy_type: String) -> Dictionary[Prop.PropType, int]:
	var drops: Dictionary[Prop.PropType, int] = {}
	if not drop_tables.has(enemy_type):
		return drops
	var table = drop_tables[enemy_type] as DropTable
	# 添加必掉物品
	for item in table.guranteed_drops:
		if rng.randf() <= item.chance:
			var drop_type = (item as DropItem).prop_type
			var count = rng.randi_range(item.min_count, item.max_count)
			drops[drop_type] = drops.get(drop_type, 0) + count
	# 独立概率计算每个基础掉落
	for item in table.base_drops:
		if rng.randf() <= item.chance:
			var drop_type = (item as DropItem).prop_type
			var count = rng.randi_range(item.min_count, item.max_count)
			drops[drop_type] = drops.get(drop_type, 0) + count
	return drops

# 加权随机（保证掉落，但物品随机）
func calculate_drops_weighted(enemy_type: String, drop_count: int = 1) -> Dictionary:
	var drops: Dictionary[Prop.PropType, int] = {}
	if not drop_tables.has(enemy_type):
		return drops
	var table = drop_tables[enemy_type]
	# 添加必掉物品
	for item in table.guaranteed_drops:
		if rng.randf() <= item.chance:
			var count = rng.randi_range(item.min_count, item.max_count)
			drops[item.prop_type] = drops.get(item.prop_type, 0) + count
	# 计算总权重
	var total_weight = 0.0
	for item in table.base_drops:
		total_weight += item.weight
	var drop_limits_data =\
		drop_limits[enemy_type] if drop_limits.has(enemy_type) else null
	var drop_statistics_data =\
		drop_statistics[enemy_type] if drop_statistics.has(enemy_type) else null
	var available_drops = min(drop_count, table.max_drops) #抽取指定数量的掉落
	for i in range(available_drops):
		if table.base_drops.is_empty() or total_weight <= 0:
			break
		var roll = rng.randf_range(0.0, total_weight)
		var current_weight = 0.0
		var movable_indexs: Array[int] = []
		for item in table.base_drops:
			current_weight += item.weight
			if roll <= current_weight: #先要满足物品掉落的权重设定
				if drop_limits_data:
					if not drop_statistics:
						drop_statistics[enemy_type] = {}
						drop_statistics_data = drop_statistics[enemy_type]
					var origin_drop_count = drop_statistics_data.get(item.prop_type, 0)
					if origin_drop_count >= drop_limits_data.get(item.prop_type, 0) as int:
						var removable_index = table.base_drops\
							.find(func(v): return v.prop_type == item.prop_type)
						if removable_index != -1: 
							movable_indexs.append(removable_index)
						continue
				if rng.randf_range(0.0, 1.0) <= item.chance: #再根据物品调律概率计算是否要掉落这个物品
					var count = rng.randi_range(item.min_count, item.max_count)
					drops[item.prop_type] = drops.get(item.prop_type, 0) + count
					if drop_statistics: #如果有掉落统计对象
						if drop_statistics_data: #如果有掉落统计记录
							var origin_drop_count = drop_statistics_data.get(item.prop_type, 0)
							drop_statistics_data[item.prop_type] = origin_drop_count + 1
							drop_statistics[enemy_type][item.prop_type] = origin_drop_count + 1
					break
		if movable_indexs.size() > 0:
			movable_indexs.sort_custom(func(a, b): return a > b)
			for index in movable_indexs:
				drop_tables[enemy_type].base_drops.remove_at(index)
	return drops

## 生成道具[br]
## - type: 道具类型[br]
## - auto_dismiss_time: 自动消失的时间，默认15秒[br]
## @return 生成的道具，可能为null
func generate_prop(\
	type: Prop.PropType,
	auto_dismiss_time: float = 15.0
) -> Node2D:
	var prop = prop_scene_packed.instantiate()
	var child = prop.get_child(0) as Prop
	child.prop_type = type
	child.auto_dismiss_time = auto_dismiss_time
	var prop_name = CommonUtils\
		.enum_to_string(Prop.PropType, type)
	print('道具[', prop_name, ']掉落成功！')
	return prop

## 掉落选项
class DropItem:
	## 道具类型
	@warning_ignore("enum_variable_without_default")
	var prop_type: Prop.PropType
	## 掉落概率
	var chance: float
	## 最小掉落数量
	var min_count: int
	## 最大掉落数量
	var max_count: int
	## 掉落权重
	var weight: float = 1.0

	func _init(
		type: Prop.PropType,
		chance_val: float = randf_range(0.0, 1.0),
		min_val: int = 1,
		max_val: int = 1,
		weight_val: float = 1.0
	):
		self.prop_type = type
		self.chance = chance_val
		self.min_count = min_val
		self.max_count = max_val
		self.weight = weight_val

## 掉落表
class DropTable:
	## 敌人类型
	var enemy_type: String
	## 基础掉落
	var base_drops: Array[DropItem] = []
	## 必掉物品
	var guaranteed_drops: Array[DropItem] = []
	## 总掉落概率
	var total_drop_chance: float = 0.0
	## 最大掉落数量
	var max_drops: int = 3

	## 构造函数[br]
	## - type: 敌人类型
	func _init(type: String):
		self.enemy_type = type
