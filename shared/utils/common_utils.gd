## 枚举类型取值转字符串名称
static func enum_to_string(enum_dict:Dictionary, value:int) -> String:
	for k in enum_dict:
		if enum_dict[k] == value:
			return k
	return ""
