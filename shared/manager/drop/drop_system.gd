extends Node

## 道具掉落系统类
class_name DropSystem

# 敌人掉落配置数据库
var drop_tables: Dictionary[String, DropTable] = {}

var rng: RandomNumberGenerator

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()
	initialize_drop_tables()  #初始化示例掉落表

## 初始化示例掉落表
func initialize_drop_tables():
	var grunt_table = DropTable.new("grunt")
	## 掉落纳豆，最大掉落6个，最少1个
	grunt_table.base_drops.append(\
		DropItem.new(Prop.PropType.nade, 0.3, 1, 1, 5.0))
	grunt_table.base_drops.append(\
		DropItem.new(Prop.PropType.ammo, 0.2, 1, 1, 2.0))
	grunt_table.base_drops.append(\
		DropItem.new(Prop.PropType.crate, 0.15, 1, 1, 3.0))
	grunt_table.base_drops.append(\
		DropItem.new(Prop.PropType.big_crate, 0.23, 1, 1, 2.5))
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
	# 抽取指定数量的掉落
	var available_drops = min(drop_count, table.max_drops)
	for i in range(available_drops):
		if table.base_drops.is_empty() or total_weight <= 0:
			break
		var roll = rng.randf_range(0.0, total_weight)
		var current_weight = 0.0
		for item in table.base_drops:
			current_weight += item.weight
			if roll <= current_weight:
				# 掉落这个物品
				var count = rng.randi_range(item.min_count, item.max_count)
				drops[item.prop_type] = drops.get(item.prop_type, 0) + count
				# 从池中移除（防止重复抽取同一个物品）
				# 如果需要允许重复，注释下面这行
				# total_weight -= item.weight
				break
	return drops

## 掉落选项
class DropItem:
	## 道具类型
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
