class_name PostMortem
## Defeat post-mortem (docs/Phase_4/06): a pure heuristic over the turn log
## that names the pivotal turn which sealed the run's fate, so the player
## understands the mistake and wants to retry immediately. Never a second
## simulation - it only reads TurnRecords.

const HAPPINESS_WEIGHT := 5.0    # damage normalization: 1 happiness ~ 5 money
const ABSORPTION_WEIGHT := 25.0  # 1 Gt/yr of sink ~ 25 money
const SUMMIT_MISS_WEIGHT := 40.0
const BANKED_PASS_WEIGHT := 25.0
const BANKED_MONEY_MIN := 150.0


## Returns { "pivot_year": int, "pivot_turn": int, "headline": String,
##           "lines": PackedStringArray } - empty dict when no records exist.
static func analyze(records: Array[TurnRecord], catalog: Catalog) -> Dictionary:
	if records.is_empty():
		return {}
	var last := records[records.size() - 1]
	match last.end_status:
		&"WIN_NEUTRAL":
			return _analyze_win(records)
		&"LOSS_REVOLT":
			return _analyze_revolt(records)
		&"LOSS_NOT_NEUTRAL":
			return _analyze_timeout(records, catalog)
		_:
			return _analyze_overheat(records, catalog)


## The turn's avoidable damage: unanswered crisis losses, a missed summit,
## and passing with a full treasury while the clock ran.
static func _turn_swing(rec: TurnRecord) -> float:
	var swing := 0.0
	for crisis in rec.crises:
		if crisis.get("answered", false) or String(crisis.get("kind", "")) != "crisis":
			continue
		var damages: Dictionary = crisis.get("damages", {})
		swing += float(damages.get("money", 0.0))
		swing += float(damages.get("happiness", 0.0)) * HAPPINESS_WEIGHT
		swing += float(damages.get("absorption", 0.0)) * ABSORPTION_WEIGHT
		swing += float(damages.get("influence", 0.0))
		swing += float(crisis.get("on_draw_e", 0.0)) * ABSORPTION_WEIGHT
	if not rec.summit.is_empty() and not bool(rec.summit.get("met", true)):
		swing += SUMMIT_MISS_WEIGHT
	if rec.actions.is_empty() and rec.money >= BANKED_MONEY_MIN:
		swing += BANKED_PASS_WEIGHT
	return swing


static func _pivot_by_swing(records: Array[TurnRecord]) -> TurnRecord:
	var best: TurnRecord = records[0]
	var best_swing := -1.0
	for rec in records:
		var swing := _turn_swing(rec)
		if swing > best_swing:  # strict: earliest turn wins ties
			best_swing = swing
			best = rec
	return best


static func _crisis_names(rec: TurnRecord, catalog: Catalog, answered: bool) -> PackedStringArray:
	var names: PackedStringArray = []
	for crisis in rec.crises:
		if bool(crisis.get("answered", false)) != answered:
			continue
		var id := String(crisis.get("id", ""))
		var def := {}
		for e in catalog.events:
			if String(e["id"]) == id:
				def = e
		names.append(String(def.get("name", id)))
	return names


static func _analyze_overheat(records: Array[TurnRecord], catalog: Catalog) -> Dictionary:
	var pivot := _pivot_by_swing(records)
	var lines: PackedStringArray = []
	var unanswered := _crisis_names(pivot, catalog, false)
	if not pivot.summit.is_empty() and not bool(pivot.summit.get("met", true)):
		lines.append("Turn %d (%d): the %s target slipped away - net %.0f against %.0f. The world stopped believing there." % [
			pivot.turn, pivot.year, String(pivot.summit.get("name", "summit")),
			float(pivot.summit.get("value", 0.0)), float(pivot.summit.get("target", 0.0))])
	if not unanswered.is_empty():
		lines.append("Turn %d (%d) took the worst unanswered hits: %s." % [
			pivot.turn, pivot.year, ", ".join(unanswered)])
	if pivot.actions.is_empty() and pivot.money >= BANKED_MONEY_MIN:
		lines.append("Turn %d (%d): %d funds sat banked while the clock ran." % [
			pivot.turn, pivot.year, roundi(pivot.money)])
	var last := records[records.size() - 1]
	if last.emissions_world > last.emissions_city:
		lines.append("The world's blocs (%.0f Gt) out-emitted your sphere (%.0f Gt): more treaties and funded transitions abroad next time." % [
			last.emissions_world, last.emissions_city])
	if lines.is_empty():
		lines.append("No single blunder - the transition was simply too slow for the curve.")
	return {
		"pivot_year": pivot.year, "pivot_turn": pivot.turn,
		"headline": "Pivotal turn: %d (%d) - the overheat was sealed there." % [pivot.turn, pivot.year],
		"lines": lines,
	}


static func _analyze_revolt(records: Array[TurnRecord]) -> Dictionary:
	var pivot: TurnRecord = records[0]
	var worst_drop := -INF
	var prev_h := -1.0
	for rec in records:
		if prev_h >= 0.0:
			var drop := prev_h - rec.happiness
			if drop > worst_drop:
				worst_drop = drop
				pivot = rec
		prev_h = rec.happiness
	var causes: PackedStringArray = []
	var cost_h := 0.0
	for action in pivot.actions:
		cost_h += float(action.get("cost_happiness", 0.0))
	if cost_h > 0.0:
		causes.append("policies paid in happiness (-%d)" % roundi(cost_h))
	var crisis_h := 0.0
	for crisis in pivot.crises:
		crisis_h += float(crisis.get("damages", {}).get("happiness", 0.0))
	if crisis_h > 0.0:
		causes.append("unanswered crises (-%d)" % roundi(crisis_h))
	if pivot.overshoot_stress > 0.0:
		causes.append("overshoot stress (-%d)" % roundi(pivot.overshoot_stress))
	if not pivot.summit.is_empty() and not bool(pivot.summit.get("met", true)):
		causes.append("the failed summit")
	var lines: PackedStringArray = []
	lines.append("Happiness collapsed hardest on turn %d (%d): -%d in one turn, driven by %s." % [
		pivot.turn, pivot.year, roundi(maxf(worst_drop, 0.0)),
		", ".join(causes) if not causes.is_empty() else "slow erosion"])
	lines.append("Wellbeing policies, answered crises and sufficiency co-benefits are the counterweights - and the Public Support Fund now exists for exactly this trap.")
	return {
		"pivot_year": pivot.year, "pivot_turn": pivot.turn,
		"headline": "Pivotal turn: %d (%d) - the revolt began there." % [pivot.turn, pivot.year],
		"lines": lines,
	}


static func _analyze_timeout(records: Array[TurnRecord], catalog: Catalog) -> Dictionary:
	var last := records[records.size() - 1]
	var pivot := _pivot_by_swing(records)
	var lines: PackedStringArray = []
	var passes := 0
	for rec in records:
		if rec.actions.is_empty():
			passes += 1
	if last.emissions_world > last.absorption * 0.6:
		lines.append("2100 closed with the world's blocs still emitting %.0f Gt - the diplomacy lever (treaties, funded transitions) was left on the table." % last.emissions_world)
	if last.emissions_city > last.absorption * 0.5:
		lines.append("Your own sphere still emitted %.0f Gt against %.0f absorbed - the home transition never finished." % [last.emissions_city, last.absorption])
	if passes >= 3:
		lines.append("%d turns passed without funding a single card." % passes)
	if _turn_swing(pivot) > 0.0:
		lines.append("The costliest single turn was %d (%d)." % [pivot.turn, pivot.year])
	if lines.is_empty():
		lines.append("Close - the balance was almost held. One more sink or treaty a decade earlier.")
	return {
		"pivot_year": pivot.year, "pivot_turn": pivot.turn,
		"headline": "The century ran out at net %+.1f Gt - not neutral, not broken." % last.net,
		"lines": lines,
	}


static func _analyze_win(records: Array[TurnRecord]) -> Dictionary:
	var last := records[records.size() - 1]
	var best_chain := 0
	var best_chain_rec: TurnRecord = last
	for rec in records:
		if rec.combo_chain > best_chain:
			best_chain = rec.combo_chain
			best_chain_rec = rec
	var lines: PackedStringArray = []
	lines.append("The curve bent on turn %d (%d): the world absorbed more than it emitted, %d years before the deadline." % [
		last.turn, last.year, int(Tuning.c("END_YEAR")) - last.year])
	if best_chain >= 3:
		lines.append("The engine peaked at chain x%d on turn %d - that compounding paid for the endgame." % [
			best_chain, best_chain_rec.turn])
	return {
		"pivot_year": last.year, "pivot_turn": last.turn,
		"headline": "Pivotal turn: %d (%d) - the drawdown moment." % [last.turn, last.year],
		"lines": lines,
	}
