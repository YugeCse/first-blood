extends Node

## 行为枚举
enum Action {
	## 静止
	idle,
	## 跳跃
	jumping,
	## 卧倒
	fell_flat,
	## 向前
	move_forward,
	## 向后
	move_backward,
	## 死亡
	dead
}
