extends Node

## 声音是否可用
var sound_available: bool = false


##############################
##                          ##
##                          ##
##       玩家相关的属性       ##
##                          ##
##                          ##
##############################


## 玩家得分
var player_score: float = 0.0

## 玩家道具背包
var player_props: Array = []

## 玩家生命数
var player_life_count: int = 3

## 重置玩家数据
func reset_player_data():
	player_score = 0.0
	player_props = []
	player_life_count = 3


##############################
##                          ##
##                          ##
##       地图相关的属性       ##
##                          ##
##                          ##
##############################

## 设计地图宽度：2000px
const DESIGN_MAP_WIDTH = 2000.0

## 设计地图高度：210px
const DESIGN_MAP_HEIGHT = 210.0
