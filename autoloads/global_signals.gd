extends Node

## 玩家死亡的通知
signal on_player_dead(location: Vector2)

## 游戏结束的通知
signal on_game_over()

## 注册玩家死亡的回调方法
func on_player_dead_connect(callback: Callable):
	if on_player_dead.is_connected(callback):
		return #已经连接了，不用再注册了
	on_player_dead.connect(callback)

## 取消注册玩家死亡的回调方法
func on_player_dead_disconnect(callback: Callable) -> bool:
	if on_player_dead.is_connected(callback):
		on_player_dead.disconnect(callback)
		return true
	return false

## 注册游戏界结束的回调方法
func on_game_over_connect(callback: Callable):
	if on_game_over.is_connected(callback):
		return #已经连接了，不用再注册了
	on_game_over.connect(callback)

## 取消注册游戏界结束的回调方法
func on_game_over_disconnect(callback: Callable) -> bool:
	if on_game_over.is_connected(callback):
		on_game_over.disconnect(callback)
		return true
	return false
