class_name Catalog
extends RefCounted
## Loads and validates all JSON content at boot. Fails loud: any schema error
## names the file and entry. The validator is the compiler for JSON.
## Pure — no Nodes, no scene tree.

const ATOM_TYPES := ["money", "popularity", "absorption", "sector_emissions", "sector_income", "income_per_turn", "gross_this_turn"]
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


## Read-only, for the act interstitial: what this era changes — the cards that
## unlock during it, and the hard-to-abate floors it lowers vs the era before.
func era_brief(era_id: String) -> Dictionary:
	var eras: Array = config.eras
	var idx := 0
	for i in eras.size():
		if eras[i].id == era_id:
			idx = i
	var era: Dictionary = eras[idx]
	var until := int(eras[idx + 1].from_year) if idx + 1 < eras.size() else 9999
	var new_cards := []
	for card in cards:
		if int(card.available_from) >= int(era.from_year) and int(card.available_from) < until:
			new_cards.append(card)
	var floor_drops := []
	if idx > 0:
		var prev: Dictionary = eras[idx - 1].min_sector_emissions
		for s in config.sectors:
			var was := int(prev[s.id])
			var now := int(era.min_sector_emissions[s.id])
			if now < was:
				floor_drops.append({"name": s.name, "was": was, "now": now})
	return {"era": era, "new_cards": new_cards, "floor_drops": floor_drops}


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
			"start_money", "start_popularity", "popularity_cap", "popularity_collapse",
			"popularity_baseline", "popularity_drift", "social_crisis_threshold", "start_absorption",
			"market_size", "reroll_cost", "crisis_start_turn", "bands", "eras", "sectors", "palettes"]:
		if not config.has(key):
			errors.append("config.json: missing key '%s'" % key)
	if not errors.is_empty():
		return

	for band in config.bands:
		for key in ["id", "min_temp", "cost_bump_money", "cost_bump_popularity"]:
			if not band.has(key):
				errors.append("config.json: band '%s' missing '%s'" % [band.get("id", "?"), key])

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
		for key in ["id", "name", "sector", "cost_money", "cost_popularity", "available_from", "effects"]:
			if not card.has(key):
				errors.append("%s: missing '%s'" % [where, key])
		if card.has("requires_popularity") and not (card.requires_popularity is float or card.requires_popularity is int):
			errors.append("%s: 'requires_popularity' must be numeric" % where)
		if card.has("risk"):
			var risk: Dictionary = card.risk
			for key in ["offset", "boost_cost", "boost_amount", "boost_max", "cap", "on_fail"]:
				if not risk.has(key):
					errors.append("%s: risk block missing '%s'" % [where, key])
			_validate_effects(risk.get("on_fail", []), sectors, where + " (on_fail)")
		if card.has("id"):
			if card_ids.has(card.id):
				errors.append("%s: duplicate id" % where)
			card_ids[card.id] = true
		_validate_effects(card.get("effects", []), sectors, where)

	var social_count := 0
	for crisis in crises:
		var where := "crises.json: '%s'" % crisis.get("id", "<no id>")
		if not CRISIS_KINDS.has(crisis.get("kind", "")):
			errors.append("%s: kind must be one of %s" % [where, CRISIS_KINDS])
		if crisis.get("social", false):
			social_count += 1
		var responses: Array = crisis.get("responses", [])
		if responses.size() < 1 or responses.size() > 3:
			errors.append("%s: needs 1-3 responses, has %d" % [where, responses.size()])
		for r in responses:
			var rwhere := "%s / '%s'" % [where, r.get("name", "<no name>")]
			if not ARCHETYPES.has(r.get("archetype", "")):
				errors.append("%s: archetype must be one of %s" % [rwhere, ARCHETYPES])
			_validate_effects(r.get("effects", []), sectors, rwhere)
	if social_count == 0:
		errors.append("crises.json: needs at least one 'social: true' crisis — the low-popularity pool would be empty")

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
