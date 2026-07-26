class_name Strategies
## Scripted decision policies for the three strategy archetypes
## (docs/Phase_1/02_Sample_Runs.md). Used by the debug autoplay buttons, the
## headless batch harness and the regression fixtures.
##
## decide() returns ONE action; the autoplay loop calls it repeatedly inside a
## turn until it returns pass (multi-card turns), then resolves the year.
## Actions: {"card": id|&"pass", "target": region|&"", "project": id|&""}.
##
## Archetypes: Safe answers crises, builds sinks/adaptation and an even
## transition; Mixed goes diplomacy-and-combo-first; Risky is a pure tech rush
## that ignores crises, sufficiency, sinks and allies - and stalls at the 70%
## cap by design.

const NAMES: Array[StringName] = [&"safe", &"risky", &"mixed"]

const PASS := {"card": &"pass", "target": &"", "project": &""}

## Cheap response card per crisis tag, in preference order.
const RESPONSE_CARDS := {
	"water": [&"RSP2", &"AGR2"],
	"food": [&"RSP4", &"AGR1"],
	"health": [&"RSP1", &"SOC2"],
	"relief": [&"RSP1", &"RSP6", &"RSP5"],
	"forest": [&"SNK1"],
	"coast": [&"RSP3", &"ADP1"],
	"energy": [&"RSP5", &"IND1"],
	"civic": [&"RSP4", &"RSP6", &"SOC3", &"SOC1"],
	"treaty": [&"DIP1", &"DIP2", &"DIP3"],
}

const TECH_CARD := {&"ind": &"IND2", &"tra": &"TRA2", &"agr": &"AGR2"}
const SUFF_CARD := {&"ind": &"IND3", &"tra": &"TRA1", &"agr": &"AGR1"}


static func decide(strategy: StringName, rs: RunState) -> Dictionary:
	match strategy:
		&"safe": return _decide_safe(rs)
		&"risky": return _decide_risky(rs)
		&"mixed": return _decide_mixed(rs)
	return PASS


static func _ok(rs: RunState, id: StringName) -> bool:
	return rs.can_play_reason(id) == &"ok"


static func _card(id: StringName) -> Dictionary:
	return {"card": id, "target": &"", "project": &""}


static func _project(id: StringName) -> Dictionary:
	return {"card": &"pass", "target": &"", "project": id}


static func _sectors_by_progress(rs: RunState) -> Array[StringName]:
	var order: Array[StringName] = WorldEnums.SECTOR_ORDER.duplicate()
	order.sort_custom(func(a: StringName, b: StringName) -> bool:
		var pa := rs.sector(a).progress
		var pb := rs.sector(b).progress
		if is_equal_approx(pa, pb):
			return WorldEnums.SECTOR_ORDER.find(a) < WorldEnums.SECTOR_ORDER.find(b)
		return pa < pb)
	return order


## Find a playable response card for the first unanswered pending crisis.
static func _answer_crisis(rs: RunState, reserve: float) -> Dictionary:
	for crisis in rs.unanswered_crises():
		var response: Dictionary = rs.crisis_def(crisis["id"]).get("response", {})
		for tag in response.get("tags_any", []):
			for cid: StringName in RESPONSE_CARDS.get(String(tag), []):
				if _ok(rs, cid) and rs.money - rs.effective_cost_money(cid) >= reserve:
					return _card(cid)
	return PASS


## Safe (Steady Transition): answer the crises, then media, adaptation, sinks
## and an even three-sector transition with a handful of alliances; banks a
## money reserve and sustains the Global Sink Trust.
static func _decide_safe(rs: RunState) -> Dictionary:
	var answer := _answer_crisis(rs, 60.0)
	if answer["card"] != &"pass":
		return answer
	if rs.year >= 2040 and rs.money >= 320.0 \
			and rs.can_start_project_reason(&"global_sink_trust") == &"ok":
		return _project(&"global_sink_trust")
	if not rs.media and _ok(rs, &"SOC1"):
		return _card(&"SOC1")
	if rs.adapt < 15.0 and _ok(rs, &"ADP1") and rs.money >= 150.0:
		return _card(&"ADP1")
	if rs.reforest_queue.size() < 2 and rs.absorption < 27.0 and _ok(rs, &"SNK1") \
			and rs.money >= 130.0:
		return _card(&"SNK1")
	if rs.allies < 4 and rs.influence >= 25.0 and _ok(rs, &"DIP1") and rs.money >= 110.0:
		return _card(&"DIP1")
	for sid in _sectors_by_progress(rs):
		var ss := rs.sector(sid)
		if not ss.suff_played and ss.progress >= 55.0 and _ok(rs, SUFF_CARD[sid]) \
				and rs.money >= rs.effective_cost_money(SUFF_CARD[sid]) + 60.0:
			return _card(SUFF_CARD[sid])
		if ss.progress < ss.cap() and _ok(rs, TECH_CARD[sid]) \
				and rs.money >= rs.effective_cost_money(TECH_CARD[sid]) + 60.0:
			return _card(TECH_CARD[sid])
		if not ss.suff_played and _ok(rs, SUFF_CARD[sid]) \
				and rs.money >= rs.effective_cost_money(SUFF_CARD[sid]) + 60.0:
			return _card(SUFF_CARD[sid])
	if rs.happiness < 55.0 and _ok(rs, &"SOC2") and rs.money >= 200.0:
		return _card(&"SOC2")
	return PASS


## Risky (Tech Rush): only the big tech cards, several per year; never answers
## a crisis, never media, sufficiency, sinks, adaptation or diplomacy.
## Stalls at the 70% cap by design.
static func _decide_risky(rs: RunState) -> Dictionary:
	for sid in _sectors_by_progress(rs):
		if _ok(rs, TECH_CARD[sid]):
			return _card(TECH_CARD[sid])
	return PASS


## Mixed (Alliance Web): diplomacy-first; answers crises, chases combo pairs,
## sustains the Continental Rail Compact, alliances up to six with Joint
## Transition Projects as the main engine, sufficiency lifts.
static func _decide_mixed(rs: RunState) -> Dictionary:
	var answer := _answer_crisis(rs, 50.0)
	if answer["card"] != &"pass":
		return answer
	if rs.year >= 2038 and rs.money >= 300.0 \
			and rs.can_start_project_reason(&"continental_rail") == &"ok":
		return _project(&"continental_rail")
	if not rs.media and _ok(rs, &"SOC1"):
		return _card(&"SOC1")
	if rs.reforest_queue.size() < 2 and rs.absorption < 25.0 and _ok(rs, &"SNK1") \
			and rs.money >= 130.0:
		return _card(&"SNK1")
	if rs.influence >= 25.0 and _ok(rs, &"DIP1") and rs.money >= 110.0:
		return _card(&"DIP1")
	# Emergency decarbonization: if at the current pace the world breaches the
	# +2.0 C limit within two decades, push the big tech cards before the bikes.
	var projected: float = rs.temp + float(Tuning.c("K_WARM")) * maxf(0.0, rs.net_emissions()) * 20.0
	if projected >= float(Tuning.c("T_LOSS")):
		for sid in _sectors_by_progress(rs):
			var ss := rs.sector(sid)
			if ss.progress < ss.cap() and _ok(rs, TECH_CARD[sid]) \
					and rs.money >= rs.effective_cost_money(TECH_CARD[sid]) + 50.0:
				return _card(TECH_CARD[sid])
	var tra := rs.sector(&"tra")
	if not tra.suff_played and _ok(rs, &"TRA1") and rs.money >= 140.0:
		return _card(&"TRA1")
	# Protect the 25-influence alliance budget until the coalition is complete.
	if (rs.allies >= int(Tuning.s("MAX_ALLIES")) or rs.influence >= 40.0) and _ok(rs, &"DIP2") \
			and rs.money >= 180.0:
		return _card(&"DIP2")
	for sid: StringName in [&"agr", &"ind"]:
		var ss := rs.sector(sid)
		if not ss.suff_played and ss.progress >= 50.0 and _ok(rs, SUFF_CARD[sid]) \
				and rs.money >= rs.effective_cost_money(SUFF_CARD[sid]) + 50.0:
			return _card(SUFF_CARD[sid])
	if tra.progress < tra.cap() and _ok(rs, &"TRA1") and rs.money >= 140.0:
		return _card(&"TRA1")
	for sid in _sectors_by_progress(rs):
		var ss := rs.sector(sid)
		if ss.progress < ss.cap() and _ok(rs, TECH_CARD[sid]) \
				and rs.money >= rs.effective_cost_money(TECH_CARD[sid]) + 50.0:
			return _card(TECH_CARD[sid])
		if not ss.suff_played and _ok(rs, SUFF_CARD[sid]) \
				and rs.money >= rs.effective_cost_money(SUFF_CARD[sid]) + 50.0:
			return _card(SUFF_CARD[sid])
	# Ledger watch: late-game money goes into sinks while net is not safely negative.
	if rs.net_emissions() > -8.0 and _ok(rs, &"SNK1") and rs.money >= 130.0:
		return _card(&"SNK1")
	if rs.happiness < 55.0 and _ok(rs, &"SOC2") and rs.money >= 180.0:
		return _card(&"SOC2")
	return PASS


## Drive one full turn: play cards/projects until the strategy passes, then
## resolve. Shared by autoplay(), the Sim debug hooks and the batch harness.
static func play_turn(strategy: StringName, rs: RunState) -> void:
	var guard := int(Tuning.s("MAX_CARDS_PER_TURN")) + 4
	while guard > 0:
		guard -= 1
		var choice := decide(strategy, rs)
		if choice["project"] != &"":
			if rs.start_project(choice["project"]) != OK:
				break
			continue
		if choice["card"] == &"pass":
			break
		if rs.play_card(choice["card"], choice["target"]) != OK:
			break
	rs.resolve_year()


## Run one full autoplay run headlessly. Returns the terminal RunState.
static func autoplay(strategy: StringName, seed_value: int, canonical: bool = false,
		unlocked_knowledge: Array = []) -> RunState:
	var gen := WorldGen.generate(seed_value, canonical)
	var rs := RunState.new_run(gen, Catalog.load_default(), unlocked_knowledge)
	var safety := 200
	while rs.phase != RunState.Phase.ENDED and safety > 0:
		safety -= 1
		play_turn(strategy, rs)
	return rs
