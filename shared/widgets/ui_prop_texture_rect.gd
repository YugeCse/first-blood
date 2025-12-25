## UI道具图片展示控件
@tool
class_name UiPropTextureRect extends TextureRect

## 道具类型
enum PropType {
	## 火力加强
	fire_strong,
	## 普通火力
	fire_normal,
	## 火力2倍强度
	fire_multiply_x1,
	## 火力2倍强度
	fire_multiply_x2
}

## 道具类型
@export
var type: PropType

func _ready() -> void:
	_update_texture(type) #更新图像数据
	
func _enter_tree() -> void:
	_update_texture(type) #更新图像数据

## 更新图像数据
func _update_texture(type: PropType) -> void:
	stretch_mode = TextureRect.STRETCH_KEEP
	expand_mode = TextureRect.EXPAND_KEEP_SIZE
	var target_texture: Resource
	match type:
		PropType.fire_strong:
			target_texture = load('res://assets/ui/ui_weapon_double_red.png')
		PropType.fire_normal:
			target_texture = load('res://assets/ui/ui_weapon_missile_red.png')
		PropType.fire_multiply_x1:
			target_texture = load('res://assets/ui/ui_weapon_grenadier_blue.png')
		PropType.fire_multiply_x2:
			target_texture = load('res://assets/ui/ui_weapon_tribow_blue.png')
	if not target_texture: return
	texture = target_texture as Texture2D
	size = (target_texture as Texture2D).get_size()
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
