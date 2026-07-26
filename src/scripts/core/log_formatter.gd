class_name LogFormatter
## Renders every player-visible log line from TurnRecord fields through the
## templates in data/log_templates.json (docs/Phase_4/06: no view computes).

const TEMPLATES_PATH := "res://data/log_templates.json"

static var templates: Dictionary = {}


static func ensure_loaded() -> void:
	if templates.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEMPLATES_PATH))
		assert(parsed is Dictionary, "Failed to parse log templates")
		templates = parsed


## Render templates[section][id] with {key} placeholders from fields.
static func render(section: String, id: String, fields: Dictionary = {}) -> String:
	ensure_loaded()
	var sect: Dictionary = templates.get(section, {})
	var tpl: String = sect.get(id, "")
	if tpl.is_empty():
		return "[missing template %s/%s]" % [section, id]
	return interpolate(tpl, fields)


static func has_template(section: String, id: String) -> bool:
	ensure_loaded()
	return templates.get(section, {}).has(id)


static func interpolate(tpl: String, fields: Dictionary) -> String:
	var out := tpl
	for key in fields:
		out = out.replace("{%s}" % key, fmt(fields[key]))
	return out


## Number formatting: whole numbers as ints, else one decimal.
static func fmt(v: Variant) -> String:
	if v is float:
		var f: float = v
		if absf(f - roundf(f)) < 0.005:
			return str(int(roundf(f)))
		return "%.1f" % f
	return str(v)
