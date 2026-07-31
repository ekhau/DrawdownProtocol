class_name Strategies
## Scripted decision policies for the three strategy archetypes
## (docs/Phase_1/02_Sample_Runs.md). Used by the debug autoplay buttons, the
## headless batch harness and the regression fixtures.
##
## decide() returns ONE action; the autoplay loop calls it repeatedly inside a
## turn until it returns pass (multi-card turns), then resolves the turn.
## All card choices come from the current MARKET (rs.market) - strategies see
## exactly what a player sees.
## Actions: {"card": id|&"pass", "target": region|&"", "project": id|&""}.
##
## Archetypes: Safe answers crises, buys down world actors, builds sinks and
## an even transition; Mixed goes diplomacy-first (allies, treaties, funded
## transitions abroad); Risky is a pure home tech rush plus moonshot bets that
## ignores crises, sufficiency, sinks and the whole outside world - it can
## never reach global neutrality by design.

const NAMES: Array[StringName] = [&"safe", &"risky", &"mixed"]

const PASS := {"card": &"pass", "target": &"", "project": &""}


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


## Market offers as defs, in offer order, playable-and-affordable only.
static func _offers(rs: RunState, reserve: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in rs.market:
		if not _ok(rs, id):
			continue
		if rs.money - rs.effective_cost_money(id) < reserve:
			continue
		out.append(rs.catalog.card(id))
	return out


static func _has_op(card: Dictionary, op: String) -> bool:
	for eff: Dictionary in card.get("effects", []):
		if String(eff.get("op", "")) == op:
			return true
	return false


static func _is_progress(card: Dictionary) -> bool:
	return _has_op(card, "sector_progress") or _has_op(card, "joint_progress")


static func _is_restoration(card: Dictionary) -> bool:
	return _has_op(card, "reforest") or _has_op(card, "sink_now")


## The cheapest offer answering the first unanswered crisis (offer order).
static func _answer_crisis(rs: RunState, reserve: float) -> Dictionary:
	for crisis in rs.unanswered_crises():
		var response: Dictionary = rs.crisis_def(crisis["id"]).get("response", {})
		var best: Dictionary = {}
		for card in _offers(rs, reserve):
			var hits := false
			for tag in response.get("tags_any", []):
				if (card.get("tags", []) as Array).has(String(tag)):
					hits = true
			if hits and (best.is_empty()
					or rs.effective_cost_money(StringName(String(card["id"])))
						< rs.effective_cost_money(StringName(String(best["id"])))):
				best = card
		if not best.is_empty():
			return _card(StringName(String(best["id"])))
	return PASS


## Safe (Steady Shield): answer everything, keep happiness healthy, buy down
## the world's blocs when offered, grow sinks, transition evenly. Banks a
## reserve and sustains the Global Sink Trust.
static func _decide_safe(rs: RunState) -> Dictionary:
	var answer := _answer_crisis(rs, 80.0)
	if answer["card"] != &"pass":
		return answer
	if rs.turn_index() >= 2 and rs.money >= 320.0 \
			and rs.can_start_project_reason(&"global_sink_trust") == &"ok":
		return _project(&"global_sink_trust")
	if rs.turn_index() >= 4 and rs.money >= 420.0 and rs.happiness < 65.0 \
			and rs.can_start_project_reason(&"universal_services") == &"ok":
		return _project(&"universal_services")
	if rs.happiness < 45.0:
		for card in _offers(rs, 60.0):
			if _has_op(card, "wellbeing"):
				return _card(StringName(String(card["id"])))
	for card in _offers(rs, 100.0):
		if _has_op(card, "actor_fund") or _has_op(card, "actor_treaty"):
			return _card(StringName(String(card["id"])))
	for card in _offers(rs, 60.0):
		if _has_op(card, "ally") and rs.influence >= float(card.get("cost_influence", 0)) + 4.0:
			return _card(StringName(String(card["id"])))
	for card in _offers(rs, 80.0):
		if _has_op(card, "media") and not rs.media:
			return _card(StringName(String(card["id"])))
	if rs.absorption < 30.0:
		for card in _offers(rs, 80.0):
			if _is_restoration(card) and not card.has("risk"):
				return _card(StringName(String(card["id"])))
	if rs.adapt < 20.0:
		for card in _offers(rs, 120.0):
			if _has_op(card, "adapt") and not _is_restoration(card):
				return _card(StringName(String(card["id"])))
	var progress_pick := _progress_pick(rs, 80.0, true)
	if progress_pick["card"] != &"pass":
		return progress_pick
	if rs.happiness < 60.0:
		for card in _offers(rs, 120.0):
			if _has_op(card, "wellbeing"):
				return _card(StringName(String(card["id"])))
	# Cheap response cards earn influence even without a crisis to answer.
	for card in _offers(rs, 250.0):
		if String(card.get("category", "")) == "response":
			return _card(StringName(String(card["id"])))
	return _greedy_spend(rs, 250.0)


## Banked money is a wasted turn against a clock: when rich, fund the
## cheapest remaining sure offer rather than pass (no risk cards).
static func _greedy_spend(rs: RunState, threshold: float) -> Dictionary:
	if rs.money < threshold:
		return PASS
	var best: Dictionary = {}
	for card in _offers(rs, threshold * 0.5):
		if card.has("risk"):
			continue
		if best.is_empty() or rs.effective_cost_money(StringName(String(card["id"]))) \
				< rs.effective_cost_money(StringName(String(best["id"]))):
			best = card
	if best.is_empty():
		return PASS
	return _card(StringName(String(best["id"])))


## Progress choice shared by safe/mixed: sufficiency lift when a sector needs
## it, else the offer that moves the laggard sector; never risk cards.
static func _progress_pick(rs: RunState, reserve: float, allow_suff: bool) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	for card in _offers(rs, reserve):
		if not _is_progress(card) or card.has("risk"):
			continue
		var score := 0.0
		for eff: Dictionary in card.get("effects", []):
			match String(eff.get("op", "")):
				"sector_progress":
					var ss := rs.sector(StringName(String(eff["sector"])))
					score += float(eff["amount"]) * (1.5 - ss.progress / 100.0)
					if bool(eff.get("lifts_cap", false)):
						if not allow_suff:
							score = -INF
						elif not ss.suff_played:
							score += 12.0  # lifts are how the endgame opens
				"joint_progress":
					score += float(eff["amount"]) * 2.2
		if score > best_score:
			best_score = score
			best = card
	if best.is_empty() or best_score <= 0.0:
		return PASS
	return _card(StringName(String(best["id"])))


## Risky (Moonshot Rush): home tech and research bets only, several per turn;
## never answers a crisis on purpose, never touches diplomacy, sufficiency,
## sinks or wellbeing. The outside world keeps drifting - and wins.
static func _decide_risky(rs: RunState) -> Dictionary:
	for card in _offers(rs, 0.0):
		if card.has("risk"):
			return _card(StringName(String(card["id"])))
	var best: Dictionary = {}
	var best_amount := 0.0
	for card in _offers(rs, 0.0):
		if not _is_progress(card):
			continue
		if (card.get("tags", []) as Array).has("sufficiency"):
			continue
		if _has_op(card, "actor_fund") or _has_op(card, "actor_treaty"):
			continue
		var amount := 0.0
		for eff: Dictionary in card.get("effects", []):
			if String(eff.get("op", "")) == "sector_progress":
				var ss := rs.sector(StringName(String(eff["sector"])))
				if ss.progress < ss.cap():
					amount += float(eff["amount"])
			elif String(eff.get("op", "")) == "joint_progress":
				amount += float(eff["amount"]) * 2.0
		if amount > best_amount:
			best_amount = amount
			best = card
	if not best.is_empty():
		return _card(StringName(String(best["id"])))
	return PASS


## Mixed (Grand Alliance): diplomacy-first - allies, treaties and funded
## transitions abroad - then crises, combos and the home transition.
## Sustains the Continental Rail Compact.
static func _decide_mixed(rs: RunState) -> Dictionary:
	for card in _offers(rs, 60.0):
		if _has_op(card, "actor_fund") or _has_op(card, "actor_treaty"):
			return _card(StringName(String(card["id"])))
	var answer := _answer_crisis(rs, 60.0)
	if answer["card"] != &"pass":
		return answer
	for card in _offers(rs, 60.0):
		if _has_op(card, "ally") and rs.influence >= float(card.get("cost_influence", 0)) + 6.0:
			return _card(StringName(String(card["id"])))
	if rs.turn_index() >= 2 and rs.money >= 350.0 \
			and rs.can_start_project_reason(&"continental_rail") == &"ok":
		return _project(&"continental_rail")
	if rs.turn_index() >= 5 and rs.money >= 420.0 \
			and rs.can_start_project_reason(&"global_sink_trust") == &"ok":
		return _project(&"global_sink_trust")
	for card in _offers(rs, 70.0):
		if _has_op(card, "media") and not rs.media:
			return _card(StringName(String(card["id"])))
	if rs.happiness < 45.0:
		for card in _offers(rs, 50.0):
			if _has_op(card, "wellbeing"):
				return _card(StringName(String(card["id"])))
	if rs.absorption < 28.0:
		for card in _offers(rs, 70.0):
			if _is_restoration(card) and not card.has("risk"):
				return _card(StringName(String(card["id"])))
	var progress_pick := _progress_pick(rs, 70.0, true)
	if progress_pick["card"] != &"pass":
		return progress_pick
	# Late-game ledger watch: spend spare funds on whatever still helps.
	if rs.net_emissions() > -3.0:
		for card in _offers(rs, 200.0):
			if _is_restoration(card) and not card.has("risk"):
				return _card(StringName(String(card["id"])))
	for card in _offers(rs, 300.0):
		if String(card.get("category", "")) == "response":
			return _card(StringName(String(card["id"])))
	return _greedy_spend(rs, 250.0)


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
		unlocked_knowledge: Array = [], archetype_id: StringName = &"") -> RunState:
	var gen := WorldGen.generate(seed_value, canonical)
	var rs := RunState.new_run(gen, Catalog.load_default(), unlocked_knowledge, archetype_id)
	var safety := 60
	while rs.phase != RunState.Phase.ENDED and safety > 0:
		safety -= 1
		play_turn(strategy, rs)
	return rs
