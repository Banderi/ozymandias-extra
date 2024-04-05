extends Tree

func _ready():
	clear()

const MAX_COLUMNS = 99

func clear():
	.clear()
	var _root = create_item()
	columns = 1
	set_column_title(0,"")
func add_array_member(label, data):
	var table_item = create_item()
	
	set_column_min_width(0, 1)
	for c in min(MAX_COLUMNS, data.size()):
		set_column_min_width(c + 1, 2)
		
	if DataStruct.is_valid(data):
		table_item.set_text(1, DataStruct.as_text(data))
	elif data is Array:
		for d in min(MAX_COLUMNS, data.size()):
			table_item.set_text(d + 1, str(data[d]))
	elif data is Dictionary:
		for d in min(MAX_COLUMNS, data.size()):
			var item = data[data.keys()[d]]
			if DataStruct.is_valid(item):
				table_item.set_text(d + 1, DataStruct.as_text(data[data.keys()[d]]))
			if item is String:
				table_item.set_text(d + 1, str(item))
	else:
		table_item.set_text(1, data.text())
	
	# index/name
#	if label.begins_with("unk"):
#		table_item.set_text(0, "??")
#		table_item.set_custom_color(0, Color(1,1,1,0.3))
#	elif label.begins_with("unused"):
#		table_item.set_text(0, str(label))
#		table_item.set_custom_color(0, Color(1,1,1,0.3))
#	else:
	table_item.set_text(0, str(label))
	return table_item
func add_raw_field(label, data):
	var table_item = create_item()
	
	# index/name
	if label.begins_with("unk"):
		table_item.set_text(0, "??")
		table_item.set_custom_color(0, Color(1,1,1,0.3))
	elif label.begins_with("unused"):
		table_item.set_text(0, str(label))
#		table_item.set_custom_color(0, Color(1,0.7,0.7,0.5))
		table_item.set_custom_color(0, Color(1,1,1,0.3))
	else:
		table_item.set_text(0, str(label))
		
	for i in data.size():
		table_item.set_text(i + 1, str(data[i]))
	return table_item

func present(key, data):
	
	# this MUST be an array of EQUAL FORMAT dictionary elements!!
	# EVERY final raw field MUST have a key/name!!
	if data is Array || (data is Dictionary && data.has("value") && data.value is Array):
		if data.has("value"):
			data = data.value
		if DataStruct.is_valid(data[0]):
			columns = 4 # index, size, value
			set_column_title(0, "#")
			set_column_title(1, "Size")
			set_column_title(2, "Type")
			set_column_title(3, "Value")
			set_column_min_width(0, 3)
			set_column_min_width(1, 4)
			set_column_min_width(2, 4)
			set_column_min_width(3, 9)
			for e in data.size():
				add_raw_field(str(e), DataStruct.as_data_array(data[e]))
			return
		elif data[0] is Dictionary:
			columns = int(min(MAX_COLUMNS + 1, data[0].size() + 1)) # column 0 is reserved for index
			set_column_title(0,"#")
			for c in min(MAX_COLUMNS, data[0].size()):
				set_column_title(c + 1, str(data[0].keys()[c]))
			for e in data.size():
				add_array_member(str(e), data[e])
			return
	
	# any other case: raw data field items
	columns = 4 # name, size, type, value
	set_column_title(0, "Name")
	set_column_title(1, "Size")
	set_column_title(2, "Type")
	set_column_title(3, "Value")
	set_column_min_width(0, 10)
	set_column_min_width(1, 4)
	set_column_min_width(2, 4)
	set_column_min_width(3, 9)
	if DataStruct.is_valid(data):
		add_raw_field(key, DataStruct.as_data_array(data))
	elif data is Dictionary:
		for element in data:
			if DataStruct.is_valid(data[element]):
				add_raw_field(element, DataStruct.as_data_array(data[element]))
			else:
				if element == "offset" || element == "schema_index":
					continue
				add_raw_field(element, ["..."])
