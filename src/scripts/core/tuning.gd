class_name Tuning
## Loads all tuning constants from data files (golden rule 9: zero balance
## constants in .gd files). Loaded once, cached in static dictionaries.

static var climate: Dictionary = {}
static var society: Dictionary = {}


static func ensure_loaded() -> void:
	if climate.is_empty():
		climate = _load_json("res://data/climate.json")
	if society.is_empty():
		society = _load_json("res://data/society.json")


static func _load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed is Dictionary, "Failed to parse %s" % path)
	return parsed


static func c(key: String) -> Variant:
	ensure_loaded()
	return climate[key]


static func s(key: String) -> Variant:
	ensure_loaded()
	return society[key]
