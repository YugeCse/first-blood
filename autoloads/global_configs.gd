extends Node

## 设计地图宽度：2000px
const DESIGN_MAP_WIDTH = 2000.0

## 设计地图高度：210px
const DESIGN_MAP_HEIGHT = 210.0



## 玩家生命数
var player_life_count: int = 3

## 玩家上次在地面上的坐标数据
var player_last_floor_position: Vector2

## 玩家得分
var player_score: float = 0.0

## 玩家道具背包
var player_props: Array = []


## 地图物理层
enum MapPhysicLayer {
	
	## 地面
	floor = 0,
	
	## 食物类
	food = 1,
	
	## 油桶/化学桶
	barrel = 2,
	
	## 普通物品
	normal = 3
}
