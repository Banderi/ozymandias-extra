extends Node

func MAX(bs):
	return 1 << bs
func u_to_i(unsigned, bs):
	return (unsigned + MAX(bs-1)) % MAX(bs) - MAX(bs-1)

var schema_items = {}
var schema_items_names = {}
func record_schema_item(item):
	if item.schema_index != -1:
		schema_items[item.schema_index] = item
func record_schema_names_recursive(item):
	if item == null:
		return
	var metadata = item.get_metadata(0)
	var itemname = metadata[0]
	var data = metadata[1]
	if data is Dictionary && data.get("schema_index",-1) != -1:
		schema_items_names[data.schema_index] = [itemname, item]
	record_schema_names_recursive(item.get_children())
	record_schema_names_recursive(item.get_next())
		
func is_valid(item):
	return item is Dictionary && item.has("display_formatting")

var last_schema_memory_address = -1
func new(type, value, display_formatting = null, data_offset = -1, schema_index = -1):
	var size = -1
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
	
	var struct = {
		"type": type,
		"size": size,
		"value": value,
		"display_formatting": display_formatting,
		"offset": data_offset,
		"schema_index": schema_index,
	}
	
	# register to schema table...
	record_schema_item(struct)
	return struct
func as_text(item, with_value = null):
	if !is_valid(item):
		return "[ ... ]"
	if with_value == null:
		with_value = item.value
	if item.display_formatting == null:
		if item.type == "[char]":
			return (with_value as PoolByteArray).get_string_from_ascii()
		if with_value is Array || with_value is PoolByteArray:
			return "[ ... ]"
		return str(with_value)
	else:
		match item.display_formatting:
			"bool":
				return str(with_value as bool)
			"string":
				return (with_value as PoolByteArray).get_string_from_ascii()
			_:
				return item.display_formatting % [with_value]
func as_data_array(item):
	return [
		item.size,
		item.type,
		as_text(item)
	]
