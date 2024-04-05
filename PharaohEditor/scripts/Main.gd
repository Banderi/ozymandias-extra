extends Control

#onready var ChunksView = $HSplit1/VSplit1/TextEdit
onready var ChunkTable = $Control/HSplit0/HSplit1/VSplit1/ChunkTable
onready var DataTable = $Control/HSplit0/HSplit1/VSplit1/DataTable

onready var SaveTable = $Control/HSplit0/HSplit2/VSplit2/SaveTable
onready var SchemaTable = $Control/HSplit0/HSplit2/VSplit2/SchemaTable
onready var SchemaMemoryTable = $Control/HSplit0/HSplit2/SchemaMemoryTable

const GDN_RES = preload("res://GDNScraper.gdns")
onready var GDNScraper = GDN_RES.new()

const RESOURCES = [
	"[None]",
	"Grain",
	"Meat",
	"Lettuce",
	"Chickpeas",
	"Pomegranates",
	"Figs",
	"Fish",
	"Game meat",
	"Straw",
	"Weapons",
	"Clay",
	"Bricks",
	"Pottery",
	"Barley",
	"Beer",
	"Flax",
	"Linen",
	"Gems",
	"Luxury goods",
	"Wood",
	"Gold",
	"Reeds",
	"Papyrus",
	"Stone",
	"Limestone",
	"Granite",
	"[Unused12]",
	"Chariots",
	"Copper",
	"Sandstone",
	"Oil",
	"Henna",
	"Paint",
	"Lamps",
	"Marble",
	"Deben",
	"Troops"
]
var DATA = {}
func construct_array(size, names, types, flip_rows = false):
	var arr = []
	if !flip_rows:
		for _i in range(0,size):
			var element = {}
			for e in names.size():
				element[names[e]] = file.read(types[e])
			arr.push_back(element)
	else: # sigh...
		for _i in range(0,size):
			var element = {}
			for e in names.size():
				element[names[e]] = null
			arr.push_back(element)
		for n in names.size():
			for i in range(0,size):
				arr[i][names[n]] = file.read(types[n])
	return arr
func construct_invasion_points():
	# UGHHHH...
	var land = []
	var sea = []
	
	var temp = []
	for _i in range(0,32):
		temp.push_back(file.read("i16"))
	
	for i in range(0,8):
		land.push_back({
			"x": temp[i],
			"y": temp[i+16]
		})
		sea.push_back({
			"x": temp[i+8],
			"y": temp[i+16+8]
		})
	return {
		"land": land,
		"sea": sea
	}
func construct_empty_schema_indexed_arr(schema_index, arr = []):
	var item = {
		"schema_index": schema_index,
		"value": arr
	}
	DataStruct.record_schema_item(item)
	return item
var next_schema_index = -1
func schema_index():
	next_schema_index += 1
	return next_schema_index

var file = null
var file_path = ""
func open_file(path):
	file_path = path
	
	# close previous streams
	if file != null:
		file.close()
	else:
		file = DataFile.new()
	var err = -1
	err = file.open(path, File.READ)
	if err != OK:
		Log.error(null,err,str("could not read file '",file_path,"'"))
		return null

	# read data
	next_schema_index = -1
	DataStruct.schema_items = {}
	DATA = {}
	DATA["header"] = {
		"map_index": file.read("u8", schema_index()),
		"campaign_index": file.read("u8", schema_index()),
		"prev_progress_pointer": file.read("i8", schema_index()),
		"mission_progress_pointer": file.read("u8", schema_index()),
		"version": file.read("u32", schema_index())
	}
	file.seek(0)
	var is_map = file.get_buffer(4).get_string_from_ascii() == "MAPS"
	file.seek(8)
	DATA["schema_count"] = file.read("u32", schema_index())
	DATA["schema_data"] = construct_empty_schema_indexed_arr(schema_index())
	for _i in range(0,300):
		var chunk = {
			"compressed": file.read("u32", -1, "bool"),
			"address": file.read("u32", -1, "0x%08X"),
			"size": file.read("u32"),
			"count": file.read("u32"),
			"unknown": file.read("u32"),
		}
		DATA["schema_data"].value.push_back(chunk)
		
	if is_map:
		DATA["image_grid"] = file.read_grid(4)
		DATA["edge_grid"] = file.read_grid(1)
		DATA["terrain_grid"] = file.read_grid(4)
		DATA["bitfields_grid"] = file.read_grid(1)
		DATA["random_grid"] = file.read_grid(1)
		DATA["elevation_grid"] = file.read_grid(1)
		DATA["random_iv"] = {
			"iv_1": file.read("i32"),
			"iv_2": file.read("i32"),
		}
		DATA["camera"] = {
			"x": file.read("i32"),
			"y": file.read("i32"),
		}
		DATA["soil_fertility_grid"] = file.read_grid(1)
	else:
		DATA["image_grid"] = file.read_zip_chunk(schema_index())
		DATA["edge_grid"] = file.read_zip_chunk(schema_index())
		DATA["building_grid"] = file.read_zip_chunk(schema_index())
		DATA["terrain_grid"] = file.read_zip_chunk(schema_index())
		DATA["aqueduct_grid"] = file.read_zip_chunk(schema_index())
		DATA["figure_grid"] = file.read_zip_chunk(schema_index())
		DATA["bitfields_grid"] = file.read_zip_chunk(schema_index())
		DATA["sprite_grid"] = file.read_zip_chunk(schema_index())
		DATA["random_grid"] = file.read_grid(1, schema_index())
		DATA["desiderability_grid"] = file.read_zip_chunk(schema_index())
		DATA["elevation_grid"] = file.read_zip_chunk(schema_index())
		DATA["building_damage_grid"] = file.read_zip_chunk(schema_index())
		DATA["aqueduct_backup_grid"] = file.read_zip_chunk(schema_index())
		DATA["sprite_backup_grid"] = file.read_zip_chunk(schema_index())
		DATA["figures"] = file.read_zip_chunk(schema_index())
		DATA["route_figures"] = file.read_zip_chunk(schema_index())
		DATA["route_paths"] = file.read_zip_chunk(schema_index())
		DATA["formations"] = file.read_zip_chunk(schema_index())
		
		DATA["formations_info"] = {
			"last_used_id": file.read("i32", schema_index()),
			"last_formation_id": file.read("i32", schema_index()),
			"total_formations": file.read("u32", schema_index()),
		}
		DATA["city_data"] = file.read_zip_chunk(schema_index())
		DATA["city_data_extra"] = {
			"unused_faction_flag1a": file.read("i8", schema_index()),
			"unused_faction_flag1b": file.read("i8"),
			"unused_faction_flag2a": file.read("i8"),
			"unused_faction_flag2b": file.read("i8"),
			"player_name_unused": file.read("str32", schema_index()),
			"player_name": file.read("str32"),
			"faction_id": file.read("i32", schema_index()),
		}
		DATA["buildings"] = file.read_zip_chunk(schema_index())
		DATA["camera_orientation"] = file.read("u32", schema_index())
		DATA["game_time"] = {
			"tick": file.read("i32", schema_index()),
			"day": file.read("i32", schema_index()),
			"month": file.read("i32", schema_index()),
			"year": file.read("i32", schema_index()),
			"total_days": file.read("i32", schema_index()),
		}
		DATA["highest_building_id_ever"] = file.read("u32", schema_index())
		DATA["tick_countdown_locusts"] = file.read("u32", schema_index())
		DATA["random_iv"] = {
			"iv_1": file.read("i32", schema_index()),
			"iv_2": file.read("i32", schema_index()),
		}
		DATA["camera"] = {
			"x": file.read("i32", schema_index()),
			"y": file.read("i32", schema_index()),
		}
		DATA["unk_city_graph_order"] = file.read("i32", schema_index())
		DATA["tick_countdown_hailstorm"] = file.read("i32", schema_index())
		DATA["empire_map_view"] = {
			"x": file.read("i32", schema_index()),
			"y": file.read("i32", schema_index()),
			"selected_object": file.read("i32", schema_index()),
		}
		DATA["empire_cities"] = file.read_zip_chunk(schema_index())
		DATA["building_count_industry"] = {
			"total": {
				"schema_index": schema_index()
			},
			"active": {
				"schema_index": schema_index()
			},
		}
		DataStruct.record_schema_item(DATA["building_count_industry"].total)
		DataStruct.record_schema_item(DATA["building_count_industry"].active)
		for r in range(0,36):
			DATA["building_count_industry"].total[RESOURCES[r]] = file.read("u32")
		for r in range(0,36):
			DATA["building_count_industry"].active[RESOURCES[r]] = file.read("u32")
		DATA["trade_prices"] = {
			"schema_index": schema_index()
		}
		DataStruct.record_schema_item(DATA["trade_prices"])
		for r in range(0,36):
			DATA["trade_prices"][RESOURCES[r]] = {
				"buying": file.read("u32"),
				"selling": file.read("u32"),
			}
		DATA["figure_names_1"] = []
		for _i in range(0,21):
			DATA["figure_names_1"].push_back(file.read("i32", schema_index()))
		DATA["scenario_info"] = {
			"schema_index": schema_index(),
			"starting_year": file.read("i16"),
			"unk1": file.read("i16"),
			"empire_id": file.read("i16"),
			"unk2": file.read("i16"),
			"unk3": file.read("i16"),
			"gods_status": {
				"Osiris": file.read("i16"),
				"Ra": file.read("i16"),
				"Ptah": file.read("i16"),
				"Seth": file.read("i16"),
				"Bast": file.read("i16"),
			},
			"unk4": file.read(10),
#			{
#				"Osiris": file.read("i16"),
#				"Ra": file.read("i16"),
#				"Ptah": file.read("i16"),
#				"Seth": file.read("i16"),
#				"Bast": file.read("i16"),
#			},
			"unk5": file.read("i16"),
			"initial_funds": file.read("i32"),
			"enemy_id": file.read("i16"),
			"unk6": file.read("i16"),
			"unk7": file.read("i16"),
			"unk8": file.read("i16"),
			"map_width": file.read("i32"),
			"map_height": file.read("i32"),
			"grid_start": file.read("i32"),
			"grid_border_size": file.read("i32"),
			"scenario_subtitle": file.read("str64"),
			"scenario_description": file.read("str522"),
			"scenario_thumbnail_id": file.read("i16"),
			"open_play": file.read("i16"),
			"player_rank": file.read("i16"),
			"herd_points": construct_array(4,["x","y"],["i16","i16"], true),
			"fishing_points": construct_array(8,["x","y"],["i16","i16"], true),
			"alternate_animal": file.read("i16"),
			"unk9": file.read(42),
			"invasion_points": construct_invasion_points(),
			"unk10": file.read(36),
			"culture_goal": file.read("i32"),
			"prosperity_goal": file.read("i32"),
			"monument_goal": file.read("i32"),
			"kingdom_goal": file.read("i32"),
			"extra_goal_1": file.read("i32"),
			"extra_goal_2": file.read("i32"),
			"culture_enabled": file.read("u8", -1, "bool"),
			"prosperity_enabled": file.read("u8", -1, "bool"),
			"monument_enabled": file.read("u8", -1, "bool"),
			"kingdom_enabled": file.read("u8", -1, "bool"),
			"extra_1_enabled": file.read("u8", -1, "bool"),
			"extra_2_enabled": file.read("u8", -1, "bool"),
			"unk11": file.read(6),
			"time_limit_enabled": file.read("i32", -1, "bool"),
			"time_limit": file.read("i32"),
			"survival_limit_enabled": file.read("i32", -1, "bool"),
			"survival_limit": file.read("i32"),
			"population_enabled": file.read("i32", -1, "bool"),
			"population_goal": file.read("i32"),
			"earthquake": {
				"x": file.read("i16"),
				"y": file.read("i16"),
			},
			"city_entry_point": {
				"x": file.read("i16"),
				"y": file.read("i16"),
			},
			"city_exit_point": {
				"x": file.read("i16"),
				"y": file.read("i16"),
			},
			"unk12": file.read(32),
			"river_entry_point": {
				"x": file.read("i16"),
				"y": file.read("i16"),
			},
			"river_exit_point": {
				"x": file.read("i16"),
				"y": file.read("i16"),
			},
			"debt_bailout": file.read("i32"),
			"pop_milestone_1": file.read("i32"),
			"pop_milestone_2": file.read("i32"),
			"pop_milestone_3": file.read("i32"),
			"unk13": file.read(12),
			"climate_id": file.read("u8"),
			"unk14": file.read("i8"),
			"unk15": file.read("i8"),
			"unk16": file.read("i8"),
			"unk17": file.read(8),
			"monuments_era": file.read("u8"),
			"player_faction": file.read("u8"),
			"unk18": file.read("i8"),
			"unk19": file.read("i8"),
			"prey_points": construct_array(4,["x","y"],["i32","i32"], true),
			"enabled_buildings": {
				"unk0": file.read("i16", -1, "bool"),
				"unk1": file.read("i16", -1, "bool"),
				"Gold mine": file.read("i16", -1, "bool"),
				"Water lift": file.read("i16", -1, "bool"),
				"Irrigation ditch": file.read("i16", -1, "bool"),
				"Shipyard": file.read("i16", -1, "bool"),
				"Work camp": file.read("i16", -1, "bool"),
				"Granary": file.read("i16", -1, "bool"),
				"Market": file.read("i16", -1, "bool"),
				"Warehouse": file.read("i16", -1, "bool"),
				"Dock": file.read("i16", -1, "bool"),
				"Jugglers": file.read("i16", -1, "bool"),
				"Musicians": file.read("i16", -1, "bool"),
				"Dancers": file.read("i16", -1, "bool"),
				"Senet house": file.read("i16", -1, "bool"),
				"Festival square": file.read("i16", -1, "bool"),
				"Scribal school": file.read("i16", -1, "bool"),
				"Library": file.read("i16", -1, "bool"),
				"Water supply": file.read("i16", -1, "bool"),
				"Dentist": file.read("i16", -1, "bool"),
				"Apothecary": file.read("i16", -1, "bool"),
				"Physician": file.read("i16", -1, "bool"),
				"Mortuary": file.read("i16", -1, "bool"),
				"Tax collector": file.read("i16", -1, "bool"),
				"Courthouse": file.read("i16", -1, "bool"),
				"Palace": file.read("i16", -1, "bool"),
				"Mansion": file.read("i16", -1, "bool"),
				"Roadblock": file.read("i16", -1, "bool"),
				"Bridge": file.read("i16", -1, "bool"),
				"Ferry": file.read("i16", -1, "bool"),
				"Garden": file.read("i16", -1, "bool"),
				"Plaza": file.read("i16", -1, "bool"),
				"Statues": file.read("i16", -1, "bool"),
				"Wall": file.read("i16", -1, "bool"),
				"Tower": file.read("i16", -1, "bool"),
				"Gatehouse": file.read("i16", -1, "bool"),
				"Recruiter": file.read("i16", -1, "bool"),
				"Fort (infantry)": file.read("i16", -1, "bool"),
				"Fort (archers)": file.read("i16", -1, "bool"),
				"Fort (charioteers)": file.read("i16", -1, "bool"),
				"Academy": file.read("i16", -1, "bool"),
				"Weaponsmith": file.read("i16", -1, "bool"),
				"Chariot maker": file.read("i16", -1, "bool"),
				"Warship wharf": file.read("i16", -1, "bool"),
				"Transport wharf": file.read("i16", -1, "bool"),
				"Zoo": file.read("i16", -1, "bool"),
				"unk3": file.read(58*2),
				"Temple complex (Osiris)": file.read("i16", -1, "bool"),
				"Temple complex (Ra)": file.read("i16", -1, "bool"),
				"Temple complex (Ptah)": file.read("i16", -1, "bool"),
				"Temple complex (Seth)": file.read("i16", -1, "bool"),
				"Temple complex (Bast)": file.read("i16", -1, "bool"),
				"unk4": file.read(5*2),
			},
			"disembark_points": construct_array(3,["x","y"],["i32","i32"], true),
			"interest_on_debt": file.read("i32"),
			"monument_1": file.read("u16"),
			"monument_2": file.read("u16"),
			"monument_3": file.read("u16"),
			"unk20": file.read("u16"),
		}
		DATA["scenario_info"]["burial_provisions"] = {
			"required": {},
			"dispatched": {},
		}
		for r in range(0,36):
			DATA["scenario_info"]["burial_provisions"].required[RESOURCES[r]] = file.read("i32")
		for r in range(0,36):
			DATA["scenario_info"]["burial_provisions"].dispatched[RESOURCES[r]] = file.read("i32")
		DATA["scenario_info"]["current_pharaoh"] = file.read("i32")
		DATA["scenario_info"]["player_incarnation"] = file.read("i32")
		DataStruct.record_schema_item(DATA["scenario_info"])
		DATA["max_year"] = file.read("i32", schema_index())
		DATA["messages"] = file.read_zip_chunk(schema_index())
		DATA["messages_extra"] = {
			"messages_total_ever": file.read("i32", schema_index()),
			"messages_total_current": file.read("i32", schema_index()),
			"last_message_mouseover_index": file.read("i32", schema_index()),
			"census_messages": construct_empty_schema_indexed_arr(schema_index()),
			"message_counts": construct_empty_schema_indexed_arr(schema_index()),
			"message_delays": construct_empty_schema_indexed_arr(schema_index()),
		}
		for _i in range(0,10):
			DATA["messages_extra"]["census_messages"].value.push_back(file.read("i8"))
		for _i in range(0,20):
			DATA["messages_extra"]["message_counts"].value.push_back(file.read("i32"))
		for _i in range(0,20):
			DATA["messages_extra"]["message_delays"].value.push_back(file.read("i32"))
		
		DATA["burning_buildings_total"] = file.read("i32", schema_index())
		DATA["burning_buildings_size"] = file.read("i32", schema_index())
		DATA["figures_sequence_phase"] = file.read("i32", schema_index())
		DATA["starting_kingdom"] = file.read("i32", schema_index())
		DATA["starting_savings"] = file.read("i32", schema_index())
		DATA["starting_rank"] = file.read("i32", schema_index())
		DATA["invasion_warnings"] = file.read_zip_chunk(schema_index())
		DATA["scenario_is_custom"] = file.read("i32", schema_index())
		DATA["city_sounds"] = construct_empty_schema_indexed_arr(schema_index())
		for _i in range(0,70):
			var datachunk = {}
			datachunk["channel_available"] = file.read("i32", -1, "bool")
			datachunk["channel_total_views"] = file.read("i32")
			datachunk["channel_views_threshold"] = file.read("i32")
			datachunk["direction_views"] = []
			for _b in range(0,5):
				datachunk["direction_views"].push_back(file.read("i32"))
			datachunk["last_channel"] = file.read("i32")
			datachunk["total_channels"] = file.read("i32")
			datachunk["channel"] = file.read("i32")
			for b in range(0,7):
				datachunk[str("unk",b)] = file.read("i32")
			datachunk["in_use"] = file.read("i32", -1, "bool")
			datachunk["times_played"] = file.read("u32")
			datachunk["last_played_time"] = file.read("u32")
			datachunk["delay_millis"] = file.read("i32")
			datachunk["should_play"] = file.read("i32", -1, "bool")
			for b in range(0,9):
				datachunk[str("unk",b+6)] = file.read("i32")
			
			DATA["city_sounds"].value.push_back(datachunk)
		DATA["building_highest_id"] = file.read("i32", schema_index())
		
		DATA["figure_traders"] = construct_empty_schema_indexed_arr(schema_index())
		for _i in range(0,100):
			var datachunk = {
				"bought_amount": file.read("i32"),
				"sold_amount": file.read("i32"),
				"bought_resources": {},
				"sold_resources": {},
			}
			for r in range(0,36):
				datachunk["bought_resources"][RESOURCES[r]] = file.read("u8")
			for r in range(0,36):
				datachunk["sold_resources"][RESOURCES[r]] = file.read("u8")
			datachunk["bought_value"] = file.read("i32")
			datachunk["sold_value"] = file.read("i32")
			DATA["figure_traders"].value.push_back(datachunk)
		DATA["next_free_trader_id"] = file.read("i32", schema_index())
		DATA["buildings_list_burning"] = file.read_zip_chunk(schema_index())
		DATA["buildings_list_small"] = file.read_zip_chunk(schema_index())
		DATA["buildings_list_large"] = file.read_zip_chunk(schema_index())
		DATA["is_campaign_mission_first"] = file.read("i32", schema_index())
		DATA["is_campaign_mission_first_four"] = file.read("i32", schema_index())
		DATA["figure_names_3"] = []
		for _i in range(0,4):
			DATA["figure_names_3"].push_back(file.read("i32", schema_index()))
		DATA["tick_countdown_frogs"] = file.read("i32", schema_index())
		DATA["tick_countdown_pyramid_speedup"] = file.read("i32", schema_index())
		DATA["tick_countdown_blood1"] = file.read("i32", schema_index())
		DATA["unk5"] = {
			"unk1": file.read("i32", schema_index()),
			"unk2": file.read("i32", schema_index()),
			"unk3": file.read("i32", schema_index()),
			"unk4": file.read("i32", schema_index()),
			"unk5": file.read("i32", schema_index()),
		}
		DATA["building_storages"] = construct_empty_schema_indexed_arr(schema_index())
		for _i in range(0,200):
			DATA["building_storages"].value.push_back({
				"data": file.read(196) # temp
			})
		DATA["trade_routes_limits"] = file.read_zip_chunk(schema_index())
		DATA["trade_routes_traded"] = file.read_zip_chunk(schema_index())
		DATA["working_towers"] = file.read("i32", schema_index())
		DATA["building_creation_highest_id"] = file.read("i32", schema_index())
		DATA["routing_debug"] = {
			"unused1": file.read("i32", schema_index()),
			"routing_count_1": file.read("i32", schema_index()),
			"routing_count_2": file.read("i32", schema_index()),
			"unused2": file.read("i32", schema_index()),
		}
		DATA["unk9"] = {
			"unk1": file.read("i32", schema_index()),
			"unk2": file.read("i32", schema_index()),
			"unk3": file.read("i32", schema_index()),
			"unk4": file.read("i32", schema_index()),
		}
		DATA["invasions_creation_sequence"] = file.read("i16", schema_index())
		DATA["corrupt_house_coords_repaired"] = file.read("i32", schema_index())
		DATA["corrupt_house_coords_deleted"] = file.read("i32", schema_index())
		DATA["scenario_name"] = file.read("str65", schema_index())
		DATA["bookmarks"] = construct_empty_schema_indexed_arr(schema_index())
		for _i in range(0,4):
			DATA["bookmarks"].value.push_back({
				"tile": file.read("i32"),
				"unk1": file.read("i16"),
				"unk2": file.read("i16"),
			})
		DATA["tick_countdown_blood2"] = file.read("i32", schema_index())
		DATA["unk14"] = {
			"unk1": file.read("i32", schema_index()),
			"unk2": file.read("i32", schema_index()),
		}
		DATA["unk15"] = construct_empty_schema_indexed_arr(schema_index())
		for _i in range(0,99):
			DATA["unk15"].value.push_back({
				"unk": file.read("i32"),
			})
		DATA["soil_fertility_grid"] = file.read_grid(1, schema_index())
		DATA["scenario_events"] = construct_empty_schema_indexed_arr(schema_index())
		for _e in range(0,150):
			var event = {
				"total_num_header": file.read("i16"),
				"unk1": file.read("i16"),
				"event_id": file.read("i16"),
				"type": file.read("i8"),
				"month": file.read("i8"),
				"items": []
			}
			for _i in range(0,4):
				event.items.push_back({
					"item":0,
					"amount":0,
					"time":0,
					"location":0,
					"route":0,
				})
			for i in range(0,4):
				event.items[i].item = file.read("i16")
			for i in range(0,4):
				event.items[i].amount = file.read("i16")
			for i in range(0,4):
				event.items[i].time = file.read("i16")
			for i in range(0,4):
				event.items[i].location = file.read("i16")
			event["on_completed_action"] = file.read("i16")
			event["on_refusal_action"] = file.read("i16")
			event["event_trigger_type"] = file.read("i16")
			event["unk2"] = file.read("i16")
			event["months_initial"] = file.read("i16")
			event["months_left"] = file.read("i16")
			event["event_state"] = file.read("i16")
			event["is_active"] = file.read("i16")
			event["unk3"] = file.read("i16")
			event["festival_deity"] = file.read("i8")
			event["unk4"] = file.read("i8")
			event["invasion_attack_target"] = file.read("i8")
			
			event["unk5"] = file.read(25)
			event["on_toolate_action"] = file.read("i16")
			event["on_defeat_action"] = file.read("i16")
			event["sender_faction"] = file.read("i8")
			event["unk6"] = file.read("i8")
			for i in range(0,4):
				event.items[i].route = file.read("i16")
			event["subtype"] = file.read("i8")
			event["unk7"] = file.read("i8")
			event["unk8"] = file.read("i16")
			event["unk9"] = file.read("i16")
			event["unk10"] = file.read("i16")
			event["unk11"] = file.read("i16")
			event["on_completed_msg_alt"] = file.read("i8")
			event["on_refusal_msg_alt"] = file.read("i8")
			event["on_toolate_msg_alt"] = file.read("i8")
			event["on_defeat_msg_alt"] = file.read("i8")
			event["unk12"] = file.read("i16")
			event["unk13"] = file.read("i16")
			event["unk14"] = file.read("i16")
			event["unk15"] = file.read("i16")
			event["unk16"] = file.read("i16")
			
			DATA["scenario_events"].value.push_back(event)
		DATA["scenario_events_extra"] = {}
		for b in range(0,7):
			DATA["scenario_events_extra"][str("unk",b)] = file.read("i32")
		DATA["ferry_queues"] = construct_empty_schema_indexed_arr(schema_index())
		for _i in range(0,50):
			if DATA.header.version.value >= 149:
				DATA["ferry_queues"].value.push_back(file.read(224))
			else:
				DATA["ferry_queues"].value.push_back(file.read(220))
		DATA["ferry_transiting"] = construct_empty_schema_indexed_arr(schema_index())
		for _i in range(0,50):
			DATA["ferry_transiting"].value.push_back(file.read(44))
		DATA["unused_figure_sequences"] = construct_empty_schema_indexed_arr(schema_index())
		for _i in range(0,4):
			DATA["unused_figure_sequences"].value.push_back(file.read("i32"))
		DATA["unused_10_x_820"] = construct_empty_schema_indexed_arr(schema_index())
		for _i in range(0,10):
			DATA["unused_10_x_820"].value.push_back(file.read(820))
		DATA["unused_empires_40_x_32"] = file.read_zip_chunk(schema_index())
		DATA["empire_map_objects"] = file.read_zip_chunk(schema_index())
		DATA["empire_map_routes"] = file.read_zip_chunk(schema_index())
		DATA["vegetation_growth"] = file.read_grid(1, schema_index())
		DATA["unk21"] = {
			"schema_index": schema_index(),
			"unk1": file.read("i32"),
			"unk2": file.read("i32"),
			"unk3": file.read("i32"),
			"unk4": file.read("i32"),
			"unk5": file.read("u8"),
			"unk6": file.read("u8"),
			"unk7": file.read("u8"),
			"unk8": file.read("u8"),
		}
		DataStruct.record_schema_item(DATA["unk21"])
		DATA["unk22"] = construct_empty_schema_indexed_arr(schema_index(), construct_array(22,["bizarre_1"],[24]))
		
		DATA["floodplain_settings"] = file.read_zip_chunk(schema_index())
		DATA["unk23"] = file.read_zip_chunk(schema_index()) # unknown grid
		DATA["unk24"] = construct_empty_schema_indexed_arr(schema_index(), construct_array(13,["bizarre_4"],[24]))
		DATA["figure_names_2"] = []
		for _i in range(0,16):
			DATA["figure_names_2"].push_back(file.read("i32", schema_index()))
		DATA["tutorial_1"] = construct_empty_schema_indexed_arr(schema_index())
		for _i in range(0,26):
			DATA["tutorial_1"].value.push_back(file.read("u8", -1, "bool"))
		DATA["tutorial_2"] = construct_empty_schema_indexed_arr(schema_index())
		for _i in range(0,15):
			DATA["tutorial_2"].value.push_back(file.read("u8", -1, "bool"))
		DATA["unk26"] = file.read_zip_chunk(schema_index()) # unknown grid
		DATA["mission_play_type"] = file.read("u8", schema_index()) # 0: custom 1: first time campaign 2: ind. mission sel. 3: campaign sel.
		DATA["moisture_grid"] = file.read_zip_chunk(schema_index())
		DATA["unk28"] = construct_empty_schema_indexed_arr(schema_index(), construct_array(10,["bizarre_2"],[24]))
		DATA["unk29"] = construct_empty_schema_indexed_arr(schema_index(), construct_array(18,["bizarre_3"],[24]))
		DATA["unk30"] = file.read("i32", schema_index())
		DATA["difficulty"] = file.read("i32", schema_index())
		if DATA.header.version.value >= 160:
			DATA["company_rejoin"] = {
				"schema_index": schema_index(),
				"savings": file.read("i32"),
				"company_name_id": file.read("i8"),
				"unk3": file.read("i8"),
				"unk4": file.read("i8"),
				"unk5": file.read("i8"),
				"company_skill": file.read("i32"),
			}
			DataStruct.record_schema_item(DATA["company_rejoin"])
			DATA["unk33"] = construct_empty_schema_indexed_arr(schema_index(), construct_array(27,["bizarre_5"],[24]))
			DATA["unk34"] = construct_empty_schema_indexed_arr(schema_index(), construct_array(27,["bizarre_6"],[24]))
			DATA["unk35"] = construct_empty_schema_indexed_arr(schema_index(), construct_array(15,["bizarre_7"],[24]))
			DATA["unk36"] = construct_empty_schema_indexed_arr(schema_index(), construct_array(56,["bizarre_8"],[24]))
			DATA["unk37"] = construct_empty_schema_indexed_arr(schema_index(), construct_array(75,["bizarre_9"],[24]))
	
	path = IO.get_folder_split_path(path)
	var file_name = path[path.size()-1]
	log_text(str("'",file_name,"' read successfully!"))
	
	# after loading the data, parse it and fill the tables / trees / textboxes etc. with it
	fill_ChunkTable()
	fill_SchemaTable()
	refresh_select_ChunkTable()
func fill_SaveTable():
	SaveTable.clear()
	SaveTable.create_item()
	var contents = IO.dir_contents("G:/SteamLibrary/steamapps/common/Pharaoh + Cleopatra/Save/")
	for profile in contents.folders:
		var profile_item = SaveTable.create_item()
		profile_item.set_text(0, profile)
		for save in IO.dir_contents(str("G:/SteamLibrary/steamapps/common/Pharaoh + Cleopatra/Save/",profile)).files:
			var save_item = SaveTable.create_item(profile_item)
			save_item.set_text(0, save)

# ChunkTable
var selected_ChunkTable_path = []
func fill_ChunkTable():
	ChunkTable.clear()
	ChunkTable.create_item()
	recursive_fill_ChunkTable(DATA, null, null)
	DataStruct.schema_items_names = {}
	DataStruct.record_schema_names_recursive(ChunkTable.get_root().get_children())
func recursive_fill_ChunkTable(item, parent, itemname):
	# add the current one to the list
	var table_item = null
	if itemname != null:
		table_item = ChunkTable.create_item(parent)
		table_item.collapsed = true
		table_item.set_metadata(0, [itemname,item])
		if itemname.begins_with("unk"):
			itemname = "??"
			table_item.set_custom_color(0, Color(1,1,1,0.3))
		elif itemname.begins_with("unused"):
			table_item.set_custom_color(0, Color(1,0.7,0.7,0.5))
#			table_item.set_custom_color(0, Color(1,1,1,0.3))
	
	var total_bytes = 0
	
	# follow through the childs
	if DataStruct.is_valid(item):
		total_bytes += item.size
	else:
		if item is Dictionary && item.has("value"):
			item = item.value
		if item is Dictionary:
			for k in item:
				if k == "offset" || k == "schema_index":
					continue
				total_bytes += recursive_fill_ChunkTable(item[k], table_item, str(k))
		elif item is Array:
			for e in item.size():
				total_bytes += recursive_fill_ChunkTable(item[e], table_item, str("[",e,"]"))
	
	if itemname != null:
		if item is Dictionary && "compressed_size" in item:
			table_item.set_text(0, str(itemname," (",total_bytes,") **"))
			table_item.set_custom_color(0, Color(0.8,0.8,0))
		else:
			table_item.set_text(0, str(itemname," (",total_bytes,")"))
	return total_bytes
func get_selected_path(node, list, use_metadata = true, ignore_root = true):
	var parent = node.get_parent()
	if parent == null && ignore_root:
		return list
	else:
		if use_metadata:
			list.push_front(node.get_metadata(0)[0])
		else:
			list.push_front(node.get_text(0))
		if parent != null:
			return get_selected_path(parent, list, use_metadata, ignore_root)
		else:
			return list
func set_selected_path(node, list):
	if list.size() == 0:
		return null
	var child = node.get_children()
	while child != null:
		if list[0] == child.get_metadata(0)[0]:
			list.pop_front()
			if list.size() == 0:
				return child
			child.collapsed = false
			return set_selected_path(child, list)
		child = child.get_next()
	return null
func refresh_select_ChunkTable():
	DataTable.clear()
	var selection = set_selected_path(ChunkTable.get_root(), selected_ChunkTable_path.duplicate())
	if selection != null:
		selection.select(0) # this already calls the signal!

# SchemaTable & SchemaMemoryTable
var SchemaMemoryTable_treeitem_lookup = [] # TODO: move this into a class for every Tree item god please
func fill_SchemaTable():
	SchemaTable.clear()
	SchemaTable.create_item()
	SchemaTable.columns = 6
	SchemaTable.set_column_title(0,"#")
	SchemaTable.set_column_title(1,"zip")
	SchemaTable.set_column_title(2,"address")
	SchemaTable.set_column_title(3,"count")
	SchemaTable.set_column_title(4,"size")
	SchemaTable.set_column_title(5,"??")
	SchemaTable.set_column_min_width(0, 1)
	SchemaTable.set_column_min_width(1, 3)
	SchemaTable.set_column_min_width(2, 3)
	SchemaTable.set_column_min_width(3, 2)
	SchemaTable.set_column_min_width(4, 3)
	SchemaTable.set_column_min_width(5, 1)
	var memory_addresses = {}
	for c in range(0,300):
		var chunk = DATA.schema_data.value[c]
		var table_item = SchemaTable.create_item()
		table_item.set_text(0,str(c))
		table_item.set_text(1,DataStruct.as_text(chunk.compressed))
		table_item.set_text(2,DataStruct.as_text(chunk.address))
		table_item.set_text(3,DataStruct.as_text(chunk.count))
		table_item.set_text(4,DataStruct.as_text(chunk.size))
		table_item.set_text(5,DataStruct.as_text(chunk.unknown))
		table_item.set_custom_color(0, Color(1,1,1,0.3))
		if chunk.compressed.value as bool:
			table_item.set_custom_color(1, Color(0.8,0.8,0))
			table_item.set_custom_color(2, Color(0.8,0.8,0))
			table_item.set_custom_color(3, Color(0.8,0.8,0))
			table_item.set_custom_color(4, Color(0.8,0.8,0))
			table_item.set_custom_color(5, Color(0.8,0.8,0))
		if c < DATA.schema_count.value:
			memory_addresses[chunk.address.value] = c
		else:
			table_item.set_custom_color(1, Color(1,1,1,0.3))
			table_item.set_custom_color(2, Color(1,1,1,0.3))
			table_item.set_custom_color(3, Color(1,1,1,0.3))
			table_item.set_custom_color(4, Color(1,1,1,0.3))
			table_item.set_custom_color(5, Color(1,1,1,0.3))
	
	SchemaMemoryTable_treeitem_lookup = []
	SchemaMemoryTable.clear()
	SchemaMemoryTable.create_item()
	SchemaMemoryTable.set_column_title(0,"address")
	SchemaMemoryTable.set_column_title(1,"#")
	SchemaMemoryTable.set_column_title(2,"item")
	SchemaMemoryTable.set_column_title(3,"data")
	SchemaMemoryTable.set_column_title(4,"process")
	SchemaMemoryTable.set_column_min_width(0, 3)
	SchemaMemoryTable.set_column_min_width(1, 1)
	SchemaMemoryTable.set_column_min_width(2, 3)
	SchemaMemoryTable.set_column_min_width(3, 2)
	SchemaMemoryTable.set_column_min_width(4, 2)
	var ordered_addresses = memory_addresses.keys()
	ordered_addresses.sort()
	for address in ordered_addresses:
		var index = memory_addresses[address]
		var memorytable_item = SchemaMemoryTable.create_item()
		var itemname = DataStruct.schema_items_names[index][0]
		if itemname.begins_with("unk"):
			itemname = "??"
			memorytable_item.set_custom_color(0, Color(1,1,1,0.3))
			memorytable_item.set_custom_color(1, Color(1,1,1,0.3))
			memorytable_item.set_custom_color(2, Color(1,1,1,0.3))
			memorytable_item.set_custom_color(3, Color(1,1,1,0.3))
		memorytable_item.set_custom_color(4, Color(1,1,1,0.3))
		memorytable_item.set_text(0, "0x%08X" % [address])
		memorytable_item.set_text(1, str(index))
		memorytable_item.set_text(2, itemname)
		memorytable_item.set_text(3, DataStruct.as_text(DataStruct.schema_items[index]))
		memorytable_item.set_text(4, "??")
		memorytable_item.set_metadata(0, address)
		SchemaMemoryTable_treeitem_lookup.push_back(memorytable_item)


# Called when the node enters the scene tree for the first time.
func _ready():
	fill_SaveTable()
	open_file("G:/SteamLibrary/steamapps/common/Pharaoh + Cleopatra/Save/Banhutep/test.sav")
	processID = GDNScraper.open("Pharaoh.exe")


var processID = -1
func cleanup():
	if processID != -1:
		for memorytable_item in SchemaMemoryTable_treeitem_lookup:
			memorytable_item.set_text(4, "??")
			memorytable_item.set_custom_color(4, Color(1,1,1,0.3))
	processID = -1
func update_process_hook(delta):
	# check if process is alive & hook to it
	if processID == -1:
		if waitfor(1.0, delta):
			processID = GDNScraper.open("Pharaoh.exe")
			if processID != -1:
				print("Hooked: PID ",processID)
	if processID == -1:
		cleanup()
		return false
		
	# update timer step
	if !waitfor(0.0, delta):
		return false
	
	# test that the process handle is still valid!
	GDNScraper.scrape(0x0000000, 4)
	if GDNScraper.getLastError() != 0:
		cleanup()
		return false
	return true
func update_memory_scraping():
	
	# update schema chunks
	if $Control.visible:
		for memorytable_item in SchemaMemoryTable_treeitem_lookup:
			memorytable_item.set_custom_color(4, Color(1,1,1,1))
			var address = memorytable_item.get_metadata(0) - GDNScraper.baseAddress
			var index = memorytable_item.get_text(1).to_int()
			var datastruct = DataStruct.schema_items[index]
			
			if DataStruct.is_valid(datastruct):
				var size_to_scrape = min(8, datastruct.size)
				var scraped = GDNScraper.scrape(address, size_to_scrape)
				if datastruct.type == "[char]" || datastruct.type == "bytes" || datastruct.type.begins_with("grid"):
					scraped = var2bytes(scraped)
				elif datastruct.type.begins_with("i"):
						scraped = file.u_to_i(scraped, datastruct.type.to_int())
				memorytable_item.set_text(4, DataStruct.as_text(datastruct, scraped))
				if scraped != datastruct.value:
					memorytable_item.set_custom_color(4, Color(1,0,1,1))
			else:
				memorytable_item.set_text(4, "[ ... ]")
				
	elif $Control2.visible:
		$Control2/unk10a.text = "unk10a:\n"
		var unk10a = []
		
		$Control2/unk10b.text = "unk10b:\n"
		var unk10b = []
		
		for i in range(0,50):
			unk10a.push_back({
				"in_use": GDNScraper.scrape_abs(0x00EAAF68 + i * 224, 4),
				"unk_0x4": GDNScraper.scrape_abs(0x00EAAF68 + i * 224 + 4, 4),
				"unk_0x8": GDNScraper.scrape_abs(0x00EAAF68 + i * 224 + 8, 4),
				"unk_50_counter": GDNScraper.scrape_abs(0x00EAAF68 + i * 224 + 12, 4),
				"unk_0x10": GDNScraper.scrape_abs(0x00EAAF68 + i * 224 + 16, 4),
				"array": [],
				"building_id": GDNScraper.scrape_abs(0x00EAAF68 + i * 224 + 220, 4),
			})
			for k in range(0,50):
				var val = GDNScraper.scrape_abs(0x00EAAF68 + i * 224 + 20 + k*4, 4)
				if val != 0:
					unk10a[i].array.push_back(GDNScraper.scrape_abs(0x00EAAF68 + i * 224 + 20 + k*4, 4))
			unk10b.push_back({
				"in_use": GDNScraper.scrape_abs(0x009784D8 + i * 44, 4),
				"figure_ids": [
					DataStruct.u_to_i(GDNScraper.scrape_abs(0x009784D8 + i * 44 + 4*1, 4),32),
					DataStruct.u_to_i(GDNScraper.scrape_abs(0x009784D8 + i * 44 + 4*2, 4),32),
					DataStruct.u_to_i(GDNScraper.scrape_abs(0x009784D8 + i * 44 + 4*3, 4),32),
					DataStruct.u_to_i(GDNScraper.scrape_abs(0x009784D8 + i * 44 + 4*4, 4),32),
					DataStruct.u_to_i(GDNScraper.scrape_abs(0x009784D8 + i * 44 + 4*5, 4),32),
					DataStruct.u_to_i(GDNScraper.scrape_abs(0x009784D8 + i * 44 + 4*6, 4),32),
					DataStruct.u_to_i(GDNScraper.scrape_abs(0x009784D8 + i * 44 + 4*7, 4),32),
					DataStruct.u_to_i(GDNScraper.scrape_abs(0x009784D8 + i * 44 + 4*8, 4),32),
					DataStruct.u_to_i(GDNScraper.scrape_abs(0x009784D8 + i * 44 + 4*9, 4),32),
					DataStruct.u_to_i(GDNScraper.scrape_abs(0x009784D8 + i * 44 + 4*10, 4),32),
				]
			})
			if unk10a[i].in_use:
				$Control2/unk10a.text += "%d %d %d %d %d %s\n" % [
					unk10a[i].unk_0x4,
					unk10a[i].unk_0x8,
					unk10a[i].unk_50_counter,
					unk10a[i].unk_0x10,
					unk10a[i].building_id,
					str(unk10a[i].array)]

			if unk10b[i].in_use:
				$Control2/unk10b.text += str(unk10b[i].figure_ids,"\n")
	
	elif $Control3.visible:
		$Control3/test.text = "tutorial_1:\ndone: p_tut2:                  #n: msg_id: UNK map: UNK p_unk"
		$Control3/test_b.text = "\n"
		$Control3/test2.text = "tutorial_2:"
		$Control3/test3.text = "tutorial_2_index_table:"
		for i in range(0,26):
			var tut1_field = {
				"complete": GDNScraper.scrape_abs(0x007027B8 + i, 1),
				"tut2_count": GDNScraper.scrape_abs(0x005794A0 + i * 28, 4),
				"p_tut2_indices": GDNScraper.scrape_abs(0x005794A0 + i * 28 + 4*1, 4),
				"message_id": GDNScraper.scrape_abs(0x005794A0 + i * 28 + 4*2, 4),
				"unk2": GDNScraper.scrape_abs(0x005794A0 + i * 28 + 4*3, 4),
				"map_index": GDNScraper.scrape_abs(0x005794A0 + i * 28 + 4*4, 4),
				"unk3": GDNScraper.scrape_abs(0x005794A0 + i * 28 + 4*5, 4),
				"p_unk": GDNScraper.scrape_abs(0x005794A0 + i * 28 + 4*6, 4),
			}
			var has_valid_indices = tut1_field.p_tut2_indices > 0x005793E8
			$Control3/test.text += str("\n",
				"",tut1_field.complete,
				"     ","0x%08X (%2d)" % [ tut1_field.p_tut2_indices,
										   (tut1_field.p_tut2_indices - 0x005793E8) / 4 if has_valid_indices else -1 ],
				"          ",tut1_field.tut2_count,
				"   ","%-3d" % [tut1_field.message_id],
				"     ",tut1_field.unk2,
				"   ","%-2d" % [tut1_field.map_index],
				"   ",tut1_field.unk3,
				"   ","0x%08X" % [tut1_field.p_unk]
				)
			$Control3/test_b.text += "\n"
			if has_valid_indices:
				var arr = []
				for j in tut1_field.tut2_count:
					arr.push_back(GDNScraper.scrape_abs(tut1_field.p_tut2_indices + j*4, 4))
				$Control3/test_b.text += str("                      ", arr)
			else:
				$Control3/test_b.text += "                      -"
		for i in range(0,15):
			var tut2 = GDNScraper.scrape_abs(0x006FDC88 + i, 1)
			$Control3/test2.text += str("\n",tut2)
		for i in range(0,46):
			var tut2_index = GDNScraper.scrape_abs(0x005793E8 + i*4, 4)
			$Control3/test3.text += str("\n","%2d: "%[i],tut2_index)

# Called every frame. 'delta' is the elapsed time since the previous frame.
var wait_t = 0
func waitfor(amount, delta):
	if amount == 0:
		return true
	wait_t += delta
	if wait_t > amount:
		while wait_t > amount:
			wait_t -= amount
		return true
	return false
var t = 0
func log_text(txt):
		Log.generic(null,txt)
		$LogLabel2.text = txt
		t = 0
func _process(delta):
	t += delta
	if t > 2:
		$LogLabel2.text = ""
	
	if !update_process_hook(delta):
		$LogLabel.text = "Waiting for process..."
		return
	$LogLabel.text = "Hooked into Pharaoh.exe"
	update_memory_scraping()

func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
			
		fill_SaveTable()
		
		if file_path != null:
			open_file(file_path)

func copy_to_clipboard(txt):
	OS.set_clipboard(txt)
	log_text(str("Copied to clipboard: ",txt))

func scroll_proper_to_item(table, item):
	if table.get_selected() != item:
		var parent = item.get_parent()
		while parent != null:
			parent.collapsed = false
			parent = parent.get_parent()
		item.select(0)
	table.ensure_cursor_is_visible()

func _on_ChunkTable_cell_selected():
	var selection = ChunkTable.get_selected()
	var data = selection.get_metadata(0)
	DataTable.clear()
	DataTable.present(data[0], data[1])
	selected_ChunkTable_path = get_selected_path(selection, [])
	
	# select associated schema items
	if data[1] is Dictionary:
		var index = data[1].get("schema_index", -1)
		if index != -1:
			var address = SchemaTable.get_root().get_children()
			while address != null:
				if address.get_text(0).to_int() == index:
					copy_to_clipboard(address.get_text(2))
					return scroll_proper_to_item(SchemaTable, address)
				else:
					address = address.get_next()
		

func _on_SaveTable_cell_selected():
	var sav = SaveTable.get_selected()
	if sav.get_parent().get_parent() == null:
		return # this is a profile name, not a save file!
	var path_arr = get_selected_path(sav, [], false, false)
	var path = str("G:/SteamLibrary/steamapps/common/Pharaoh + Cleopatra/Save/","/".join(path_arr))
	open_file(path)
	
func _on_SchemaTable_item_selected():
	var item = SchemaTable.get_selected()
	var index = item.get_text(0)

	if DataStruct.schema_items_names.has(index.to_int()):
		scroll_proper_to_item(ChunkTable, DataStruct.schema_items_names[index.to_int()][1])
	
	var address = SchemaMemoryTable.get_root().get_children()
	while address != null:
		if address.get_text(1) == index:
			return scroll_proper_to_item(SchemaMemoryTable, address)
		else:
			address = address.get_next()

func _on_SchemaMemoryTable_item_selected():
	var address = SchemaMemoryTable.get_selected()
	var index = address.get_text(1)
	var item = SchemaTable.get_root().get_children()
	while item != null:
		if item.get_text(0) == index:
			return scroll_proper_to_item(SchemaTable, item)
		else:
			item = item.get_next()
