class_name Catalog
extends RefCounted
## Loads and validates all JSON content at boot. Fails loud: any schema error
## names the file and entry. The validator is the compiler for JSON.
## Pure — no Nodes, no scene tree.

const ATOM_TYPES := ["money", "support", "absorption", "sector_emissions", "sector_income", "income_per_turn", "gross_this_turn"]
const ARCHETYPES := ["pay", "absorb", "mortgage", "invest"]
const CRISIS_KINDS := ["crisis", "windfall"]

var config: Dictionary = {}
var cards: Array = []          # Array[Dictionary], deck order as authored
var cards_by_id: Dictionary = {}
var crises: Array = []
var crises_by_id: Dictionary = {}
var combos: Array = []

var errors: PackedStringArray = []


static func load_all(base_path: String = "res://data") -> Catalog:
	var cat := Catalog.new()
	cat.config = cat._read_json(base_path + "/config.json")
	cat.cards = cat._read_json(base_path + "/cards.json").get("cards", [])
	cat.crises = cat._read_json(base_path + "/crises.json").get("crises", [])
	cat.combos = cat._read_json(base_path + "/combos.json").get("combos", [])
	cat._validate()
	if not cat.errors.is_empty():
		for e in cat.errors:
			push_error("[catalog] " + e)
		return null
	for c in cat.cards:
		cat.cards_by_id[c.id] = c
	for c in cat.crises:
		cat.crises_by_id[c.id] = c
	return cat


func sector_ids() -> Array:
	var ids := []
	for s in config.get("sectors", []):
		ids.append(s.id)
	return ids


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("missing file: " + path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		errors.append("invalid JSON in " + path)
		return {}
	return parsed


func _validate() -> void:
	if config.is_empty() or cards.is_empty() or crises.is_empty() or combos.is_empty():
		errors.append("one or more data files empty or unreadable")
		return
	for key in ["start_year", "start_temp", "lose_temp", "warming_per_net_emission",
			"start_money", "start_support", "support_cap", "start_absorption",
			"market_size", "reroll_cost", "crisis_start_turn", "bands", "eras", "sectors", "palettes"]:
		if not config.has(key):
			errors.append("config.json: missing key '%s'" % key)
	if not errors.is_empty():
		return

	var sectors := sector_ids()
	for era in config.eras:
		if not config.palettes.has(era.get("palette", "")):
			errors.append("config.json: era '%s' references unknown palette '%s'" % [era.get("id", "?"), era.get("palette", "?")])
		var floors: Dictionary = era.get("min_sector_emissions", {})
		for sid in sectors:
			if not floors.has(sid):
				errors.append("config.json: era '%s' missing min_sector_emissions for '%s'" % [era.get("id", "?"), sid])

	var card_ids := {}
	for card in cards:
		var where := "cards.json: '%s'" % card.get("id", "<no id>")
		for key in ["id", "name", "sector", "cost_money", "cost_support", "available_from", "effects"]:
			if not card.has(key):
				errors.append("%s: missing '%s'" % [where, key])
		if card.has("id"):
			if card_ids.has(card.id):
				errors.append("%s: duplicate id" % where)
			card_ids[card.id] = true
		_validate_effects(card.get("effects", []), sectors, where)

	for crisis in crises:
		var where := "crises.json: '%s'" % crisis.get("id", "<no id>")
		if not CRISIS_KINDS.has(crisis.get("kind", "")):
			errors.append("%s: kind must be one of %s" % [where, CRISIS_KINDS])
		var responses: Array = crisis.get("responses", [])
		if responses.size() < 1 or responses.size() > 3:
			errors.append("%s: needs 1-3 responses, has %d" % [where, responses.size()])
		for r in responses:
			var rwhere := "%s / '%s'" % [where, r.get("name", "<no name>")]
			if not ARCHETYPES.has(r.get("archetype", "")):
				errors.append("%s: archetype must be one of %s" % [rwhere, ARCHETYPES])
			_validate_effects(r.get("effects", []), sectors, rwhere)

	for combo in combos:
		var where := "combos.json: '%s'" % combo.get("id", "<no id>")
		for cid in combo.get("cards", []):
			if not card_ids.has(cid):
				errors.append("%s: references unknown card '%s'" % [where, cid])
		_validate_effects(combo.get("effects", []), sectors, where)


func _validate_effects(effects: Array, sectors: Array, where: String) -> void:
	if effects.is_empty():
		errors.append("%s: empty effects list" % where)
	for atom in effects:
		var t: String = atom.get("type", "")
		if not ATOM_TYPES.has(t):
			errors.append("%s: unknown atom type '%s'" % [where, t])
		if not atom.has("amount") or not (atom.amount is float or atom.amount is int):
			errors.append("%s: atom '%s' missing numeric 'amount'" % [where, t])
		if t in ["sector_emissions", "sector_income"] and not sectors.has(atom.get("sector", "")):
			errors.append("%s: atom '%s' has unknown sector '%s'" % [where, t, atom.get("sector", "?")])
