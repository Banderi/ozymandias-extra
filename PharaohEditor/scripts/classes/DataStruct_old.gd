extends Node
class_name DataStruct_old

var type : String
var size : int
var value
var display_formatting
var offset = -1

func _free_if_orphaned():
	if not is_inside_tree(): # Optional check - don't free if in the scene tree
		queue_free()

func _init(_type, _value, _display_formatting = null, data_offset = -1):
	Utils.connect("freeing_orphans", self, "_free_if_orphaned")
	type = _type
	value = _value
	display_formatting = _display_formatting
	offset = data_offset
	match type:
		"u8","i8":
			size = 1
		"u16","i16":
			size = 2
		"u32","i32":
			size = 4
		"u64","i64":
			size = 8
	if type.begins_with("grid"):
		size = type.to_int() * 51984
	elif type.begins_with("buf"):
		size = type.to_int()
		type = "bytes"
	elif type.begins_with("str"):
		size = type.to_int()
		type = "[char]"
	
func as_text():
	if display_formatting == null:
		if type == "[char]":
			return (value as PoolByteArray).get_string_from_ascii()
		if value is Array || value is PoolByteArray:
			return "[ ... ]"
		return str(value)
	else:
		match display_formatting:
			"bool":
				return str(value as bool)
			"string":
				return (value as PoolByteArray).get_string_from_ascii()
			_:
				return display_formatting % [value]
func as_data_array():
	return [
		size,
		type,
		as_text()
	]

func _exit_tree():
	print("1")
