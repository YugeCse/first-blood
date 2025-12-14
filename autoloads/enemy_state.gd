extends Node

## 行为
enum Action {
	## 禁止
	idle,
	## 巡逻
	patrol,
	## 追击
	chase,
	## 死亡
	dead
}
