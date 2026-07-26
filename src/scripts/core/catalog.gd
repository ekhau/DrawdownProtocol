class_name Catalog
extends RefCounted
## Loads and holds the card / event / knowledge catalogs from data/*.json.
## Spec: docs/Phase_5/01_Card_Catalog_Data.md, 02_Event_Catalog_Data.md and
## docs/Phase_4/02_Policy_Effect_Resolver.md (knowledge patches).
## Knowledge nodes patch a per-run IN-MEMORY copy; disk files are never mutated.

const CARDS_PATH := "res://data/cards.json"
const EVENTS_PATH := "res://data/events.json"
const KNOWLEDGE_PATH := "res://data/knowledge.json"

var cards: Array[Dictionary] = []
var cards_by_id: Dictionary = {}        # String -> Dictionary (same refs as cards)
var events: Array[Dictionary] = []      # sorted by ascending "order"
var knowledge: Array[Dictionary] = []
var knowledge_by_id: Dictionary = {}


static func load_default() -> Catalog:
	var cat := Catalog.new()
	cat._load_from(_read_json(CARDS_PATH), _read_json(EVENTS_PATH), _read_json(KNOWLEDGE_PATH))
	return cat


static func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "Failed to parse %s" % path)
	return parsed


func _load_from(cards_doc: Dictionary, events_doc: Dictionary, knowledge_doc: Dictionary) -> void:
	cards.clear()
	cards_by_id.clear()
	for c: Dictionary in cards_doc.get("cards", []):
		cards.append(c)
		cards_by_id[String(c["id"])] = c
	events.clear()
	for e: Dictionary in events_doc.get("events", []):
		events.append(e)
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["order"]) < int(b["order"]))
	knowledge.clear()
	knowledge_by_id.clear()
	for n: Dictionary in knowledge_doc.get("nodes", []):
		knowledge.append(n)
		knowledge_by_id[String(n["id"])] = n


func card(id: StringName) -> Dictionary:
	return cards_by_id.get(String(id), {})


func extreme_events() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in events:
		if e.get("kind", "") == "extreme":
			out.append(e)
	return out


func feedback_events() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in events:
		if e.get("kind", "") == "feedback":
			out.append(e)
	return out


## Deep copy of this catalog with the given knowledge node patches applied.
## Patch vocabulary per docs/Phase_4/02: cost_money, cost_influence,
## effect_happiness, reforest_years (preserving program totals).
func duplicate_patched(unlocked_ids: Array) -> Catalog:
	var cat := Catalog.new()
	for c in cards:
		var copy: Dictionary = c.duplicate(true)
		cat.cards.append(copy)
		cat.cards_by_id[String(copy["id"])] = copy
	cat.events = events.duplicate(true)
	cat.knowledge = knowledge.duplicate(true)
	for n in cat.knowledge:
		cat.knowledge_by_id[String(n["id"])] = n

	for node_id in unlocked_ids:
		var node: Dictionary = knowledge_by_id.get(String(node_id), {})
		if node.is_empty() or not node.has("patch"):
			continue
		var patch: Dictionary = node["patch"]
		var targets: Array = []
		if patch.has("card"):
			targets = [patch["card"]]
		elif patch.has("cards"):
			targets = patch["cards"]
		for card_id in targets:
			var c: Dictionary = cat.cards_by_id.get(String(card_id), {})
			if c.is_empty():
				continue
			if patch.has("cost_money"):
				c["cost_money"] = patch["cost_money"]
			if patch.has("cost_influence"):
				c["cost_influence"] = patch["cost_influence"]
			if patch.has("effect_happiness"):
				for eff: Dictionary in c["effects"]:
					if eff.get("op", "") == "happiness":
						eff["amount"] = patch["effect_happiness"]
			if patch.has("reforest_years"):
				for eff: Dictionary in c["effects"]:
					if eff.get("op", "") == "reforest":
						var total: float = float(eff["per_year"]) * float(eff["years"])
						eff["years"] = int(patch["reforest_years"])
						eff["per_year"] = total / float(eff["years"])
	return cat


## State grants from unlocked knowledge nodes, applied by RunState at init.
## Returns { "media": bool, "adapt": float }.
func grants(unlocked_ids: Array) -> Dictionary:
	var out := {"media": false, "adapt": 0.0}
	for node_id in unlocked_ids:
		var node: Dictionary = knowledge_by_id.get(String(node_id), {})
		var grant: Dictionary = node.get("grant", {})
		if grant.get("media", false):
			out["media"] = true
		out["adapt"] += float(grant.get("adapt", 0.0))
	return out
