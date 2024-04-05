extends Node

var LOG_EVERYTHING = []
var LOG_ENGINE = []
var LOG_ERRORS = []

var LOG_CHANGED = false

const MAX_LINES_IN_CONSOLE = 200
func limit_array(arr, limit = MAX_LINES_IN_CONSOLE):
	if arr.size() > limit:
		arr.pop_front()

func get_enum_string(enums, value):
	return enums.keys()[value]
func get_timestamp(from):
	var d = OS.get_datetime()
	var date = "%04d/%02d/%02d %02d:%02d:%02d" % [d.year, d.month, d.day, d.hour, d.minute, d.second]
	if from == null:
		return date + " -- "
	else:
		var app_name = from.APP_NAME if "APP_NAME" in from else from.name
		return date + str(" -- [", app_name, "]: ")
func generic(from, text):
	var msg = str(get_timestamp(from), text)

	var bb_msg = msg
	LOG_EVERYTHING.push_back(bb_msg)
	limit_array(LOG_EVERYTHING)
	if from != null && "LOG" in from:
		from.LOG.push_back(bb_msg)
		limit_array(from.LOG)
	else:
		LOG_ENGINE.push_back(bb_msg)
		limit_array(LOG_ENGINE)
	print(msg)
	LOG_CHANGED = true
func error(from, err, text):
	var msg = str(get_timestamp(from), "ERROR: ", text)
	if err != null:
		msg += str(" (", err, ":", get_enum_string(GlobalScope.Error, err), ")")

	var bb_msg = str("[color=#ee1100]", msg, "[/color]")
	LOG_EVERYTHING.push_back(bb_msg)
	limit_array(LOG_EVERYTHING)
	LOG_ERRORS.push_back(bb_msg)
	limit_array(LOG_ERRORS)
	if from != null && "LOG" in from:
		from.LOG.push_back(bb_msg)
		limit_array(from.LOG)
	else:
		LOG_ENGINE.push_back(bb_msg)
		limit_array(LOG_ENGINE)
	print(msg)
	push_error(msg)
	LOG_CHANGED = true
