class_name RunState
extends RefCounted
## The single source of truth for one run: the per-turn race against the
## climate clock (docs/Phase_1/01_Balance_Model.md, docs/Phase_4/01-05).
## One turn = YEARS_PER_TURN years; a run is 15 decision turns, 2030-2100.
## Each turn: income + project upkeep -> 3 events drawn (may spike emissions
## and inject bonus market cards) -> a market of 3-5 cards is dealt -> the
## player funds cards that answer crises, bend world-actor curves and fire
## combos -> resolve applies the ledger (city + world actors), warming, drift,
## unanswered crises, summits, feedbacks - then the world's blocs advance
## their own emission curves. Victory: net <= 0 before the tipping point.
## Defeat: +2.0 C (clock 100%), happiness 0 (revolt), or 2100 net-positive.
## Headless-capable: never touches nodes, autoloads or OS. Nondeterminism
## lives in three seeded streams: rng_events (crisis draw), rng_market
## (market deal), rng_risk (push-your-luck cards, consumed only on play).

signal year_started(year: int)
signal card_played(card_id: StringName, accepted: bool)
signal year_advanced(report: TurnRecord)
signal event_struck(event_id: StringName, region_id: StringName, opportunity: StringName)
signal crisis_answered(crisis_id: StringName, card_id: StringName)
signal combo_triggered(combo_id: StringName, chain: int, mult: float)
signal card_unlocked(card_id: StringName)
signal project_changed(project_id: StringName, status: StringName)
signal warming_band_changed(band: int)
signal ally_changed(region_id: StringName, is_ally: bool)
signal summit_resolved(summit_id: StringName, met: bool)
signal risk_resolved(card_id: StringName, success: bool)
signal curve_bent(year: int)
signal run_ended(outcome: StringName, knowledge_points: int)

enum Phase { AWAIT_ACTION, RESOLVING, ENDED }

const DAMAGE_KEYS: Array[String] = ["money", "happiness", "absorption", "influence"]
const REWARD_KEYS: Array[String] = ["money", "influence", "happiness", "knowledge"]


class SectorState:
	extends RefCounted
	var base: float = 0.0
	var progress: float = 0.0
	var suff_played: bool = false

	func cap() -> float:
		return float(Tuning.c("FULL_CAP")) if suff_played else float(Tuning.c("TECH_CAP"))


class ReforestEntry:
	extends RefCounted
	var per_turn: float = 0.0
	var turns_left: int = 0


class ProjectState:
	extends RefCounted
	var id: StringName = &""
	var turns_left: int = 0


# --- identity / timeline ---
var run_seed: int = 0
var year: int = 2030
var phase: Phase = Phase.AWAIT_ACTION
# --- pillars and warming ---
var temp: float = 1.30
var money: float = 100.0
var happiness: float = 60.0
var influence: float = 10.0
# --- carbon ledger ---
var sectors: Dictionary = {}                  # StringName -> SectorState
var absorption: float = 20.0
var e_extra: float = 0.0
var reforest_queue: Array[ReforestEntry] = []
# --- diplomacy / society ---
var allies: int = 0
var adapt: float = 0.0
var media: bool = false
var window: bool = false
var fire_discount: bool = false
var flood_rebuild: bool = false
# --- crises (drawn at turn start; resolved at turn end) ---
var pending_crises: Array[Dictionary] = []    # {id, kind, region_id, answered, answered_by, on_draw_e}
# --- the project market (dealt at turn start) ---
var market: Array[StringName] = []            # current offers (plays consume them)
var market_bonus: Array[StringName] = []      # subset injected by events this turn
var market_enforced: bool = true              # op-level test suites may disable
# --- world actors (the rest of the world's emission curves) ---
var world_actors: Array[Dictionary] = []      # [{id, name, emissions, trend, floor}]
# --- city archetype (selected at run start; {} = baseline coalition) ---
var archetype: Dictionary = {}
# --- meta-lesson cards (unlocked by past defeats, available from turn 1) ---
var meta_cards: Array = []                    # Array[String] of card ids
# --- summits (COPs) ---
var summit_results: Dictionary = {}           # summit id -> "met"|"missed"
var curve_bent_year: int = 0                  # first year net <= 0 (0 = never)
# --- combos ---
var combo_chain: int = 0
var combos_fired_run: Dictionary = {}         # combo id -> times fired this run
# --- long-term projects ---
var active_projects: Array[ProjectState] = []
var project_history: Dictionary = {}          # String -> "completed"|"failed"|"abandoned"
var passives: Dictionary = {}                 # aggregated completion passives
# --- run counters (deck growth + meta) ---
var crises_answered_total: int = 0
var combos_total: int = 0
var projects_completed: int = 0
var kp_earned: int = 0
var unlocked_card_ids: Array[StringName] = [] # unlocked THIS run by play
# --- feedback loop one-shots (event id -> trigger year) ---
var fires: int = 0
var feedback_years: Dictionary = {}
# --- world (Phase 3) ---
var world: Array[RegionData] = []
var rng_events: RandomNumberGenerator
var rng_market: RandomNumberGenerator
var rng_risk: RandomNumberGenerator
var records: Array[TurnRecord] = []
var catalog: Catalog
var unlocked_knowledge: Array = []

var _events_by_id: Dictionary = {}
var _pending_income: Dictionary = {}
var _turn_actions: Array[Dictionary] = []
var _turn_tags: Dictionary = {}               # tag -> count, this turn
var _turn_combos: Array[Dictionary] = []      # [{id, chain, mult, rewards}]
var _turn_project_events: Array[Dictionary] = []
var _turn_unlocks: Array[StringName] = []
var _turn_market_offered: Array[StringName] = []  # snapshot at deal time


# Named accessors for the three MVP feedback loops (debug overlay / tests).
var permafrost: bool:
	get: return feedback_years.has("permafrost_methane")
var ocean_weak: bool:
	get: return feedback_years.has("ocean_sink_weakening")
var amazon: bool:
	get: return feedback_years.has("amazon_dieback")


static func new_run(gen: WorldGen.WorldGenResult, base_catalog: Catalog, unlocked_ids: Array = [],
		archetype_id: StringName = &"", meta_card_ids: Array = []) -> RunState:
	var rs := RunState.new()
	rs.run_seed = gen.run_seed
	rs.year = int(Tuning.c("START_YEAR"))
	rs.temp = gen.temp_start
	rs.money = gen.money_start
	rs.happiness = gen.happiness_start
	rs.influence = float(Tuning.s("I_START"))
	rs.absorption = gen.absorption_start
	for sector in WorldEnums.SECTOR_ORDER:
		var ss := SectorState.new()
		ss.base = float(gen.sector_bases[sector])
		rs.sectors[sector] = ss
	rs.world = gen.regions
	rs.rng_events = RandomNumberGenerator.new()
	rs.rng_events.seed = SeedUtil.sub_seed(gen.run_seed, SeedUtil.STREAM_EVENTS)
	rs.rng_market = RandomNumberGenerator.new()
	rs.rng_market.seed = SeedUtil.sub_seed(gen.run_seed, SeedUtil.STREAM_MARKET)
	rs.rng_risk = RandomNumberGenerator.new()
	rs.rng_risk.seed = SeedUtil.sub_seed(gen.run_seed, SeedUtil.STREAM_RISK)
	rs.unlocked_knowledge = unlocked_ids.duplicate()
	rs.meta_cards = meta_card_ids.duplicate()
	rs.catalog = base_catalog.duplicate_patched(unlocked_ids)
	for e in rs.catalog.events:
		rs._events_by_id[String(e["id"])] = e
	# World actors: deep-copied definitions become live per-run state.
	for a in rs.catalog.actors:
		rs.world_actors.append({
			"id": String(a["id"]), "name": String(a.get("name", a["id"])),
			"emissions": float(a["emissions"]), "trend": float(a["trend"]),
			"floor": float(a.get("floor", 1.0)),
		})
	var grants := base_catalog.grants(unlocked_ids)
	rs.media = bool(grants["media"])
	rs.adapt = minf(float(Tuning.s("ADAPT_MAX")), float(grants["adapt"]))
	# City archetype: multiplicative/additive modifiers over the generated
	# baseline, so procgen jitter and archetype identity compose.
	if archetype_id != &"":
		rs.archetype = rs.catalog.archetype(archetype_id)
	if not rs.archetype.is_empty():
		rs.money *= float(rs.archetype.get("money_mult", 1.0))
		rs.influence = maxf(0.0, rs.influence + float(rs.archetype.get("influence_bonus", 0)))
		rs.happiness = clampf(rs.happiness + float(rs.archetype.get("happiness_delta", 0)), 0.0, 100.0)
		var smult: Dictionary = rs.archetype.get("sector_mult", {})
		for sector in WorldEnums.SECTOR_ORDER:
			rs.sector(sector).base *= float(smult.get(String(sector), 1.0))
		for i in int(rs.archetype.get("start_allies", 0)):
			var neutrals := rs.neutral_regions()
			if neutrals.is_empty():
				break
			neutrals[0].ally_state = WorldEnums.AllyState.ALLY
			rs.allies += 1
	rs._begin_year()
	return rs


# ---------------------------------------------------------------- queries ---

func sector(id: StringName) -> SectorState:
	return sectors[id]


func avg_progress() -> float:
	var total := 0.0
	for s in WorldEnums.SECTOR_ORDER:
		total += sector(s).progress
	return total / WorldEnums.SECTOR_ORDER.size()


## City-sphere gross emissions (the player's direct levers) + feedback extras.
func gross_emissions() -> float:
	var e := e_extra
	for s in WorldEnums.SECTOR_ORDER:
		var ss := sector(s)
		e += ClimateCalc.sector_emissions(ss.base, ss.progress)
	return e


## What the rest of the world emits: the sum of the actor curves.
func world_emissions() -> float:
	var e := 0.0
	for a in world_actors:
		e += float(a["emissions"])
	return e


## The world's current between-turn drift (before ally damping).
func world_trend() -> float:
	var t := 0.0
	for a in world_actors:
		t += maxf(0.0, float(a["trend"]))
	return t


func total_emissions() -> float:
	return gross_emissions() + world_emissions()


## THE adversary number: global net. Victory the moment it reaches <= 0.
func net_emissions() -> float:
	return total_emissions() - absorption


func warming_band() -> int:
	return ClimateCalc.band(temp)


## 1-based decision-turn index (turn 1 = 2030; turn 15 = 2100).
func turn_index() -> int:
	@warning_ignore("integer_division")
	return (year - int(Tuning.c("START_YEAR"))) / int(Tuning.c("YEARS_PER_TURN")) + 1


static func total_turns() -> int:
	@warning_ignore("integer_division")
	return (int(Tuning.c("END_YEAR")) - int(Tuning.c("START_YEAR"))) \
			/ int(Tuning.c("YEARS_PER_TURN")) + 1


## The Climate Clock: warming as percent of the tipping track (100% = loss).
func clock_pct() -> float:
	return ClimateCalc.clock_pct(temp)


## Forecast of next turn's clock rise (clock points), assuming no further
## plays: current city emissions + advanced actor curves - stressed sinks.
func clock_forecast_pct() -> float:
	var damp := allies * float(Tuning.s("ACTOR_TREND_PER_ALLY"))
	var next_world := 0.0
	for a in world_actors:
		var use := minf(damp, maxf(0.0, float(a["trend"])))
		damp -= use
		next_world += maxf(float(a["floor"]), float(a["emissions"]) + maxf(0.0, float(a["trend"])) - use)
	var next_a := maxf(ClimateCalc.a_floor(), absorption - ClimateCalc.sink_stress(temp))
	var n := gross_emissions() + next_world - next_a
	return ClimateCalc.clock_delta_pct(ClimateCalc.warming_delta(n))


func resilience() -> float:
	return SocietyCalc.resilience(happiness, adapt)


func region_by_id(id: StringName) -> RegionData:
	for r in world:
		if r.id == id:
			return r
	return null


## Derived region display values (regions render state, never own it).
func region_emissions(r: RegionData) -> float:
	var e := 0.0
	for s in WorldEnums.SECTOR_ORDER:
		var ss := sector(s)
		e += ClimateCalc.sector_emissions(ss.base * r.share_for(s), ss.progress)
	return e


func region_absorption(r: RegionData) -> float:
	return absorption * r.sink_share


func neutral_regions() -> Array[RegionData]:
	var out: Array[RegionData] = []
	for r in world:
		if r.ally_state == WorldEnums.AllyState.NEUTRAL:
			out.append(r)
	return out


func ally_regions() -> Array[RegionData]:
	var out: Array[RegionData] = []
	for r in world:
		if r.ally_state == WorldEnums.AllyState.ALLY:
			out.append(r)
	return out


## Cards in the player's current pool (starting cards + run unlocks + meta
## lessons). Bonus-only cards exist only while an event holds them in the
## market.
func is_card_available(card_id: StringName) -> bool:
	var card := catalog.card(card_id)
	if card.is_empty():
		return false
	if bool(card.get("bonus_only", false)):
		return market.has(card_id)
	if card.has("meta_unlock"):
		return meta_cards.has(String(card_id))
	return not card.has("unlock") or unlocked_card_ids.has(card_id)


## The market draw pool (excludes bonus-only injections).
func available_cards() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in catalog.cards:
		if bool(c.get("bonus_only", false)):
			continue
		if is_card_available(StringName(String(c["id"]))):
			out.append(c)
	return out


## Test/debug hook: force this turn's market (headless suites compose exact
## scenarios; the UI never calls this).
func force_market(ids: Array) -> void:
	market = []
	for id in ids:
		market.append(StringName(String(id)))
	_turn_market_offered = market.duplicate()


func cards_played_this_turn() -> int:
	return _turn_actions.size()


## Effects applied by the most recent card play this turn (UI preview + tests).
func last_action_effects() -> Array:
	if _turn_actions.is_empty():
		return []
	return _turn_actions.back().get("effects_applied", [])


## Combos fired so far this turn (UI banners read the last entry).
func turn_combos() -> Array[Dictionary]:
	return _turn_combos


func unanswered_crises() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in pending_crises:
		if not c["answered"]:
			out.append(c)
	return out


func crisis_def(id: StringName) -> Dictionary:
	return _events_by_id.get(String(id), {})


# ------------------------------------------------------ card playability ---

## The fire-discount price; the single source of truth for what the UI reads.
func effective_cost_money(card_id: StringName) -> float:
	var card := catalog.card(card_id)
	if card.is_empty():
		return 0.0
	var cost := float(card.get("cost_money", 0))
	if fire_discount and card.get("tags", []).has("restoration"):
		cost *= float(Tuning.s("FIRE_DISCOUNT_MULT"))
	return cost


## Human-readable reason codes; the UI derives card states from these only.
func can_play_reason(card_id: StringName) -> StringName:
	if phase == Phase.ENDED:
		return &"ended"
	if phase != Phase.AWAIT_ACTION:
		return &"resolving"
	var card := catalog.card(card_id)
	if card.is_empty():
		return &"unknown_card"
	if not is_card_available(card_id):
		return &"card_locked"
	if market_enforced and not market.has(card_id):
		return &"not_in_market"
	if _turn_actions.size() >= int(Tuning.s("MAX_CARDS_PER_TURN")):
		return &"turn_limit"
	if effective_cost_money(card_id) > money:
		return &"no_money"
	if float(card.get("cost_influence", 0)) > influence:
		return &"no_influence"
	if float(card.get("cost_happiness", 0)) > happiness:
		return &"no_happiness"
	var requires: Dictionary = card.get("requires", {})
	if int(requires.get("allies_min", 0)) > allies:
		return &"locked_allies"
	for eff: Dictionary in card.get("effects", []):
		match String(eff.get("op", "")):
			"ally":
				if allies >= int(Tuning.s("MAX_ALLIES")) or neutral_regions().is_empty():
					return &"no_target"
			"actor_fund":
				if _actor_by_rank(true).is_empty():
					return &"no_target"
			"actor_treaty":
				if _actor_by_rank(false).is_empty():
					return &"no_target"
			"media":
				if media:
					return &"media_active"
			"sector_progress":
				var ss := sector(StringName(eff["sector"]))
				var lifts := bool(eff.get("lifts_cap", false))
				if ss.progress >= ss.cap() and not (lifts and not ss.suff_played):
					return &"capped"
	return &"ok"


func can_play(card_id: StringName) -> Error:
	# NOTE: the Phase 4 spec names ERR_INSUFFICIENT_FUNDS, which does not exist
	# in Godot's Error enum; ERR_CANT_ACQUIRE_RESOURCE is the closest match.
	match can_play_reason(card_id):
		&"ok": return OK
		&"no_money", &"no_influence", &"no_happiness": return ERR_CANT_ACQUIRE_RESOURCE
		&"locked_allies", &"card_locked": return ERR_UNCONFIGURED
		&"media_active": return ERR_ALREADY_IN_USE
		&"no_target": return ERR_DOES_NOT_EXIST
		&"unknown_card": return ERR_INVALID_PARAMETER
	return ERR_UNAVAILABLE  # ended / resolving / turn_limit / capped / not_in_market


# ------------------------------------------------- step 2: player actions ---

## Play a card (up to MAX_CARDS_PER_TURN per year). target_region is required
## only by cards with an "ally" effect (DIP1); empty auto-picks a neutral.
func play_card(card_id: StringName, target_region: StringName = &"") -> Error:
	var err := can_play(card_id)
	if err != OK:
		card_played.emit(card_id, false)
		return err
	var card := catalog.card(card_id)

	# Resolve the ally target up front (validation before any mutation).
	var ally_target: RegionData = null
	var wants_ally := false
	for eff: Dictionary in card["effects"]:
		if String(eff.get("op", "")) == "ally":
			wants_ally = true
	if wants_ally:
		if target_region == &"":
			ally_target = neutral_regions()[0]
		else:
			ally_target = region_by_id(target_region)
			if ally_target == null or ally_target.ally_state != WorldEnums.AllyState.NEUTRAL:
				card_played.emit(card_id, false)
				return ERR_INVALID_PARAMETER

	# 1. Pay (money, influence, happiness).
	var cost_m := effective_cost_money(card_id)
	var cost_i := float(card.get("cost_influence", 0))
	var cost_h := float(card.get("cost_happiness", 0))
	var used_discount: bool = fire_discount and (card.get("tags", []) as Array).has("restoration")
	money -= cost_m
	influence -= cost_i
	happiness = clampf(happiness - cost_h, 0.0, 100.0)
	if used_discount:
		fire_discount = false

	# 2. Apply effects in catalog order.
	var applied: Array[Dictionary] = []
	var waiver: StringName = &"none"
	for eff: Dictionary in card["effects"]:
		var op := String(eff.get("op", ""))
		match op:
			"happiness", "wellbeing":
				var amount := float(eff["amount"])
				var waived := false
				if amount < 0.0 and bool(eff.get("waivable", false)):
					# Waiver precedence (C1): media first and the window is NOT
					# consumed when media already covers it.
					if media:
						waiver = &"media"
						waived = true
					elif window:
						waiver = &"window"
						window = false
						waived = true
				var add := 0.0
				if not waived:
					add = clampf(happiness + amount, 0.0, 100.0) - happiness
					happiness += add
				applied.append({"op": op, "requested": amount, "applied": add, "waived": waived})
			"media":
				media = true
				applied.append({"op": op})
			"ally":
				allies += 1
				ally_target.ally_state = WorldEnums.AllyState.ALLY
				applied.append({"op": op, "region": String(ally_target.id)})
				ally_changed.emit(ally_target.id, true)
			_:
				applied.append(_apply_simple_effect(eff))

	# 2b. Push-your-luck: roll the card's stated odds. rng_risk is consumed
	# ONLY here - exactly one randf per risk card played.
	var risk_outcome := {}
	var risk_spec: Dictionary = card.get("risk", {})
	if not risk_spec.is_empty():
		var chance := float(risk_spec["chance"])
		var success := rng_risk.randf() < chance
		var branch: Dictionary = risk_spec.get("on_success" if success else "on_failure", {})
		var risk_applied: Array[Dictionary] = []
		for eff: Dictionary in branch.get("effects", []):
			risk_applied.append(_apply_simple_effect(eff))
		var risk_gains := _grant_rewards(branch.get("rewards", {}), 1.0)
		risk_outcome = {"chance": chance, "success": success,
			"effects_applied": risk_applied, "rewards": risk_gains}
		risk_resolved.emit(card_id, success)

	# 3. Grant the card's own rewards.
	var reward_gains := _grant_rewards(card.get("rewards", {}), 1.0)

	# 4. Crisis assignment: the first unanswered crisis matching a card tag.
	var tags: Array = card.get("tags", [])
	var answered_id: StringName = &""
	for crisis in pending_crises:
		if crisis["answered"]:
			continue
		var response: Dictionary = crisis_def(crisis["id"]).get("response", {})
		var hit := false
		for t in response.get("tags_any", []):
			if tags.has(t):
				hit = true
		if hit:
			crisis["answered"] = true
			crisis["answered_by"] = card_id
			crisis["response_gains"] = _grant_rewards(response.get("rewards", {}), 1.0)
			crises_answered_total += 1
			answered_id = crisis["id"]
			crisis_answered.emit(answered_id, card_id)
			break

	# 5. Tag accounting and combo check (fires immediately - combos are juice).
	for t in tags:
		_turn_tags[String(t)] = int(_turn_tags.get(String(t), 0)) + 1
	var fired := _check_combos()

	# 6. A market offer is a single funding decision: playing consumes it.
	market.erase(card_id)

	_turn_actions.append({
		"card": card_id,
		"target": ally_target.id if ally_target != null else &"",
		"cost_money": cost_m,
		"cost_influence": cost_i,
		"cost_happiness": cost_h,
		"rewards": reward_gains,
		"effects_applied": applied,
		"waiver": waiver,
		"risk": risk_outcome,
		"crisis_answered": answered_id,
		"combos": fired,
	})
	card_played.emit(card_id, true)
	_check_unlocks()
	return OK


## Effects legal outside a card context (combos, project completions) plus
## the shared card ops. Returns the applied-entry for the record.
func _apply_simple_effect(eff: Dictionary) -> Dictionary:
	var op := String(eff.get("op", ""))
	match op:
		"sector_progress":
			var sid := StringName(eff["sector"])
			var ss := sector(sid)
			if bool(eff.get("lifts_cap", false)):
				ss.suff_played = true  # lift before adding (same-card order rule)
			var requested := float(eff["amount"])
			var add := minf(ss.cap(), ss.progress + requested) - ss.progress
			ss.progress += add
			return {"op": op, "sector": String(sid), "requested": requested, "applied": add}
		"joint_progress":
			var requested := float(eff["amount"])
			var entry := {"op": op, "requested": requested}
			for sid in WorldEnums.SECTOR_ORDER:  # fixed order; never lifts caps
				var ss := sector(sid)
				var add := minf(ss.cap(), ss.progress + requested) - ss.progress
				ss.progress += add
				entry["applied_" + String(sid)] = add
			return entry
		"happiness", "wellbeing":
			var amount := float(eff["amount"])
			var add := clampf(happiness + amount, 0.0, 100.0) - happiness
			happiness += add
			return {"op": op, "requested": amount, "applied": add, "waived": false}
		"sink_now":
			var amount := float(eff["amount"])
			absorption += amount
			return {"op": op, "requested": amount, "applied": amount}
		"reforest":
			var entry := ReforestEntry.new()
			entry.per_turn = float(eff["per_turn"])
			entry.turns_left = int(eff["turns"])
			reforest_queue.append(entry)
			return {"op": op, "per_turn": entry.per_turn, "turns": entry.turns_left}
		"actor_fund":
			# Buy down the biggest emitter: cheapest tons on Earth, bought abroad.
			var target := _actor_by_rank(true)
			if target.is_empty():
				return {"op": op, "actor": "", "skipped": true}
			var cut := float(eff.get("cut", 0.0))
			var floor_e := float(target["floor"])
			var applied_cut: float = float(target["emissions"]) - maxf(floor_e, float(target["emissions"]) - cut)
			target["emissions"] = float(target["emissions"]) - applied_cut
			var tcut := float(eff.get("trend_cut", 0.0))
			target["trend"] = maxf(0.0, float(target["trend"]) - tcut)
			return {"op": op, "actor": String(target["id"]), "requested": cut,
				"applied": applied_cut, "trend_cut": tcut}
		"actor_treaty":
			# Bend the steepest curve: the treaty targets the fastest-growing bloc.
			var target := _actor_by_rank(false)
			if target.is_empty():
				return {"op": op, "actor": "", "skipped": true}
			var tcut := float(eff.get("trend_cut", 0.0))
			var applied_cut: float = minf(tcut, maxf(0.0, float(target["trend"])))
			target["trend"] = maxf(0.0, float(target["trend"]) - tcut)
			return {"op": op, "actor": String(target["id"]), "trend_cut": applied_cut}
		"adapt":
			var requested := float(eff["amount"])
			var add := minf(float(Tuning.s("ADAPT_MAX")), adapt + requested) - adapt
			adapt += add
			return {"op": op, "requested": requested, "applied": add}
		"ally":
			# Auto-target: project completions strengthen relations with the
			# first neutral region (skipped when the world is fully allied).
			var neutrals := neutral_regions()
			if neutrals.is_empty() or allies >= int(Tuning.s("MAX_ALLIES")):
				return {"op": op, "region": "", "skipped": true}
			var target := neutrals[0]
			allies += 1
			target.ally_state = WorldEnums.AllyState.ALLY
			ally_changed.emit(target.id, true)
			return {"op": op, "region": String(target.id)}
	return {"op": op}


## The diplomacy target: by_emissions picks the biggest cuttable emitter
## (above its floor); otherwise the steepest still-positive trend. Returns {}
## when no actor qualifies. Fixed iteration order keeps ties deterministic.
func _actor_by_rank(by_emissions: bool) -> Dictionary:
	var best: Dictionary = {}
	var best_v := -INF
	for a in world_actors:
		var v: float
		if by_emissions:
			if float(a["emissions"]) <= float(a["floor"]):
				continue
			v = float(a["emissions"])
		else:
			if float(a["trend"]) <= 0.0:
				continue
			v = float(a["trend"])
		if v > best_v:
			best_v = v
			best = a
	return best


## Between-turn advance: every actor's curve climbs by its trend, damped by
## the coalition (each ally absorbs ACTOR_TREND_PER_ALLY of world drift,
## steepest curves first). This is the clock's automatic escalation.
func _advance_actors() -> void:
	var damp := allies * float(Tuning.s("ACTOR_TREND_PER_ALLY"))
	var order := world_actors.duplicate()
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a["trend"]), float(b["trend"])):
			return world_actors.find(a) < world_actors.find(b)
		return float(a["trend"]) > float(b["trend"]))
	for a: Dictionary in order:
		var trend := maxf(0.0, float(a["trend"]))
		var use := minf(damp, trend)
		damp -= use
		a["emissions"] = maxf(float(a["floor"]), float(a["emissions"]) + trend - use)


func _actors_snapshot() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for a in world_actors:
		out.append({"id": String(a["id"]), "emissions": float(a["emissions"]),
			"trend": float(a["trend"])})
	return out


## Apply a rewards dict (money/influence/happiness scaled by mult; knowledge
## flat). Returns the actually-applied gains for records and logs.
func _grant_rewards(rewards: Dictionary, mult: float) -> Dictionary:
	var gains := {}
	if rewards.is_empty():
		return gains
	var m := float(rewards.get("money", 0)) * mult
	if m != 0.0:
		money += m
		gains["money"] = m
	var i := float(rewards.get("influence", 0)) * mult
	if i != 0.0:
		influence += i
		gains["influence"] = i
	var h := float(rewards.get("happiness", 0)) * mult
	if h != 0.0:
		var add := clampf(happiness + h, 0.0, 100.0) - happiness
		happiness += add
		gains["happiness"] = add
	var k := int(rewards.get("knowledge", 0))
	if k != 0:
		kp_earned += k
		gains["knowledge"] = k
	return gains


## Combo check after a card play: every not-yet-fired combo whose required
## tag multiset is covered by this turn's played tags fires immediately.
func _check_combos() -> Array[StringName]:
	var fired: Array[StringName] = []
	for combo in catalog.combos:
		var cid := StringName(String(combo["id"]))
		var already := false
		for f in _turn_combos:
			if StringName(String(f["id"])) == cid:
				already = true
		if already:
			continue
		var needed := {}
		for t in combo["tags_required"]:
			needed[String(t)] = int(needed.get(String(t), 0)) + 1
		var ok := true
		for t in needed:
			if int(_turn_tags.get(String(t), 0)) < int(needed[t]):
				ok = false
		if not ok:
			continue
		# Fire: chain multiplier uses the chain BEFORE this combo.
		var mult := SocietyCalc.combo_mult(combo_chain)
		combo_chain += 1
		combos_total += 1
		var applied: Array[Dictionary] = []
		for eff: Dictionary in combo.get("effects", []):
			applied.append(_apply_simple_effect(eff))
		# Knowledge is an insight: earned the FIRST time a combo is discovered
		# this run, never farmed by repetition.
		var rewards: Dictionary = combo.get("rewards", {})
		if int(combos_fired_run.get(String(cid), 0)) > 0 and rewards.has("knowledge"):
			rewards = rewards.duplicate()
			rewards.erase("knowledge")
		combos_fired_run[String(cid)] = int(combos_fired_run.get(String(cid), 0)) + 1
		var gains := _grant_rewards(rewards, mult)
		_turn_combos.append({
			"id": String(cid), "chain": combo_chain, "mult": mult,
			"rewards": gains, "effects_applied": applied,
		})
		fired.append(cid)
		combo_triggered.emit(cid, combo_chain, mult)
	return fired


## Deck growth: unlock every locked card whose condition the run now meets.
func _check_unlocks() -> void:
	for card in catalog.cards:
		if not card.has("unlock"):
			continue
		var cid := StringName(String(card["id"]))
		if unlocked_card_ids.has(cid):
			continue
		var cond: Dictionary = card["unlock"]
		var met := false
		match String(cond.get("kind", "")):
			"crises_answered":
				met = crises_answered_total >= int(cond.get("count", 1))
			"combos":
				met = combos_total >= int(cond.get("count", 1))
			"allies":
				met = allies >= int(cond.get("count", 1))
			"projects_completed":
				met = projects_completed >= int(cond.get("count", 1))
			"sector_progress":
				met = sector(StringName(String(cond["sector"]))).progress >= float(cond.get("gte", 0))
		if met:
			unlocked_card_ids.append(cid)
			_turn_unlocks.append(cid)
			card_unlocked.emit(cid)


# --------------------------------------------------- long-term projects ---

func can_start_project_reason(project_id: StringName) -> StringName:
	if phase == Phase.ENDED:
		return &"ended"
	if phase != Phase.AWAIT_ACTION:
		return &"resolving"
	var p := catalog.project(project_id)
	if p.is_empty():
		return &"unknown_project"
	if project_history.has(String(project_id)):
		return &"already_done"
	for ap in active_projects:
		if ap.id == project_id:
			return &"already_active"
	if active_projects.size() >= int(Tuning.s("PROJECT_MAX_ACTIVE")):
		return &"max_active"
	if float(p.get("upkeep_money", 0)) > money:
		return &"no_money"
	if float(p.get("upkeep_influence", 0)) > influence:
		return &"no_influence"
	return &"ok"


## Launch a project: pays the first turn's upkeep immediately; the remaining
## turns charge at each turn start until completion.
func start_project(project_id: StringName) -> Error:
	if can_start_project_reason(project_id) != &"ok":
		return ERR_UNAVAILABLE
	var p := catalog.project(project_id)
	var cost_m := float(p.get("upkeep_money", 0))
	var cost_i := float(p.get("upkeep_influence", 0))
	money -= cost_m
	influence -= cost_i
	var ps := ProjectState.new()
	ps.id = project_id
	ps.turns_left = int(p.get("turns", 3)) - 1
	active_projects.append(ps)
	_turn_project_events.append({
		"id": String(project_id), "event": "launched",
		"cost_money": cost_m, "cost_influence": cost_i, "turns_left": ps.turns_left,
	})
	project_changed.emit(project_id, &"launched")
	return OK


## Abandon an active project: the pledged partners remember (penalty applies).
func abandon_project(project_id: StringName) -> Error:
	if phase != Phase.AWAIT_ACTION:
		return ERR_UNAVAILABLE
	for i in active_projects.size():
		if active_projects[i].id == project_id:
			active_projects.remove_at(i)
			var penalty := _apply_project_penalty(project_id)
			project_history[String(project_id)] = "abandoned"
			_turn_project_events.append({
				"id": String(project_id), "event": "abandoned",
				"penalty": penalty,
			})
			project_changed.emit(project_id, &"abandoned")
			return OK
	return ERR_DOES_NOT_EXIST


func _apply_project_penalty(project_id: StringName) -> Dictionary:
	var p := catalog.project(project_id)
	var penalty: Dictionary = p.get("abandon_penalty", {})
	var h := float(penalty.get("happiness", 0))
	var i := float(penalty.get("influence", 0))
	happiness = clampf(happiness - h, 0.0, 100.0)
	influence = maxf(0.0, influence - i)
	return {"happiness": h, "influence": i}


## Turn-start upkeep: pay or fail, complete on the last paid turn.
func _charge_projects() -> void:
	var still_active: Array[ProjectState] = []
	for ps in active_projects:
		var p := catalog.project(ps.id)
		var cost_m := float(p.get("upkeep_money", 0))
		var cost_i := float(p.get("upkeep_influence", 0))
		if cost_m > money or cost_i > influence:
			var penalty := _apply_project_penalty(ps.id)
			project_history[String(ps.id)] = "failed"
			_turn_project_events.append({
				"id": String(ps.id), "event": "failed", "penalty": penalty,
			})
			project_changed.emit(ps.id, &"failed")
			continue
		money -= cost_m
		influence -= cost_i
		ps.turns_left -= 1
		if ps.turns_left <= 0:
			var completion: Dictionary = p.get("completion", {})
			var applied: Array[Dictionary] = []
			for eff: Dictionary in completion.get("effects", []):
				applied.append(_apply_simple_effect(eff))
			for key in completion.get("passive", {}):
				passives[String(key)] = float(passives.get(String(key), 0.0)) \
						+ float(completion["passive"][key])
			projects_completed += 1
			project_history[String(ps.id)] = "completed"
			_turn_project_events.append({
				"id": String(ps.id), "event": "completed",
				"cost_money": cost_m, "cost_influence": cost_i,
				"effects_applied": applied,
			})
			project_changed.emit(ps.id, &"completed")
			_check_unlocks()
		else:
			still_active.append(ps)
			_turn_project_events.append({
				"id": String(ps.id), "event": "charged",
				"cost_money": cost_m, "cost_influence": cost_i,
				"turns_left": ps.turns_left,
			})
	active_projects = still_active


# ------------------------------------------- step 1 + crisis draw + 3-8 ---

func _begin_year() -> void:
	_turn_actions = []
	_turn_tags = {}
	_turn_combos = []
	_turn_project_events = []
	_turn_unlocks = []
	# Step 1: income (strongest happiness penalty only, archetype-scaled) +
	# completion passives.
	var inc := SocietyCalc.income(happiness, allies)
	var inc_money := float(inc["amount"]) * float(archetype.get("income_mult", 1.0)) \
			+ float(passives.get("income_money", 0.0))
	money += inc_money
	var inf_gain := SocietyCalc.influence_income(allies, media) \
			+ float(archetype.get("influence_income_bonus", 0.0)) \
			+ float(passives.get("income_influence", 0.0))
	influence += inf_gain
	if passives.get("happiness_per_turn", 0.0) != 0.0:
		happiness = clampf(happiness + float(passives["happiness_per_turn"]), 0.0, 100.0)
	if passives.get("absorption_per_turn", 0.0) != 0.0:
		absorption += float(passives["absorption_per_turn"])
	var rebuild := false
	var rebuild_amount := 0.0
	if flood_rebuild:
		var ss := sector(&"tra")
		rebuild_amount = minf(ss.cap(), ss.progress + float(Tuning.s("FLOOD_REBUILD_TRA"))) - ss.progress
		ss.progress += rebuild_amount
		flood_rebuild = false
		rebuild = true
	_pending_income = {
		"money": inc_money,
		"influence": inf_gain,
		"penalty": StringName(inc["penalty"]),
		"rebuild": rebuild,
		"rebuild_amount": rebuild_amount,
	}
	# Step 1b: project upkeep (pay, fail, or complete).
	_charge_projects()
	# Step 1c: draw this turn's crises (the ONLY consumer of rng_events;
	# fixed order: pick then target, three times), then apply on-draw spikes.
	_draw_crises()
	_apply_on_draw_effects()
	# Step 1d: deal the project market (the ONLY consumer of rng_market),
	# then let qualifying crises inject their bonus cards.
	_deal_market()
	phase = Phase.AWAIT_ACTION
	year_started.emit(year)


func _draw_crises() -> void:
	pending_crises = []
	var pool := catalog.drawable_events()
	var band := ClimateCalc.band(temp)
	var used := {}
	for n in int(Tuning.s("CRISES_PER_TURN")):
		var weights: Array[float] = []
		var total := 0.0
		for e in pool:
			var w := 0.0
			if not used.has(String(e["id"])):
				w = SocietyCalc.crisis_weight(e, band, happiness, media)
			weights.append(w)
			total += w
		var roll := rng_events.randf() * total  # always consume the draw
		var pick: Dictionary = {}
		var acc := 0.0
		for j in pool.size():
			acc += weights[j]
			if pick.is_empty() and weights[j] > 0.0 and roll < acc:
				pick = pool[j]
		if pick.is_empty():  # numeric edge: last eligible entry
			for j in range(pool.size() - 1, -1, -1):
				if weights[j] > 0.0:
					pick = pool[j]
					break
		if pick.is_empty():
			continue  # degenerate data (pool smaller than draws)
		used[String(pick["id"])] = true
		var target := _draw_event_target(pick)  # consumes exactly one randf
		pending_crises.append({
			"id": StringName(String(pick["id"])),
			"kind": String(pick.get("kind", "crisis")),
			"region_id": target.id if target != null else &"",
			"answered": false,
			"answered_by": &"",
		})


## On-draw spikes (a record heat wave bakes in extra emissions the moment it
## lands). Answering the crisis this turn dissipates the spike before the
## ledger is read; ignoring it makes the spike permanent.
func _apply_on_draw_effects() -> void:
	for crisis in pending_crises:
		var on_draw: Dictionary = crisis_def(crisis["id"]).get("on_draw", {})
		var e := float(on_draw.get("e_extra", 0.0))
		if e != 0.0:
			e_extra += e
			crisis["on_draw_e"] = e


## Deal MARKET_SIZE offers from the available pool: weighted (card
## market_weight x the archetype's tag lean), without replacement, fixed pool
## order; consumes exactly MARKET_SIZE randf draws. Then the guarantee rule
## and event bonus injections (both RNG-free).
func _deal_market() -> void:
	market = []
	market_bonus = []
	var pool := available_cards()
	var deal := mini(int(Tuning.s("MARKET_SIZE")), pool.size())
	var arch_weights: Dictionary = archetype.get("market_weights", {})
	var picked: Dictionary = {}
	for n in deal:
		var weights: Array[float] = []
		var total := 0.0
		for c in pool:
			var w := 0.0
			if not picked.has(String(c["id"])):
				w = float(c.get("market_weight", 1.0))
				var lean := 1.0
				for tag in c.get("tags", []):
					lean = maxf(lean, float(arch_weights.get(String(tag), 1.0)))
				w *= lean
			weights.append(w)
			total += w
		var roll := rng_market.randf() * total  # always consume the draw
		var pick: Dictionary = {}
		var acc := 0.0
		for j in pool.size():
			acc += weights[j]
			if pick.is_empty() and weights[j] > 0.0 and roll < acc:
				pick = pool[j]
		if pick.is_empty():  # numeric edge: last eligible entry
			for j in range(pool.size() - 1, -1, -1):
				if weights[j] > 0.0:
					pick = pool[j]
					break
		if pick.is_empty():
			break
		picked[String(pick["id"])] = true
		market.append(StringName(String(pick["id"])))
	_ensure_answer_offer(pool)
	_inject_bonus_cards()
	_turn_market_offered = market.duplicate()


## Guarantee rule: if no offer carries any response tag of this turn's
## events, swap the last slot for the cheapest answering card (catalog order
## breaks ties). Keeps every turn interactive without extra randomness.
func _ensure_answer_offer(pool: Array[Dictionary]) -> void:
	if market.is_empty():
		return
	var wanted := {}
	for crisis in pending_crises:
		for tag in crisis_def(crisis["id"]).get("response", {}).get("tags_any", []):
			wanted[String(tag)] = true
	if wanted.is_empty():
		return
	for id in market:
		for tag in catalog.card(id).get("tags", []):
			if wanted.has(String(tag)):
				return  # already answerable
	var best: Dictionary = {}
	for c in pool:
		if market.has(StringName(String(c["id"]))):
			continue
		var hits := false
		for tag in c.get("tags", []):
			if wanted.has(String(tag)):
				hits = true
		if hits and (best.is_empty() or float(c.get("cost_money", 0)) < float(best.get("cost_money", 0))):
			best = c
	if not best.is_empty():
		market[market.size() - 1] = StringName(String(best["id"]))


## Event -> card links (design doc: conditional bonus cards): a drawn event
## adds its bonus card to the market when the resource gate is met at draw
## time. Data-driven via events.json "bonus_card".
func _inject_bonus_cards() -> void:
	for crisis in pending_crises:
		var spec: Dictionary = crisis_def(crisis["id"]).get("bonus_card", {})
		if spec.is_empty():
			continue
		var requires: Dictionary = spec.get("requires", {})
		if happiness < float(requires.get("happiness_gte", -1e30)):
			continue
		if money < float(requires.get("money_gte", -1e30)):
			continue
		if influence < float(requires.get("influence_gte", -1e30)):
			continue
		var cid := StringName(String(spec["card"]))
		if catalog.card(cid).is_empty() or market.has(cid):
			continue
		market.append(cid)
		market_bonus.append(cid)


## Resolve steps 3-8 for the current turn. Playing zero cards is legal and
## is recorded as an explicit pass.
func resolve_year() -> TurnRecord:
	if phase == Phase.ENDED:
		return records.back() if not records.is_empty() else null
	phase = Phase.RESOLVING

	var rec := TurnRecord.new()
	rec.year = year
	rec.turn = turn_index()
	rec.income_money = float(_pending_income.get("money", 0.0))
	rec.income_influence = float(_pending_income.get("influence", 0.0))
	rec.income_penalty = _pending_income.get("penalty", &"none")
	rec.rebuild_bonus_applied = bool(_pending_income.get("rebuild", false))
	rec.rebuild_bonus_amount = float(_pending_income.get("rebuild_amount", 0.0))
	rec.project_events = _turn_project_events
	rec.market_offered = _turn_market_offered
	rec.market_bonus = market_bonus.duplicate()
	rec.actions = _turn_actions
	rec.combos_fired = _turn_combos

	# --- Step 3: carbon ledger (clear answered spikes -> mature -> stress ->
	# floor -> E city + E world -> N) ---
	for crisis in pending_crises:
		if crisis["answered"] and crisis.get("on_draw_e", 0.0) != 0.0:
			e_extra -= float(crisis["on_draw_e"])  # the spike dissipates
	var matured := 0.0
	for entry in reforest_queue:
		absorption += entry.per_turn
		matured += entry.per_turn
		entry.turns_left -= 1
	reforest_queue = reforest_queue.filter(func(e: ReforestEntry) -> bool: return e.turns_left > 0)
	var t_prev := temp
	var stress := ClimateCalc.sink_stress(t_prev)  # reads LAST turn's temperature
	absorption = maxf(ClimateCalc.a_floor(), absorption - stress)
	var e_city := gross_emissions()
	var e_world := world_emissions()
	var e := e_city + e_world
	var n := ClimateCalc.net(e, absorption)
	rec.sink_matured = matured
	rec.sink_stress = stress
	rec.emissions = e
	rec.emissions_city = e_city
	rec.emissions_world = e_world
	rec.absorption = absorption
	rec.net = n

	# --- Step 4: warming (the clock ticks) ---
	var dt := ClimateCalc.warming_delta(n)
	temp = ClimateCalc.apply_warming(temp, n)
	rec.warming_delta = dt
	rec.temp = temp
	rec.clock_pct = ClimateCalc.clock_pct(temp)
	var band_prev := ClimateCalc.band(t_prev)
	var band_new := ClimateCalc.band(temp)
	rec.band_prev = band_prev
	rec.band = band_new
	if band_new != band_prev:
		warming_band_changed.emit(band_new)

	# --- Step 5: happiness drift (reads band of T_new) ---
	var drift := SocietyCalc.happiness_drift(avg_progress(), band_new)
	happiness = clampf(happiness + float(drift["co_benefit"]) - float(drift["stress"]), 0.0, 100.0)
	rec.co_benefit = float(drift["co_benefit"])
	rec.overshoot_stress = float(drift["stress"])
	rec.happiness = happiness

	# --- Step 6: crisis resolution (no RNG here; draw happened at year start).
	# Answered crises are contained; unanswered crises strike at full force
	# (scaled by resilience where the catalog says so).
	var mult := SocietyCalc.damage_mult(happiness, adapt)  # frozen at step-6 entry
	for crisis in pending_crises:
		if not crisis["answered"] and crisis["kind"] == "crisis":
			_apply_crisis_hit(crisis, mult)
		rec.crises.append(crisis)
	rec.combo_chain = combo_chain
	if _turn_combos.is_empty():
		combo_chain = maxi(0, combo_chain - 1)
		rec.combo_chain = combo_chain
	rec.cards_unlocked = _turn_unlocks

	# --- Step 6b: summit (COP) evaluation - the mid-run sub-objective.
	# The target was announced turns in advance; it reads this turn's net.
	var summit := catalog.summit_for_turn(rec.turn)
	if not summit.is_empty():
		var goal: Dictionary = summit.get("goal", {})
		var value := n
		if String(goal.get("metric", "net")) == "clock_pct":
			value = rec.clock_pct
		var met := value <= float(goal.get("lte", 0.0))
		var sid := String(summit["id"])
		summit_results[sid] = "met" if met else "missed"
		var outcome := {"id": sid, "name": String(summit.get("name", sid)),
			"met": met, "value": value, "target": float(goal.get("lte", 0.0))}
		if met:
			outcome["gains"] = _grant_rewards(summit.get("reward", {}), 1.0)
		else:
			var penalty: Dictionary = summit.get("penalty", {})
			influence = maxf(0.0, influence - float(penalty.get("influence", 0)))
			happiness = clampf(happiness - float(penalty.get("happiness", 0)), 0.0, 100.0)
			money = maxf(0.0, money - float(penalty.get("money", 0)))
			outcome["penalty"] = penalty
		rec.summit = outcome
		summit_resolved.emit(StringName(sid), met)

	# --- Step 7: one-time feedback loops (post-crisis state, fixed order) ---
	for fb in catalog.feedback_events():
		var fb_id := String(fb["id"])
		if feedback_years.has(fb_id):
			continue
		var trigger: Dictionary = fb.get("trigger", {})
		var fired := false
		if trigger.has("temp_gte") and temp >= float(trigger["temp_gte"]):
			fired = true
		if trigger.has("fires_gte") and fires >= int(trigger["fires_gte"]):
			fired = true
		if fired:
			var effect: Dictionary = fb.get("effect", {})
			if effect.has("e_extra"):
				e_extra += float(effect["e_extra"])
			if effect.has("absorption"):
				absorption = maxf(ClimateCalc.a_floor(), absorption + float(effect["absorption"]))
			feedback_years[fb_id] = year
			rec.feedbacks.append(StringName(fb_id))
			event_struck.emit(StringName(fb_id), &"", &"")

	# --- Step 7b: the world's blocs advance their curves between turns (the
	# clock's automatic escalation, damped by the coalition's allies).
	var status := EndState.evaluate(year, temp, n, happiness)
	if status == EndState.RunStatus.RUNNING:
		_advance_actors()
	rec.actors = _actors_snapshot()

	# --- Step 8: end-of-turn check ---
	rec.end_status = EndState.status_string(status)
	rec.money = money
	rec.influence = influence
	rec.allies = allies
	rec.resilience = resilience()
	rec.kp_earned = kp_earned
	if n <= 0.0 and curve_bent_year == 0:
		curve_bent_year = year
		curve_bent.emit(year)

	if status != EndState.RunStatus.RUNNING:
		var progs: Array = []
		for s in WorldEnums.SECTOR_ORDER:
			progs.append(sector(s).progress)
		rec.kp_awarded = EndState.knowledge_points(status, year, progs, allies) + kp_earned

	rec.log_lines = _build_log_lines(rec)
	records.append(rec)

	if status == EndState.RunStatus.RUNNING:
		year_advanced.emit(rec)
		year += int(Tuning.c("YEARS_PER_TURN"))
		_begin_year()
	else:
		phase = Phase.ENDED
		run_ended.emit(rec.end_status, rec.kp_awarded)
	return rec


## Weighted flavor-target draw; always consumes exactly one randf on a hit.
func _draw_event_target(ev: Dictionary) -> RegionData:
	var target_spec: Dictionary = ev.get("target", {})
	var tags_any: Array = target_spec.get("tags_any", [])
	var boosts: Dictionary = target_spec.get("weight_boost", {})
	var eligible: Array[RegionData] = []
	var weights: Array[float] = []
	var total := 0.0
	for r in world:
		var ok := tags_any.is_empty()
		for tag in tags_any:
			if r.has_tag(StringName(String(tag))):
				ok = true
		if not ok:
			continue
		var w := 1.0
		for key in boosts:
			if String(key) == "ally":
				if r.ally_state == WorldEnums.AllyState.ALLY:
					w *= float(boosts[key])
			elif r.has_tag(StringName(String(key))):
				w *= float(boosts[key])
		eligible.append(r)
		weights.append(w)
		total += w
	var roll := rng_events.randf() * total  # consume the draw even if degenerate
	if eligible.is_empty():
		return null
	var acc := 0.0
	for i in eligible.size():
		acc += weights[i]
		if roll < acc:
			return eligible[i]
	return eligible.back()


## An unanswered crisis strikes: damages, ally loss, counters, scar and the
## opportunity rider (crisis doors only open when the crisis actually hits).
func _apply_crisis_hit(crisis: Dictionary, mult: float) -> void:
	var ev := crisis_def(crisis["id"])
	var target := region_by_id(crisis["region_id"])
	var scaled := bool(ev.get("scaled_by_resilience", false))
	var used_mult := mult if scaled else 1.0
	var damages: Dictionary = ev.get("damages", {})
	var applied_damages: Dictionary = {}
	for key in DAMAGE_KEYS:
		if not damages.has(key):
			continue
		var dmg := float(damages[key]) * used_mult
		match key:
			"money":
				money = maxf(0.0, money - dmg)
			"happiness":
				happiness = clampf(happiness - dmg, 0.0, 100.0)
			"absorption":
				absorption = maxf(ClimateCalc.a_floor(), absorption - dmg)
			"influence":
				influence = maxf(0.0, influence - dmg)
		applied_damages[key] = dmg

	# Ally loss: the targeted ally if any, else the highest-affinity ally.
	var ally_lost: StringName = &""
	if damages.has("ally_lost") and allies > 0:
		var victim: RegionData = null
		if target != null and target.ally_state == WorldEnums.AllyState.ALLY:
			victim = target
		else:
			for r in ally_regions():
				if victim == null or r.alliance_affinity > victim.alliance_affinity:
					victim = r
		if victim != null:
			victim.ally_state = WorldEnums.AllyState.NEUTRAL
			allies -= 1
			ally_lost = victim.id
			ally_changed.emit(victim.id, false)

	# Counters, scars, opportunity rider.
	var counters: Dictionary = ev.get("counters", {})
	fires += int(counters.get("fires", 0))
	if ev.has("scar") and target != null:
		target.scars.append(StringName("%s_%d" % [String(ev["scar"]), year]))
	var opp_flag: StringName = &""
	var opp: Variant = ev.get("opportunity")
	if opp is Dictionary:
		opp_flag = StringName(String(opp["set_flag"]))
		match opp_flag:
			&"window": window = true
			&"fire_discount": fire_discount = true
			&"flood_rebuild": flood_rebuild = true

	crisis["mult"] = used_mult
	crisis["damages"] = applied_damages
	crisis["ally_lost"] = ally_lost
	crisis["opportunity"] = opp_flag
	event_struck.emit(crisis["id"], crisis["region_id"], opp_flag)


# ----------------------------------------------------------- log building ---

func _build_log_lines(rec: TurnRecord) -> PackedStringArray:
	var lines: PackedStringArray = []
	# Step 1: income.
	var penalty_note := ""
	if rec.income_penalty != &"none":
		penalty_note = LogFormatter.render("system", "penalty_" + String(rec.income_penalty))
	lines.append(LogFormatter.render("system", "income", {
		"money": rec.income_money, "influence": rec.income_influence, "penalty_note": penalty_note,
	}))
	if rec.rebuild_bonus_applied:
		lines.append(LogFormatter.render("system", "rebuild_better_tra", {"amount": rec.rebuild_bonus_amount}))
	# Step 1b: project events, in occurrence order.
	for pe in rec.project_events:
		lines.append(_project_line(pe))
	# Step 1c: the turn's event draw, on-draw spikes and bonus-card windows.
	if not rec.crises.is_empty():
		var names: PackedStringArray = []
		for crisis in rec.crises:
			var region := region_by_id(crisis["region_id"])
			var ev := crisis_def(crisis["id"])
			var label := String(ev.get("name", crisis["id"]))
			if region != null:
				label += " (%s)" % region.display_name
			names.append(label)
		lines.append(LogFormatter.render("system", "crises_faced", {"list": ", ".join(names)}))
	for crisis in rec.crises:
		if float(crisis.get("on_draw_e", 0.0)) != 0.0:
			var ev := crisis_def(crisis["id"])
			var key := "on_draw_cleared" if crisis["answered"] else "on_draw_hit"
			lines.append(LogFormatter.render("system", key, {
				"name": String(ev.get("name", crisis["id"])),
				"e_extra": float(crisis["on_draw_e"]),
			}))
	for cid in rec.market_bonus:
		lines.append(LogFormatter.render("system", "bonus_card", {
			"name": catalog.card(cid).get("name", String(cid)),
		}))
	# Step 2: actions (plays, risk rolls, answers, combos - in play order).
	if rec.actions.is_empty():
		lines.append(LogFormatter.render("system", "pass"))
	for action in rec.actions:
		var card := catalog.card(action["card"])
		var cost_note := "-%s funds" % LogFormatter.fmt(action["cost_money"])
		if float(action["cost_influence"]) > 0.0:
			cost_note += ", -%s influence" % LogFormatter.fmt(action["cost_influence"])
		if float(action["cost_happiness"]) > 0.0:
			cost_note += ", -%s happiness" % LogFormatter.fmt(action["cost_happiness"])
		lines.append(LogFormatter.render("cards", "enact", {
			"name": card.get("name", String(action["card"])), "cost_note": cost_note,
		}))
		for eff in action["effects_applied"]:
			lines.append("  " + _effect_line(eff))
		var risk: Dictionary = action.get("risk", {})
		if not risk.is_empty():
			var risk_key := "risk_success" if risk["success"] else "risk_failure"
			lines.append("  " + LogFormatter.render("system", risk_key, {
				"name": card.get("name", String(action["card"])),
				"chance": roundi(float(risk["chance"]) * 100.0),
				"gains": _gains_note(risk.get("rewards", {})),
			}))
			for eff in risk.get("effects_applied", []):
				lines.append("  " + _effect_line(eff))
		if not (action["rewards"] as Dictionary).is_empty():
			lines.append("  " + LogFormatter.render("system", "rewards", {
				"gains": _gains_note(action["rewards"]),
			}))
		if action["crisis_answered"] != &"":
			lines.append("  " + crisis_answered_line(action["crisis_answered"]))
		for combo_id in action["combos"]:
			for fired in rec.combos_fired:
				if String(fired["id"]) == String(combo_id):
					lines.append(combo_line(fired))
	# Steps 3-4: ledger (city + world) and the climate clock.
	if rec.sink_matured > 0.0:
		lines.append(LogFormatter.render("system", "sink_matured", {"amount": rec.sink_matured}))
	lines.append(LogFormatter.render("system", "ledger", {
		"ec": rec.emissions_city, "ew": rec.emissions_world,
		"a": rec.absorption, "n": _signed(rec.net),
	}))
	lines.append(LogFormatter.render("system", "warming", {
		"clock": "%.0f" % rec.clock_pct, "t": "+%.2f" % rec.temp,
		"dt": _signed_precise(rec.warming_delta),
	}))
	if rec.net <= 0.0:
		lines.append(LogFormatter.render("system", "curve_bent"))
	if rec.band != rec.band_prev:
		var key := "band_up_%d" % rec.band if rec.band > rec.band_prev else "band_down_%d" % rec.band
		lines.append(LogFormatter.render("system", key))
	# Step 5: drift.
	lines.append(LogFormatter.render("system", "drift", {
		"h": rec.happiness, "co": rec.co_benefit, "stress": rec.overshoot_stress,
	}))
	# Step 6: unanswered crises strike; missed opportunities pass by.
	for crisis in rec.crises:
		if crisis["answered"]:
			continue
		if crisis["kind"] == "opportunity":
			lines.append(LogFormatter.render("events", String(crisis["id"]) + "_missed"))
			continue
		lines.append(_crisis_hit_line(crisis))
		if crisis.get("ally_lost", &"") != &"":
			var lost := region_by_id(crisis["ally_lost"])
			lines.append(LogFormatter.render("system", "ally_lost", {
				"region": lost.display_name if lost != null else String(crisis["ally_lost"]),
			}))
		if crisis.get("opportunity", &"") != &"":
			lines.append(LogFormatter.render("events", String(crisis["id"]) + "_opp"))
	# Step 6b: the summit verdict.
	if not rec.summit.is_empty():
		if bool(rec.summit["met"]):
			lines.append(LogFormatter.render("system", "summit_met", {
				"name": rec.summit["name"], "value": _signed(float(rec.summit["value"])),
				"target": float(rec.summit["target"]),
				"gains": LogFormatter.render("system", "rewards", {
					"gains": _gains_note(rec.summit.get("gains", {}))}),
			}))
		else:
			var penalty: Dictionary = rec.summit.get("penalty", {})
			var notes: PackedStringArray = []
			for key in ["influence", "happiness", "money"]:
				if float(penalty.get(key, 0)) > 0.0:
					notes.append("-%s %s" % [LogFormatter.fmt(penalty[key]), key])
			lines.append(LogFormatter.render("system", "summit_missed", {
				"name": rec.summit["name"], "value": _signed(float(rec.summit["value"])),
				"target": float(rec.summit["target"]), "penalty_note": ", ".join(notes),
			}))
	# Deck growth.
	for cid in rec.cards_unlocked:
		lines.append(LogFormatter.render("system", "card_unlocked", {
			"name": catalog.card(cid).get("name", String(cid)),
		}))
	# Step 7: feedbacks, then the world's between-turn drift.
	for fb in rec.feedbacks:
		lines.append(LogFormatter.render("events", String(fb) + "_hit"))
	if rec.end_status == &"RUNNING":
		var trend_total := 0.0
		for a in rec.actors:
			trend_total += maxf(0.0, float(a["trend"]))
		lines.append(LogFormatter.render("system", "world_drift", {
			"we": rec.emissions_world, "trend": trend_total,
		}))
	# Step 8: terminal.
	if rec.end_status != &"RUNNING":
		lines.append(LogFormatter.render("endings", String(rec.end_status)))
		lines.append(LogFormatter.render("system", "run_end_kp", {"kp": rec.kp_awarded}))
	return lines


func _project_line(pe: Dictionary) -> String:
	var p := catalog.project(StringName(String(pe["id"])))
	var pname := String(p.get("name", pe["id"]))
	match String(pe["event"]):
		"launched":
			var upkeep := "-%s funds" % LogFormatter.fmt(pe.get("cost_money", 0.0))
			if float(pe.get("cost_influence", 0.0)) > 0.0:
				upkeep += ", -%s influence" % LogFormatter.fmt(pe.get("cost_influence", 0.0))
			return LogFormatter.render("system", "project_launched", {
				"name": pname, "upkeep_note": upkeep, "turns": int(p.get("turns", 3)),
			})
		"charged":
			var cost := "-%s funds" % LogFormatter.fmt(pe.get("cost_money", 0.0))
			if float(pe.get("cost_influence", 0.0)) > 0.0:
				cost += ", -%s influence" % LogFormatter.fmt(pe.get("cost_influence", 0.0))
			return LogFormatter.render("system", "project_charged", {
				"name": pname, "cost_note": cost, "turns_left": int(pe.get("turns_left", 0)),
			})
		"completed":
			var payoffs: PackedStringArray = []
			for eff in pe.get("effects_applied", []):
				payoffs.append(_effect_line(eff))
			var passive: Dictionary = p.get("completion", {}).get("passive", {})
			for key in passive:
				payoffs.append("%s +%s" % [String(key).replace("_", " "), LogFormatter.fmt(passive[key])])
			return LogFormatter.render("system", "project_completed", {
				"name": pname, "payoff_note": "; ".join(payoffs),
			})
		"failed", "abandoned":
			var penalty: Dictionary = pe.get("penalty", {})
			var notes: PackedStringArray = []
			if float(penalty.get("happiness", 0)) > 0.0:
				notes.append("-%s happiness" % LogFormatter.fmt(penalty["happiness"]))
			if float(penalty.get("influence", 0)) > 0.0:
				notes.append("-%s influence" % LogFormatter.fmt(penalty["influence"]))
			return LogFormatter.render("system", "project_" + String(pe["event"]), {
				"name": pname, "penalty_note": ", ".join(notes),
			})
	return String(pe["event"])


func combo_line(fired: Dictionary) -> String:
	var combo_name := ""
	for combo in catalog.combos:
		if String(combo["id"]) == String(fired["id"]):
			combo_name = String(combo["name"])
	var gains := _gains_note(fired["rewards"])
	for eff in fired.get("effects_applied", []):
		gains += ("; " if not gains.is_empty() else "") + _effect_line(eff)
	return LogFormatter.render("system", "combo", {
		"n": int(fired["chain"]), "name": combo_name, "gains": gains,
	})


func crisis_answered_line(crisis_id: StringName) -> String:
	for crisis in pending_crises:
		if crisis["id"] == crisis_id:
			var region := region_by_id(crisis["region_id"])
			var key := String(crisis_id) + ("_seized" if crisis["kind"] == "opportunity" else "_answered")
			return LogFormatter.render("events", key, {
				"region": region.display_name if region != null else "the world",
				"reward_note": LogFormatter.render("system", "rewards", {
					"gains": _gains_note(crisis.get("response_gains", {})),
				}),
			})
	return ""


func _gains_note(gains: Dictionary) -> String:
	var parts: PackedStringArray = []
	if gains.get("money", 0.0):
		parts.append("+%s funds" % LogFormatter.fmt(gains["money"]))
	if gains.get("influence", 0.0):
		parts.append("+%s influence" % LogFormatter.fmt(gains["influence"]))
	if gains.get("happiness", 0.0):
		parts.append("+%s happiness" % LogFormatter.fmt(gains["happiness"]))
	if gains.get("knowledge", 0):
		parts.append("+%s knowledge" % LogFormatter.fmt(gains["knowledge"]))
	return ", ".join(parts)


func _effect_line(eff: Dictionary) -> String:
	var op := String(eff.get("op", ""))
	match op:
		"sector_progress":
			var cap_note := ""
			if float(eff["applied"]) < float(eff["requested"]):
				cap_note = " (requested +%s, at cap: sufficiency needed)" % LogFormatter.fmt(eff["requested"])
			return LogFormatter.render("ops", op, {
				"sector": WorldEnums.SECTOR_NAMES[StringName(eff["sector"])],
				"applied": eff["applied"], "cap_note": cap_note,
			})
		"joint_progress":
			return LogFormatter.render("ops", op, {
				"ind": eff["applied_ind"], "tra": eff["applied_tra"], "agr": eff["applied_agr"],
			})
		"happiness", "wellbeing":
			var waive_note := ""
			if eff.get("waived", false):
				waive_note = " (waived)"
			if op == "wellbeing":
				return LogFormatter.render("ops", op, {"amount": eff["applied"]})
			return LogFormatter.render("ops", op, {
				"amount": _signed(float(eff["requested"])), "waive_note": waive_note,
			})
		"sink_now":
			return LogFormatter.render("ops", op, {"amount": eff["applied"]})
		"reforest":
			return LogFormatter.render("ops", op, {"per_turn": eff["per_turn"], "turns": eff["turns"]})
		"adapt":
			return LogFormatter.render("ops", op, {"amount": eff["applied"]})
		"actor_fund", "actor_treaty":
			if eff.get("skipped", false):
				return "No bloc left to move."
			var actor_name := String(eff.get("actor", ""))
			for a in world_actors:
				if String(a["id"]) == actor_name:
					actor_name = String(a["name"])
			return LogFormatter.render("ops", op, {
				"actor": actor_name, "applied": eff.get("applied", 0.0),
				"trend_cut": eff.get("trend_cut", 0.0),
			})
		"media":
			return LogFormatter.render("ops", op)
		"ally":
			if eff.get("skipped", false):
				return "The coalition is already complete."
			var r := region_by_id(StringName(String(eff.get("region", ""))))
			return LogFormatter.render("ops", op, {
				"region": r.display_name if r != null else String(eff.get("region", "")),
			})
	return op


func _crisis_hit_line(crisis: Dictionary) -> String:
	var region := region_by_id(crisis["region_id"])
	var fields := {
		"region": region.display_name if region != null else "the world",
		"fires": fires,
		"ally_note": "",
		"resilience_note": "",
	}
	var damages: Dictionary = crisis.get("damages", {})
	for key in damages:
		fields[key] = damages[key]
	if float(crisis.get("mult", 1.0)) < 1.0:
		fields["resilience_note"] = LogFormatter.render("events", "resilience_note")
	if crisis.get("ally_lost", &"") != &"":
		fields["ally_note"] = ", an ally wavers"
	return LogFormatter.render("events", String(crisis["id"]) + "_hit", fields)


static func _signed(v: float) -> String:
	return ("+" + LogFormatter.fmt(v)) if v >= 0.0 else LogFormatter.fmt(v)


static func _signed_precise(v: float) -> String:
	return ("+%.3f" % v) if v >= 0.0 else ("%.3f" % v)
