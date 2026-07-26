class_name RunState
extends RefCounted
## The single source of truth for one run: the 8-step yearly pipeline of
## docs/Phase_1/01_Balance_Model.md, implemented per docs/Phase_4/01-05.
## Headless-capable: never touches nodes, autoloads or OS. The only
## nondeterminism is rng_events (stream 2), consumed ONLY in step 6.

signal year_started(year: int)
signal card_played(card_id: StringName, accepted: bool)
signal year_advanced(report: TurnRecord)
signal event_struck(event_id: StringName, region_id: StringName, opportunity: StringName)
signal warming_band_changed(band: int)
signal ally_changed(region_id: StringName, is_ally: bool)
signal run_ended(outcome: StringName, knowledge_points: int)

enum Phase { AWAIT_ACTION, RESOLVING, ENDED }

const DAMAGE_KEYS: Array[String] = ["money", "happiness", "absorption", "influence"]


class SectorState:
	extends RefCounted
	var base: float = 0.0
	var progress: float = 0.0
	var suff_played: bool = false

	func cap() -> float:
		return float(Tuning.c("FULL_CAP")) if suff_played else float(Tuning.c("TECH_CAP"))


class ReforestEntry:
	extends RefCounted
	var per_year: float = 0.0
	var years_left: int = 0


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
# --- feedback loop one-shots (event id -> trigger year) ---
var fires: int = 0
var feedback_years: Dictionary = {}
# --- world (Phase 3) ---
var world: Array[RegionData] = []
var action_taken: bool = false
var rng_events: RandomNumberGenerator
var records: Array[TurnRecord] = []
var catalog: Catalog
var unlocked_knowledge: Array = []

var _pending_income: Dictionary = {}
var _pending_action: Dictionary = {}


# Named accessors for the three MVP feedback loops (debug overlay / tests).
var permafrost: bool:
	get: return feedback_years.has("permafrost_methane")
var ocean_weak: bool:
	get: return feedback_years.has("ocean_sink_weakening")
var amazon: bool:
	get: return feedback_years.has("amazon_dieback")


static func new_run(gen: WorldGen.WorldGenResult, base_catalog: Catalog, unlocked_ids: Array = []) -> RunState:
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
	rs.unlocked_knowledge = unlocked_ids.duplicate()
	rs.catalog = base_catalog.duplicate_patched(unlocked_ids)
	var grants := base_catalog.grants(unlocked_ids)
	rs.media = bool(grants["media"])
	rs.adapt = minf(float(Tuning.s("ADAPT_MAX")), float(grants["adapt"]))
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


func gross_emissions() -> float:
	var e := e_extra
	for s in WorldEnums.SECTOR_ORDER:
		var ss := sector(s)
		e += ClimateCalc.sector_emissions(ss.base, ss.progress)
	return e


func net_emissions() -> float:
	return gross_emissions() - absorption


func warming_band() -> int:
	return ClimateCalc.band(temp)


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


## Effects applied by this year's not-yet-resolved action (UI preview + tests).
func pending_effects() -> Array:
	return _pending_action.get("effects_applied", [])


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
	if phase != Phase.AWAIT_ACTION or action_taken:
		return &"action_taken"
	var card := catalog.card(card_id)
	if card.is_empty():
		return &"unknown_card"
	if effective_cost_money(card_id) > money:
		return &"no_money"
	if float(card.get("cost_influence", 0)) > influence:
		return &"no_influence"
	var requires: Dictionary = card.get("requires", {})
	if int(requires.get("allies_min", 0)) > allies:
		return &"locked_allies"
	for eff: Dictionary in card.get("effects", []):
		match String(eff.get("op", "")):
			"ally":
				if allies >= int(Tuning.s("MAX_ALLIES")) or neutral_regions().is_empty():
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
		&"no_money", &"no_influence": return ERR_CANT_ACQUIRE_RESOURCE
		&"locked_allies": return ERR_UNCONFIGURED
		&"media_active": return ERR_ALREADY_IN_USE
		&"no_target": return ERR_DOES_NOT_EXIST
		&"unknown_card": return ERR_INVALID_PARAMETER
	return ERR_UNAVAILABLE  # ended / action_taken / capped


# ------------------------------------------------- step 2: player action ---

## Play exactly one card this year. target_region is required only by cards
## with an "ally" effect (DIP1); empty auto-picks the first neutral region.
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

	# 1. Pay.
	var cost_m := effective_cost_money(card_id)
	var cost_i := float(card.get("cost_influence", 0))
	var used_discount: bool = fire_discount and (card.get("tags", []) as Array).has("restoration")
	money -= cost_m
	influence -= cost_i
	if used_discount:
		fire_discount = false

	# 2. Apply effects in catalog order.
	var applied: Array[Dictionary] = []
	var waiver: StringName = &"none"
	for eff: Dictionary in card["effects"]:
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
				applied.append({"op": op, "sector": String(sid), "requested": requested, "applied": add})
			"joint_progress":
				var requested := float(eff["amount"])
				var entry := {"op": op, "requested": requested}
				for sid in WorldEnums.SECTOR_ORDER:  # fixed order; never lifts caps
					var ss := sector(sid)
					var add := minf(ss.cap(), ss.progress + requested) - ss.progress
					ss.progress += add
					entry["applied_" + String(sid)] = add
				applied.append(entry)
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
			"sink_now":
				var amount := float(eff["amount"])
				absorption += amount
				applied.append({"op": op, "requested": amount, "applied": amount})
			"reforest":
				var entry := ReforestEntry.new()
				entry.per_year = float(eff["per_year"])
				entry.years_left = int(eff["years"])
				reforest_queue.append(entry)
				applied.append({"op": op, "per_year": entry.per_year, "years": entry.years_left})
			"adapt":
				var requested := float(eff["amount"])
				var add := minf(float(Tuning.s("ADAPT_MAX")), adapt + requested) - adapt
				adapt += add
				applied.append({"op": op, "requested": requested, "applied": add})
			"media":
				media = true
				applied.append({"op": op})
			"ally":
				allies += 1
				ally_target.ally_state = WorldEnums.AllyState.ALLY
				applied.append({"op": op, "region": String(ally_target.id)})
				ally_changed.emit(ally_target.id, true)

	action_taken = true
	_pending_action = {
		"action": card_id,
		"target": ally_target.id if ally_target != null else &"",
		"costs": Vector2(cost_m, cost_i),
		"effects_applied": applied,
		"waiver": waiver,
	}
	card_played.emit(card_id, true)
	return OK


# --------------------------------------------------- steps 1 and 3-8 ---

func _begin_year() -> void:
	action_taken = false
	_pending_action = {}
	# Step 1: income (strongest happiness penalty only).
	var inc := SocietyCalc.income(happiness, allies)
	money += float(inc["amount"])
	var inf_gain := SocietyCalc.influence_income(allies, media)
	influence += inf_gain
	var rebuild := false
	var rebuild_amount := 0.0
	if flood_rebuild:
		var ss := sector(&"tra")
		rebuild_amount = minf(ss.cap(), ss.progress + float(Tuning.s("FLOOD_REBUILD_TRA"))) - ss.progress
		ss.progress += rebuild_amount
		flood_rebuild = false
		rebuild = true
	_pending_income = {
		"money": float(inc["amount"]),
		"influence": inf_gain,
		"penalty": StringName(inc["penalty"]),
		"rebuild": rebuild,
		"rebuild_amount": rebuild_amount,
	}
	phase = Phase.AWAIT_ACTION
	year_started.emit(year)


## Resolve steps 3-8 for the current year. Passing (no card played) is legal
## and is recorded as an explicit decision.
func resolve_year() -> TurnRecord:
	if phase == Phase.ENDED:
		return records.back() if not records.is_empty() else null
	phase = Phase.RESOLVING

	var rec := TurnRecord.new()
	rec.year = year
	rec.income_money = float(_pending_income.get("money", 0.0))
	rec.income_influence = float(_pending_income.get("influence", 0.0))
	rec.income_penalty = _pending_income.get("penalty", &"none")
	rec.rebuild_bonus_applied = bool(_pending_income.get("rebuild", false))
	rec.rebuild_bonus_amount = float(_pending_income.get("rebuild_amount", 0.0))
	if not _pending_action.is_empty():
		rec.action = _pending_action["action"]
		rec.action_target = _pending_action["target"]
		rec.costs_paid = _pending_action["costs"]
		rec.effects_applied = _pending_action["effects_applied"]
		rec.waiver_used = _pending_action["waiver"]

	# --- Step 3: carbon ledger (mature -> stress -> floor -> E -> N) ---
	var matured := 0.0
	for entry in reforest_queue:
		absorption += entry.per_year
		matured += entry.per_year
		entry.years_left -= 1
	reforest_queue = reforest_queue.filter(func(e: ReforestEntry) -> bool: return e.years_left > 0)
	var t_prev := temp
	var stress := ClimateCalc.sink_stress(t_prev)  # reads LAST year's temperature
	absorption = maxf(ClimateCalc.a_floor(), absorption - stress)
	var e := gross_emissions()
	var n := ClimateCalc.net(e, absorption)
	rec.sink_matured = matured
	rec.sink_stress = stress
	rec.emissions = e
	rec.absorption = absorption
	rec.net = n

	# --- Step 4: warming ---
	var dt := ClimateCalc.warming_delta(n)
	temp = ClimateCalc.apply_warming(temp, n)
	rec.warming_delta = dt
	rec.temp = temp
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

	# --- Step 6: events (single consumer of rng_events, fixed catalog order) ---
	var mult := SocietyCalc.damage_mult(happiness, adapt)  # frozen at step-6 entry
	for ev in catalog.extreme_events():
		var p := _event_probability(ev, band_new)
		var roll := rng_events.randf()
		if roll < p:
			_apply_event(ev, mult, rec)

	# --- Step 7: one-time feedback loops (post-event state, fixed order) ---
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

	# --- Step 8: end-of-turn check ---
	var status := EndState.evaluate(year, temp, n)
	rec.end_status = EndState.status_string(status)
	rec.money = money
	rec.influence = influence
	rec.allies = allies
	rec.resilience = resilience()

	if status != EndState.RunStatus.RUNNING:
		var progs: Array = []
		for s in WorldEnums.SECTOR_ORDER:
			progs.append(sector(s).progress)
		rec.kp_awarded = EndState.knowledge_points(status, year, progs, allies)

	rec.log_lines = _build_log_lines(rec)
	records.append(rec)

	if status == EndState.RunStatus.RUNNING:
		year_advanced.emit(rec)
		year += 1
		_begin_year()
	else:
		phase = Phase.ENDED
		run_ended.emit(rec.end_status, rec.kp_awarded)
	return rec


func _event_probability(ev: Dictionary, band_new: int) -> float:
	if ev.has("probability_formula"):
		return SocietyCalc.social_crisis_p(happiness, band_new, media, ev["probability_formula"])
	var probs: Array = ev["probabilities"]
	return float(probs[band_new])


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


func _apply_event(ev: Dictionary, mult: float, rec: TurnRecord) -> void:
	var ev_id := String(ev["id"])
	var target := _draw_event_target(ev)
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

	var region_id: StringName = target.id if target != null else &""
	rec.events.append({
		"id": StringName(ev_id),
		"region_id": region_id,
		"mult": used_mult,
		"damages": applied_damages,
		"ally_lost": ally_lost,
		"opportunity": opp_flag,
	})
	event_struck.emit(StringName(ev_id), region_id, opp_flag)


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
	# Step 2: action.
	if rec.action == &"pass":
		lines.append(LogFormatter.render("system", "pass"))
	else:
		var card := catalog.card(rec.action)
		var cost_note := "-%s funds" % LogFormatter.fmt(rec.costs_paid.x)
		if rec.costs_paid.y > 0.0:
			cost_note += ", -%s influence" % LogFormatter.fmt(rec.costs_paid.y)
		lines.append(LogFormatter.render("cards", "enact", {
			"name": card.get("name", String(rec.action)), "cost_note": cost_note,
		}))
		for eff in rec.effects_applied:
			lines.append("  " + _effect_line(eff))
	# Steps 3-4: ledger and warming.
	if rec.sink_matured > 0.0:
		lines.append(LogFormatter.render("system", "sink_matured", {"amount": rec.sink_matured}))
	lines.append(LogFormatter.render("system", "ledger", {
		"e": rec.emissions, "a": rec.absorption, "n": _signed(rec.net),
	}))
	lines.append(LogFormatter.render("system", "warming", {
		"t": "%.2f" % rec.temp, "dt": _signed_precise(rec.warming_delta),
	}))
	if rec.band != rec.band_prev:
		var key := "band_up_%d" % rec.band if rec.band > rec.band_prev else "band_down_%d" % rec.band
		lines.append(LogFormatter.render("system", key))
	# Step 5: drift.
	lines.append(LogFormatter.render("system", "drift", {
		"h": rec.happiness, "co": rec.co_benefit, "stress": rec.overshoot_stress,
	}))
	# Step 6: events (damage first, opportunity second - always).
	for ev in rec.events:
		lines.append(_event_hit_line(ev))
		if ev["ally_lost"] != &"":
			var lost := region_by_id(ev["ally_lost"])
			lines.append(LogFormatter.render("system", "ally_lost", {
				"region": lost.display_name if lost != null else String(ev["ally_lost"]),
			}))
		if ev["opportunity"] != &"":
			lines.append(LogFormatter.render("events", String(ev["id"]) + "_opp"))
	# Step 7: feedbacks.
	for fb in rec.feedbacks:
		lines.append(LogFormatter.render("events", String(fb) + "_hit"))
	# Step 8: terminal.
	if rec.end_status != &"RUNNING":
		lines.append(LogFormatter.render("endings", String(rec.end_status)))
		lines.append(LogFormatter.render("system", "run_end_kp", {"kp": rec.kp_awarded}))
	return lines


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
			return LogFormatter.render("ops", op, {"per_year": eff["per_year"], "years": eff["years"]})
		"adapt":
			return LogFormatter.render("ops", op, {"amount": eff["applied"]})
		"media":
			return LogFormatter.render("ops", op)
		"ally":
			var r := region_by_id(StringName(String(eff.get("region", ""))))
			return LogFormatter.render("ops", op, {
				"region": r.display_name if r != null else String(eff.get("region", "")),
			})
	return op


func _event_hit_line(ev: Dictionary) -> String:
	var region := region_by_id(ev["region_id"])
	var fields := {
		"region": region.display_name if region != null else "the world",
		"fires": fires,
		"ally_note": "",
		"resilience_note": "",
	}
	var damages: Dictionary = ev["damages"]
	for key in damages:
		fields[key] = damages[key]
	if float(ev["mult"]) < 1.0:
		fields["resilience_note"] = LogFormatter.render("events", "resilience_note")
	if ev["ally_lost"] != &"":
		fields["ally_note"] = ", an ally wavers"
	return LogFormatter.render("events", String(ev["id"]) + "_hit", fields)


static func _signed(v: float) -> String:
	return ("+" + LogFormatter.fmt(v)) if v >= 0.0 else LogFormatter.fmt(v)


static func _signed_precise(v: float) -> String:
	return ("+%.3f" % v) if v >= 0.0 else ("%.3f" % v)
