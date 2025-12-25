extends Node

## 游戏结束的通知事件
@warning_ignore("unused_signal")
signal on_game_over()

## 玩家死亡的通知事件[br]
## - location: 玩家死亡时的全局坐标
@warning_ignore("unused_signal")
signal on_player_dead(location: Vector2)

## 玩家获得道具的通知事件，用于更新HUD的显示[br]
## - type: 道具类型[br]
## - bundle: 数据包
@warning_ignore("unused_signal")
signal on_player_get_prop(type: Prop.PropType, bundle: Dictionary[String, Variant])
