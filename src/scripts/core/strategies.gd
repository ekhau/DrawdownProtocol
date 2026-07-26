class_name Strategies
## Scripted decision policies for the three Phase 1 strategy archetypes
## (docs/Phase_1/02_Sample_Runs.md). Used by the debug autoplay buttons, the
## headless batch harness and the regression fixtures.
##
## NOTE: the Phase 1 throwaway script (and its exact per-year card lists) was
## deliberately not committed (golden rule 4), so these are re-authored
## heuristics targeting the same structural outcomes: Safe and Mixed win,
## Risky never wins (the 70% tech-cap plateau).

const NAMES: Array[StringName] = [&"safe", &"risky", &"mixed"]


## Returns the card to play this year: {"card": StringName, "target": StringName}.
## &"pass" means bank the money.
static func decide(strategy: StringName, rs: RunState) -> Dictionary:
	match strategy:
		&"safe": return _decide_safe(rs)
		&"risky": return _decide_risky(rs)
		&"mixed": return _decide_mixed(rs)
	return {"card": &"pass", "target": &""}


static func _ok(rs: RunState, id: StringName) -> bool:
	return rs.can_play_reason(id) == &"ok"


static func _sectors_by_progress(rs: RunState) -> Array[StringName]:
	var order: Array[StringName] = WorldEnums.SECTOR_ORDER.duplicate()
	order.sort_custom(func(a: StringName, b: StringName) -> bool:
		var pa := rs.sector(a).progress
		var pb := rs.sector(b).progress
		if is_equal_approx(pa, pb):
			return WorldEnums.SECTOR_ORDER.find(a) < WorldEnums.SECTOR_ORDER.find(b)
		return pa < pb)
	return order


const TECH_CARD := {&"ind": &"IND2", &"tra": &"TRA2", &"agr": &"AGR2"}
const SUFF_CARD := {&"ind": &"IND3", &"tra": &"TRA1", &"agr": &"AGR1"}


## Safe (Steady Transition): media first, then adaptation, sinks, and an even
## three-sector transition with a handful of alliances.
static func _decide_safe(rs: RunState) -> Dictionary:
	if not rs.media and _ok(rs, &"SOC1"):
		return {"card": &"SOC1", "target": &""}
	if rs.adapt < 15.0 and _ok(rs, &"ADP1"):
		return {"card": &"ADP1", "target": &""}
	if rs.reforest_queue.size() < 2 and rs.absorption < 27.0 and _ok(rs, &"SNK1"):
		return {"card": &"SNK1", "target": &""}
	if rs.allies < 4 and rs.influence >= 25.0 and _ok(rs, &"DIP1"):
		return {"card": &"DIP1", "target": &""}
	for sid in _sectors_by_progress(rs):
		var ss := rs.sector(sid)
		if not ss.suff_played and ss.progress >= 55.0 and _ok(rs, SUFF_CARD[sid]):
			return {"card": SUFF_CARD[sid], "target": &""}
		if ss.progress < ss.cap() and _ok(rs, TECH_CARD[sid]):
			return {"card": TECH_CARD[sid], "target": &""}
		if not ss.suff_played and _ok(rs, SUFF_CARD[sid]):
			return {"card": SUFF_CARD[sid], "target": &""}
	if rs.happiness < 55.0 and _ok(rs, &"SOC2"):
		return {"card": &"SOC2", "target": &""}
	return {"card": &"pass", "target": &""}


## Risky (Tech Rush): only the big tech cards; never media, sufficiency,
## sinks, adaptation or diplomacy. Stalls at the 70% cap by design.
static func _decide_risky(rs: RunState) -> Dictionary:
	for sid in _sectors_by_progress(rs):
		if _ok(rs, TECH_CARD[sid]):
			return {"card": TECH_CARD[sid], "target": &""}
	return {"card": &"pass", "target": &""}


## Mixed (Alliance Web): diplomacy-first; bikes-and-rail opening, alliances up
## to six, Joint Transition Projects as the main engine, sufficiency lifts.
static func _decide_mixed(rs: RunState) -> Dictionary:
	if not rs.media and _ok(rs, &"SOC1"):
		return {"card": &"SOC1", "target": &""}
	if rs.reforest_queue.size() < 2 and rs.absorption < 25.0 and _ok(rs, &"SNK1"):
		return {"card": &"SNK1", "target": &""}
	if rs.influence >= 25.0 and _ok(rs, &"DIP1"):
		return {"card": &"DIP1", "target": &""}
	# Emergency decarbonization: if at the current pace the world breaches the
	# +2.0 C limit within two decades, push the big tech cards before the bikes.
	var projected: float = rs.temp + float(Tuning.c("K_WARM")) * maxf(0.0, rs.net_emissions()) * 20.0
	if projected >= float(Tuning.c("T_LOSS")):
		for sid in _sectors_by_progress(rs):
			var ss := rs.sector(sid)
			if ss.progress < ss.cap() and _ok(rs, TECH_CARD[sid]):
				return {"card": TECH_CARD[sid], "target": &""}
	var tra := rs.sector(&"tra")
	if not tra.suff_played and _ok(rs, &"TRA1"):
		return {"card": &"TRA1", "target": &""}
	# Protect the 25-influence alliance budget until the coalition is complete.
	if (rs.allies >= int(Tuning.s("MAX_ALLIES")) or rs.influence >= 40.0) and _ok(rs, &"DIP2"):
		return {"card": &"DIP2", "target": &""}
	for sid: StringName in [&"agr", &"ind"]:
		var ss := rs.sector(sid)
		if not ss.suff_played and ss.progress >= 50.0 and _ok(rs, SUFF_CARD[sid]):
			return {"card": SUFF_CARD[sid], "target": &""}
	if tra.progress < tra.cap() and _ok(rs, &"TRA1"):
		return {"card": &"TRA1", "target": &""}
	for sid in _sectors_by_progress(rs):
		var ss := rs.sector(sid)
		if ss.progress < ss.cap() and _ok(rs, TECH_CARD[sid]):
			return {"card": TECH_CARD[sid], "target": &""}
		if not ss.suff_played and _ok(rs, SUFF_CARD[sid]):
			return {"card": SUFF_CARD[sid], "target": &""}
	# Ledger watch: late-game money goes into sinks while net is not safely negative.
	if rs.net_emissions() > -8.0 and _ok(rs, &"SNK1"):
		return {"card": &"SNK1", "target": &""}
	if rs.happiness < 55.0 and _ok(rs, &"SOC2"):
		return {"card": &"SOC2", "target": &""}
	return {"card": &"pass", "target": &""}


## Run one full autoplay run headlessly. Returns the terminal TurnRecord.
static func autoplay(strategy: StringName, seed_value: int, canonical: bool = false,
		unlocked_knowledge: Array = []) -> RunState:
	var gen := WorldGen.generate(seed_value, canonical)
	var rs := RunState.new_run(gen, Catalog.load_default(), unlocked_knowledge)
	var safety := 200
	while rs.phase != RunState.Phase.ENDED and safety > 0:
		safety -= 1
		var choice := decide(strategy, rs)
		if choice["card"] != &"pass":
			rs.play_card(choice["card"], choice["target"])
		rs.resolve_year()
	return rs
