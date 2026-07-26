class_name DataValidator
extends RefCounted
## Collected (not first-failure) schema validation of the content catalogs.
## Spec: docs/Phase_5/05_Data_Validation_And_Content_Pipeline.md.
## Run three ways: at boot, headless via tools/validate_data.gd, and by tests.
##
## Rule E8 (order renumbering vs the previous committed file version) is not
## implemented: it needs version history, out of scope for the prototype.

const CATEGORIES := ["ind", "tra", "agr", "sink", "society", "diplomacy", "response"]
const SECTORS := ["ind", "tra", "agr"]
const TARGET_TAGS := ["coastal", "arid", "forested"]
const CONSUMABLE_FLAGS := ["window", "fire_discount", "flood_rebuild"]
const DAMAGE_KEYS := ["money", "happiness", "absorption", "influence", "ally_lost"]
const REWARD_KEYS := ["money", "influence", "happiness", "knowledge"]
const FEEDBACK_EFFECT_KEYS := ["e_extra", "absorption"]
const KNOWN_SCHEMA_VERSIONS := [1, 2]

## Combo/response tag vocabulary (cards carry them; crises and combos match on
## them). "sufficiency" and "restoration" are rule tags with hard-coded
## semantics (cap lift, fire discount).
const COMBO_TAGS := ["water", "food", "energy", "mobility", "forest", "coast",
	"health", "civic", "treaty", "relief"]
const RULE_TAGS := ["sufficiency", "restoration"]

const UNLOCK_KINDS := ["crises_answered", "combos", "allies", "projects_completed",
	"sector_progress"]
const PASSIVE_KEYS := ["income_money", "income_influence", "happiness_per_year",
	"absorption_per_year"]

## op -> { param: required(bool) }; "op" key itself is implicit.
const OPS := {
	"sector_progress": {"sector": true, "amount": true, "lifts_cap": false},
	"joint_progress": {"amount": true},
	"happiness": {"amount": true, "waivable": false},
	"sink_now": {"amount": true},
	"reforest": {"per_year": true, "years": true},
	"adapt": {"amount": true},
	"media": {},
	"wellbeing": {"amount": true},
	"ally": {},
}
## Ops legal outside a card play (combo bonuses, project completions).
const SIMPLE_OPS := ["sector_progress", "joint_progress", "happiness", "wellbeing",
	"sink_now", "reforest", "adapt"]

const KNOWLEDGE_PATCH_KEYS := ["card", "cards", "cost_money", "cost_influence",
	"effect_happiness", "reforest_years"]
const KNOWLEDGE_GRANT_KEYS := ["media", "adapt"]

## Tutorial step vocabulary (docs: GoldenRules #7 - teach through play).
const TUTORIAL_TARGETS := ["none", "top_bar", "warming_gauge", "carbon_label",
	"board", "region_home", "card_tray", "crisis_bar", "project_column",
	"log_dock", "prompt", "help_button"]
const TUTORIAL_SIGNALS := ["region_selected", "card_played", "year_advanced",
	"hub_opened", "project_started"]
const TUTORIAL_TEXT_MAX := 280  # warning guardrail: steps must not be walls of text

var errors: PackedStringArray = []
var warnings: PackedStringArray = []


static func load_and_validate(data_dir: String = "res://data") -> DataValidator:
	var v := DataValidator.new()
	var cards_doc := _read(data_dir + "/cards.json", v)
	var events_doc := _read(data_dir + "/events.json", v)
	var knowledge_doc := _read(data_dir + "/knowledge.json", v)
	var templates_doc := _read(data_dir + "/log_templates.json", v)
	var tutorial_doc := _read(data_dir + "/tutorial.json", v)
	var combos_doc := _read(data_dir + "/combos.json", v)
	var projects_doc := _read(data_dir + "/projects.json", v)
	if v.errors.is_empty():
		v.validate_all(cards_doc, events_doc, knowledge_doc, templates_doc,
			tutorial_doc, combos_doc, projects_doc)
	return v


static func _read(path: String, v: DataValidator) -> Dictionary:
	if not FileAccess.file_exists(path):
		v.errors.append("IO [%s] file missing" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		v.errors.append("IO [%s] not valid JSON object" % path)
		return {}
	return parsed


func ok() -> bool:
	return errors.is_empty()


func validate_all(cards_doc: Dictionary, events_doc: Dictionary,
		knowledge_doc: Dictionary, templates_doc: Dictionary,
		tutorial_doc: Dictionary = {}, combos_doc: Dictionary = {},
		projects_doc: Dictionary = {}) -> bool:
	var card_info := validate_cards(cards_doc)
	var event_info := validate_events(events_doc, card_info)
	validate_knowledge(knowledge_doc, card_info["ids"])
	if not combos_doc.is_empty():
		validate_combos(combos_doc, card_info)
	if not projects_doc.is_empty():
		validate_projects(projects_doc)
	validate_templates(templates_doc, event_info)
	if not tutorial_doc.is_empty():
		validate_tutorial(tutorial_doc)
	return ok()


# ------------------------------------------------------------- cards.json ---

## Returns { "ids": Array[String], "cards": Array[Dictionary] }.
func validate_cards(doc: Dictionary) -> Dictionary:
	var ids: Array[String] = []
	var all_cards: Array[Dictionary] = []
	# C1
	if not KNOWN_SCHEMA_VERSIONS.has(int(doc.get("schema_version", -1))):
		errors.append("C1 [cards] unknown schema_version")
	var cards: Array = doc.get("cards", [])
	if cards.is_empty():
		errors.append("C1 [cards] empty or missing cards array")
	var id_regex := RegEx.create_from_string("^[A-Z]{3}[0-9]+$")
	for c: Dictionary in cards:
		all_cards.append(c)
		var id := String(c.get("id", ""))
		var where := "cards:%s" % (id if not id.is_empty() else "?")
		# C2
		if id_regex.search(id) == null:
			errors.append("C2 [%s] id must match ^[A-Z]{3}[0-9]+$" % where)
		if ids.has(id):
			errors.append("C2 [%s] duplicate id" % where)
		ids.append(id)
		var cname := String(c.get("name", ""))
		if cname.is_empty() or cname.length() > 24:
			errors.append("C2 [%s] name empty or longer than 24 chars" % where)
		# C3
		if not CATEGORIES.has(String(c.get("category", ""))):
			errors.append("C3 [%s] unknown category '%s'" % [where, c.get("category", "")])
		# C4
		if float(c.get("cost_money", 0)) < 0 or float(c.get("cost_influence", 0)) < 0 \
				or float(c.get("cost_happiness", 0)) < 0:
			errors.append("C4 [%s] negative cost" % where)
		for rkey in c.get("requires", {}):
			if String(rkey) != "allies_min":
				errors.append("C4 [%s] unknown requires key '%s'" % [where, rkey])
		# C5 / C7
		var lifts := false
		var has_reforest := false
		var progress_amount := 0.0
		for eff: Dictionary in c.get("effects", []):
			var op := String(eff.get("op", ""))
			if not OPS.has(op):
				errors.append("C5 [%s] unknown effect op '%s'" % [where, op])
				continue
			var params: Dictionary = OPS[op]
			for p in params:
				if params[p] and not eff.has(p):
					errors.append("C5 [%s] op '%s' missing required param '%s'" % [where, op, p])
			for key in eff:
				if String(key) != "op" and not params.has(String(key)):
					errors.append("C5 [%s] op '%s' has unknown param '%s'" % [where, op, key])
			match op:
				"sector_progress":
					if not SECTORS.has(String(eff.get("sector", ""))):
						errors.append("C7 [%s] sector_progress.sector must be ind|tra|agr" % where)
					if float(eff.get("amount", 0)) <= 0:
						errors.append("C7 [%s] sector_progress.amount must be > 0" % where)
					if bool(eff.get("lifts_cap", false)):
						lifts = true
					progress_amount += float(eff.get("amount", 0))
				"joint_progress":
					if float(eff.get("amount", 0)) <= 0:
						errors.append("C7 [%s] joint_progress.amount must be > 0" % where)
				"reforest":
					has_reforest = true
					if int(eff.get("years", 0)) < 1:
						errors.append("C7 [%s] reforest.years must be >= 1" % where)
		# C6 (both directions)
		var tagged: bool = c.get("tags", []).has("sufficiency")
		if tagged != lifts:
			errors.append("C6 [%s] 'sufficiency' tag and lifts_cap must agree" % where)
		# C8
		if has_reforest and not c.get("tags", []).has("restoration"):
			warnings.append("C8 [%s] reforest effect without 'restoration' tag" % where)
		# C9 (balance guardrail; non-sufficiency sector cards per Phase_5/01)
		if progress_amount > 0.0 and not tagged and float(c.get("cost_money", 0)) > 0:
			var per100 := progress_amount / float(c.get("cost_money", 1)) * 100.0
			if per100 < 6.0 or per100 > 14.0:
				warnings.append("C9 [%s] progress per 100 money is %.1f (guardrail 6-14)" % [where, per100])
		# C10: rewards
		var rewards: Dictionary = c.get("rewards", {})
		for key in rewards:
			if not REWARD_KEYS.has(String(key)):
				errors.append("C10 [%s] unknown reward key '%s'" % [where, key])
			elif float(rewards[key]) < 0:
				errors.append("C10 [%s] reward '%s' must be >= 0" % [where, key])
		if float(rewards.get("money", 0)) >= float(c.get("cost_money", 0)) \
				and float(rewards.get("money", 0)) > 0:
			warnings.append("C10 [%s] money reward >= money cost (self-financing card)" % where)
		# C11: unlock condition (deck growth)
		if c.has("unlock"):
			var unlock: Dictionary = c["unlock"]
			var kind := String(unlock.get("kind", ""))
			if not UNLOCK_KINDS.has(kind):
				errors.append("C11 [%s] unknown unlock kind '%s'" % [where, kind])
			elif kind == "sector_progress":
				if not SECTORS.has(String(unlock.get("sector", ""))):
					errors.append("C11 [%s] unlock sector must be ind|tra|agr" % where)
				if float(unlock.get("gte", 0)) <= 0:
					errors.append("C11 [%s] unlock gte must be > 0" % where)
			elif int(unlock.get("count", 0)) < 1:
				errors.append("C11 [%s] unlock count must be >= 1" % where)
		# C12: tag vocabulary
		for tag in c.get("tags", []):
			if not COMBO_TAGS.has(String(tag)) and not RULE_TAGS.has(String(tag)):
				errors.append("C12 [%s] unknown tag '%s'" % [where, tag])
	return {"ids": ids, "cards": all_cards}


# ------------------------------------------------------------ events.json ---

## Returns info consumed by the template cross-check: { "crises": [...ids],
## "opportunities": [...ids], "feedbacks": [...ids], "with_rider": [...ids] }.
func validate_events(doc: Dictionary, card_info: Dictionary = {}) -> Dictionary:
	var info := {"crises": [], "opportunities": [], "feedbacks": [], "with_rider": []}
	if not KNOWN_SCHEMA_VERSIONS.has(int(doc.get("schema_version", -1))):
		errors.append("E1 [events] unknown schema_version")
	var events: Array = doc.get("events", [])
	if events.is_empty():
		errors.append("E1 [events] empty or missing events array")
	var ids: Array[String] = []
	var orders: Array[int] = []
	var snake := RegEx.create_from_string("^[a-z][a-z0-9_]*$")
	var starting_cards: Array = []
	for c: Dictionary in card_info.get("cards", []):
		if not c.has("unlock"):
			starting_cards.append(c)
	for e: Dictionary in events:
		var id := String(e.get("id", ""))
		var where := "events:%s" % (id if not id.is_empty() else "?")
		var kind := String(e.get("kind", ""))
		# E1
		if snake.search(id) == null:
			errors.append("E1 [%s] id must be snake_case" % where)
		if ids.has(id):
			errors.append("E1 [%s] duplicate id" % where)
		ids.append(id)
		var order := int(e.get("order", -1))
		if orders.has(order):
			errors.append("E1 [%s] duplicate order %d" % [where, order])
		orders.append(order)
		match kind:
			"crisis":
				info["crises"].append(id)
				if order >= 50:
					errors.append("E1 [%s] crisis order must be < 50" % where)
			"opportunity":
				info["opportunities"].append(id)
				if order < 50 or order >= 90:
					errors.append("E1 [%s] opportunity order must be in 50-89" % where)
			"feedback":
				info["feedbacks"].append(id)
				if order < 90:
					errors.append("E1 [%s] feedback order must be >= 90" % where)
			_:
				errors.append("E1 [%s] kind must be crisis|opportunity|feedback" % where)
		# E2: drawable entries carry weights; feedbacks carry a trigger.
		if kind == "feedback":
			if not e.has("trigger") or e.has("weights"):
				errors.append("E2 [%s] feedback needs 'trigger' and no 'weights'" % where)
		else:
			if not e.has("weights") or e.has("trigger"):
				errors.append("E2 [%s] drawable event needs 'weights' and no 'trigger'" % where)
		# E3: weights per band; crises escalate with Overshoot.
		if e.has("weights"):
			var weights: Array = e["weights"]
			if weights.size() != 3:
				errors.append("E3 [%s] weights must have exactly 3 entries" % where)
			else:
				for i in 3:
					if float(weights[i]) < 0.0:
						errors.append("E3 [%s] weight %d must be >= 0" % [where, i])
				if kind == "crisis" and (float(weights[0]) > float(weights[1])
						or float(weights[1]) > float(weights[2])):
					errors.append("E3 [%s] crisis weights must be non-decreasing (Overshoot escalates)" % where)
		var mods: Dictionary = e.get("weight_mods", {})
		for key in mods:
			if not ["low_happiness_mult", "happiness_threshold", "media_mult"].has(String(key)):
				errors.append("E3 [%s] unknown weight_mods key '%s'" % [where, key])
		# E4
		var target: Dictionary = e.get("target", {})
		for tag in target.get("tags_any", []):
			if not TARGET_TAGS.has(String(tag)):
				errors.append("E4 [%s] unknown target tag '%s'" % [where, tag])
		for key in target.get("weight_boost", {}):
			if not TARGET_TAGS.has(String(key)) and String(key) != "ally":
				errors.append("E4 [%s] unknown weight_boost key '%s'" % [where, key])
		# E5: damages (crises only)
		for key in e.get("damages", {}):
			if not DAMAGE_KEYS.has(String(key)):
				errors.append("E5 [%s] unknown damage key '%s'" % [where, key])
			elif float(e["damages"][key]) <= 0:
				errors.append("E5 [%s] damage '%s' must be > 0" % [where, key])
		if kind == "opportunity" and (e.has("damages") or e.has("scar") or e.has("counters")):
			errors.append("E5 [%s] opportunity cannot carry damages/scar/counters" % where)
		# E6
		var opp: Variant = e.get("opportunity")
		if opp is Dictionary:
			if not CONSUMABLE_FLAGS.has(String(opp.get("set_flag", ""))):
				errors.append("E6 [%s] opportunity.set_flag not a consumable flag" % where)
			info["with_rider"].append(id)
		if kind == "feedback":
			for key in e.get("effect", {}):
				if not FEEDBACK_EFFECT_KEYS.has(String(key)):
					errors.append("E6 [%s] unknown feedback effect key '%s'" % [where, key])
		# E9: response (the card-tag answer contract)
		if kind == "crisis" or kind == "opportunity":
			var response: Dictionary = e.get("response", {})
			var rtags: Array = response.get("tags_any", [])
			if rtags.is_empty():
				errors.append("E9 [%s] response.tags_any must be non-empty" % where)
			for tag in rtags:
				if not COMBO_TAGS.has(String(tag)):
					errors.append("E9 [%s] unknown response tag '%s'" % [where, tag])
			for key in response.get("rewards", {}):
				if not REWARD_KEYS.has(String(key)):
					errors.append("E9 [%s] unknown response reward key '%s'" % [where, key])
				elif float(response["rewards"][key]) < 0:
					errors.append("E9 [%s] response reward '%s' must be >= 0" % [where, key])
			# E10: answerable from the starting pool (no unlock required)
			if not card_info.is_empty():
				var answerable := false
				for c: Dictionary in starting_cards:
					for tag in rtags:
						if (c.get("tags", []) as Array).has(String(tag)):
							answerable = true
				if not answerable:
					errors.append("E10 [%s] no starting card carries any response tag" % where)
		elif e.has("response"):
			errors.append("E9 [%s] feedback cannot carry a response" % where)
	return info


# ------------------------------------------------------------ combos.json ---

func validate_combos(doc: Dictionary, card_info: Dictionary = {}) -> void:
	if not KNOWN_SCHEMA_VERSIONS.has(int(doc.get("schema_version", -1))):
		errors.append("CB1 [combos] unknown schema_version")
	var combos: Array = doc.get("combos", [])
	if combos.is_empty():
		errors.append("CB1 [combos] empty or missing combos array")
	var ids: Array[String] = []
	var snake := RegEx.create_from_string("^[a-z][a-z0-9_]*$")
	for cb: Dictionary in combos:
		var id := String(cb.get("id", ""))
		var where := "combos:%s" % (id if not id.is_empty() else "?")
		if snake.search(id) == null:
			errors.append("CB1 [%s] id must be snake_case" % where)
		if ids.has(id):
			errors.append("CB1 [%s] duplicate id" % where)
		ids.append(id)
		if String(cb.get("name", "")).is_empty():
			errors.append("CB1 [%s] name must be non-empty" % where)
		# CB2: tags
		var tags: Array = cb.get("tags_required", [])
		if tags.size() < 2:
			errors.append("CB2 [%s] tags_required needs at least 2 tags" % where)
		for tag in tags:
			if not COMBO_TAGS.has(String(tag)) and not RULE_TAGS.has(String(tag)):
				errors.append("CB2 [%s] unknown tag '%s'" % [where, tag])
		# CB3: payoff
		var rewards: Dictionary = cb.get("rewards", {})
		for key in rewards:
			if not REWARD_KEYS.has(String(key)):
				errors.append("CB3 [%s] unknown reward key '%s'" % [where, key])
			elif float(rewards[key]) < 0:
				errors.append("CB3 [%s] reward '%s' must be >= 0" % [where, key])
		if rewards.is_empty() and (cb.get("effects", []) as Array).is_empty():
			errors.append("CB3 [%s] combo needs rewards or effects" % where)
		# CB4: effect ops restricted to the simple set
		for eff: Dictionary in cb.get("effects", []):
			var op := String(eff.get("op", ""))
			if not SIMPLE_OPS.has(op):
				errors.append("CB4 [%s] effect op '%s' not allowed in combos" % [where, op])
			elif OPS.has(op):
				for p in OPS[op]:
					if OPS[op][p] and not eff.has(p):
						errors.append("CB4 [%s] op '%s' missing required param '%s'" % [where, op, p])
		# CB5 (warning): a combo must need at least two cards
		for c: Dictionary in card_info.get("cards", []):
			var card_tags: Array = c.get("tags", [])
			var covers := true
			for tag in tags:
				if not card_tags.has(String(tag)):
					covers = false
			if covers and not tags.is_empty():
				warnings.append("CB5 [%s] single card %s covers the whole combo" % [where, c.get("id", "?")])


# ---------------------------------------------------------- projects.json ---

func validate_projects(doc: Dictionary) -> void:
	if not KNOWN_SCHEMA_VERSIONS.has(int(doc.get("schema_version", -1))):
		errors.append("PR1 [projects] unknown schema_version")
	var projects: Array = doc.get("projects", [])
	if projects.is_empty():
		errors.append("PR1 [projects] empty or missing projects array")
	var ids: Array[String] = []
	var snake := RegEx.create_from_string("^[a-z][a-z0-9_]*$")
	for p: Dictionary in projects:
		var id := String(p.get("id", ""))
		var where := "projects:%s" % (id if not id.is_empty() else "?")
		if snake.search(id) == null:
			errors.append("PR1 [%s] id must be snake_case" % where)
		if ids.has(id):
			errors.append("PR1 [%s] duplicate id" % where)
		ids.append(id)
		var pname := String(p.get("name", ""))
		if pname.is_empty() or pname.length() > 24:
			errors.append("PR1 [%s] name empty or longer than 24 chars" % where)
		if float(p.get("upkeep_money", 0)) < 0 or float(p.get("upkeep_influence", 0)) < 0:
			errors.append("PR1 [%s] negative upkeep" % where)
		if float(p.get("upkeep_money", 0)) + float(p.get("upkeep_influence", 0)) <= 0:
			errors.append("PR1 [%s] project needs a non-zero upkeep" % where)
		var years := int(p.get("years", 0))
		if years < 2 or years > 10:
			errors.append("PR1 [%s] years must be in 2-10" % where)
		# PR2: completion payload
		var completion: Dictionary = p.get("completion", {})
		if completion.get("effects", []).is_empty() and completion.get("passive", {}).is_empty():
			errors.append("PR2 [%s] completion needs effects or a passive" % where)
		for eff: Dictionary in completion.get("effects", []):
			var op := String(eff.get("op", ""))
			if not SIMPLE_OPS.has(op) and op != "ally":
				errors.append("PR2 [%s] effect op '%s' not allowed in completions" % [where, op])
		for key in completion.get("passive", {}):
			if not PASSIVE_KEYS.has(String(key)):
				errors.append("PR2 [%s] unknown passive key '%s'" % [where, key])
		# PR3: abandon penalty
		var penalty: Dictionary = p.get("abandon_penalty", {})
		if penalty.is_empty():
			errors.append("PR3 [%s] abandon_penalty required (commitment must bite)" % where)
		for key in penalty:
			if not ["happiness", "influence"].has(String(key)):
				errors.append("PR3 [%s] unknown penalty key '%s'" % [where, key])
			elif float(penalty[key]) < 0:
				errors.append("PR3 [%s] penalty '%s' must be >= 0" % [where, key])


# --------------------------------------------------------- knowledge.json ---

func validate_knowledge(doc: Dictionary, card_ids: Array[String]) -> void:
	if not KNOWN_SCHEMA_VERSIONS.has(int(doc.get("schema_version", -1))):
		errors.append("K1 [knowledge] unknown schema_version")
	var ids: Array[String] = []
	for n: Dictionary in doc.get("nodes", []):
		var id := String(n.get("id", ""))
		var where := "knowledge:%s" % (id if not id.is_empty() else "?")
		if ids.has(id):
			errors.append("K1 [%s] duplicate id" % where)
		ids.append(id)
		var cost := int(n.get("kp_cost", 0))
		if cost < 1 or cost > 20:
			errors.append("K1 [%s] kp_cost must be in 1-20" % where)
		if String(n.get("insight", "")).is_empty():
			errors.append("K1 [%s] insight must be non-empty" % where)
		if not n.has("patch") and not n.has("grant"):
			errors.append("K1 [%s] node needs a patch or a grant" % where)
		var patch: Dictionary = n.get("patch", {})
		for key in patch:
			if not KNOWLEDGE_PATCH_KEYS.has(String(key)):
				errors.append("K1 [%s] unknown patch key '%s'" % [where, key])
		var targets: Array = []
		if patch.has("card"):
			targets = [patch["card"]]
		elif patch.has("cards"):
			targets = patch["cards"]
		for t in targets:
			if not card_ids.has(String(t)):
				errors.append("K1 [%s] patch references unknown card '%s'" % [where, t])
		for key in n.get("grant", {}):
			if not KNOWLEDGE_GRANT_KEYS.has(String(key)):
				errors.append("K1 [%s] unknown grant key '%s'" % [where, key])


# ---------------------------------------------------------- tutorial.json ---

func validate_tutorial(doc: Dictionary) -> void:
	if not KNOWN_SCHEMA_VERSIONS.has(int(doc.get("schema_version", -1))):
		errors.append("TU1 [tutorial] unknown schema_version")
	var steps: Array = doc.get("steps", [])
	if steps.is_empty():
		errors.append("TU1 [tutorial] empty or missing steps array")
	var ids: Array[String] = []
	var snake := RegEx.create_from_string("^[a-z][a-z0-9_]*$")
	for s: Dictionary in steps:
		var id := String(s.get("id", ""))
		var where := "tutorial:%s" % (id if not id.is_empty() else "?")
		if snake.search(id) == null:
			errors.append("TU1 [%s] id must be snake_case" % where)
		if ids.has(id):
			errors.append("TU1 [%s] duplicate id" % where)
		ids.append(id)
		if String(s.get("title", "")).is_empty():
			errors.append("TU2 [%s] title must be non-empty" % where)
		var text := String(s.get("text", ""))
		if text.is_empty():
			errors.append("TU2 [%s] text must be non-empty" % where)
		elif text.length() > TUTORIAL_TEXT_MAX:
			warnings.append("TU2 [%s] text is %d chars (guardrail %d: teach, don't lecture)" % [where, text.length(), TUTORIAL_TEXT_MAX])
		if not TUTORIAL_TARGETS.has(String(s.get("target", ""))):
			errors.append("TU3 [%s] unknown target '%s'" % [where, s.get("target", "")])
		var advance: Dictionary = s.get("advance", {})
		match String(advance.get("type", "")):
			"next":
				pass
			"signal":
				if not TUTORIAL_SIGNALS.has(String(advance.get("signal", ""))):
					errors.append("TU4 [%s] unknown advance signal '%s'" % [where, advance.get("signal", "")])
			_:
				errors.append("TU4 [%s] advance.type must be 'next' or 'signal'" % where)


# ----------------------------------------------------- log_templates.json ---

func validate_templates(doc: Dictionary, event_info: Dictionary) -> void:
	if doc.is_empty():
		errors.append("T1 [templates] missing or empty log_templates.json")
		return
	var events_sect: Dictionary = doc.get("events", {})
	for id in event_info.get("crises", []):
		for suffix in ["_hit", "_answered"]:
			if not events_sect.has(String(id) + suffix):
				errors.append("T1 [templates] missing crisis template '%s%s'" % [id, suffix])
	for id in event_info.get("opportunities", []):
		for suffix in ["_seized", "_missed"]:
			if not events_sect.has(String(id) + suffix):
				errors.append("T1 [templates] missing opportunity template '%s%s'" % [id, suffix])
	for id in event_info.get("feedbacks", []):
		if not events_sect.has(String(id) + "_hit"):
			errors.append("T1 [templates] missing feedback template '%s_hit'" % id)
	for id in event_info.get("with_rider", []):
		if not events_sect.has(String(id) + "_opp"):
			errors.append("T1 [templates] missing rider template '%s_opp'" % id)
	var ops_sect: Dictionary = doc.get("ops", {})
	for op in OPS:
		if not ops_sect.has(String(op)):
			errors.append("T1 [templates] missing op template '%s'" % op)
	var endings: Dictionary = doc.get("endings", {})
	for status in ["WIN_NEUTRAL", "LOSS_LIMIT_BREACHED", "LOSS_NOT_NEUTRAL"]:
		if not endings.has(status):
			errors.append("T1 [templates] missing ending template '%s'" % status)
	var system: Dictionary = doc.get("system", {})
	for key in ["income", "pass", "ledger", "warming", "drift", "sink_matured",
			"penalty_h_below_40", "penalty_h_below_25", "rebuild_better_tra",
			"band_up_1", "band_up_2", "band_down_0", "band_down_1",
			"ally_lost", "run_end_kp", "crises_faced", "combo", "rewards",
			"card_unlocked", "project_launched", "project_charged",
			"project_completed", "project_failed", "project_abandoned"]:
		if not system.has(key):
			errors.append("T1 [templates] missing system template '%s'" % key)
	if not doc.get("cards", {}).has("enact"):
		errors.append("T1 [templates] missing cards template 'enact'")


func report() -> String:
	var lines: PackedStringArray = []
	lines.append("Data validation: %d error(s), %d warning(s)" % [errors.size(), warnings.size()])
	for e in errors:
		lines.append("  ERROR   %s" % e)
	for w in warnings:
		lines.append("  warning %s" % w)
	return "\n".join(lines)
