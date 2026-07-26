class_name TurnRecord
extends RefCounted
## One immutable record per resolved year; the single source for the in-game
## log, the F3 overlay, and the headless CSV/JSONL harness.
## Spec: docs/Phase_4/06_Turn_Log_And_Analytics.md (YearReport == TurnRecord, A2).

var year: int = 0
# step 1 - income and projects
var income_money: float = 0.0
var income_influence: float = 0.0
var income_penalty: StringName = &"none"     # &"none" | &"h_below_40" | &"h_below_25"
var rebuild_bonus_applied: bool = false
var rebuild_bonus_amount: float = 0.0
var project_events: Array[Dictionary] = []
#   [{id, event: launched|charged|completed|failed|abandoned, cost_money,
#     cost_influence, years_left}]
# step 1b - crisis draw (outcome fields filled during step 6)
var crises: Array[Dictionary] = []
#   [{id, kind, region_id, answered, answered_by, mult,
#     damages: {money, happiness, absorption, influence}, ally_lost, opportunity}]
# step 2 - player actions (0..MAX_CARDS_PER_TURN card plays, in play order)
var actions: Array[Dictionary] = []
#   [{card, target, cost_money, cost_influence, cost_happiness,
#     rewards: {money, influence, happiness, knowledge},
#     effects_applied: [{op, ..., requested, applied}],
#     waiver: none|media|window, crisis_answered, combos: [combo ids]}]
var combos_fired: Array[Dictionary] = []     # [{id, chain, mult, rewards}]
var combo_chain: int = 0                     # chain value after this year
var cards_unlocked: Array[StringName] = []   # unlocked during this year
# steps 3-4 - climate
var emissions: float = 0.0
var absorption: float = 0.0
var net: float = 0.0
var sink_matured: float = 0.0
var sink_stress: float = 0.0
var warming_delta: float = 0.0
var temp: float = 0.0
var band: int = 0
var band_prev: int = 0
# step 5 - society drift
var co_benefit: float = 0.0
var overshoot_stress: float = 0.0
var happiness: float = 0.0
# step 7 - feedbacks
var feedbacks: Array[StringName] = []        # triggered THIS year only
# step 8 - end
var end_status: StringName = &"RUNNING"
var kp_awarded: int = 0
# snapshot (post-step-8; the row the balance bands read)
var money: float = 0.0
var influence: float = 0.0
var allies: int = 0
var resilience: float = 0.0
var kp_earned: float = 0.0                   # in-run KP accumulated so far
# rendered log lines (template output; views display, never compute)
var log_lines: PackedStringArray = []


func to_dict() -> Dictionary:
	var crisis_rows: Array = []
	for c in crises:
		crisis_rows.append({
			"id": String(c.get("id", "")),
			"kind": String(c.get("kind", "")),
			"region_id": String(c.get("region_id", "")),
			"answered": c.get("answered", false),
			"answered_by": String(c.get("answered_by", "")),
			"mult": c.get("mult", 1.0),
			"damages": c.get("damages", {}),
			"ally_lost": String(c.get("ally_lost", "")),
			"opportunity": String(c.get("opportunity", "")),
		})
	var action_rows: Array = []
	for a in actions:
		action_rows.append({
			"card": String(a.get("card", "")),
			"target": String(a.get("target", "")),
			"cost_money": a.get("cost_money", 0.0),
			"cost_influence": a.get("cost_influence", 0.0),
			"cost_happiness": a.get("cost_happiness", 0.0),
			"rewards": a.get("rewards", {}),
			"effects_applied": a.get("effects_applied", []),
			"waiver": String(a.get("waiver", "none")),
			"crisis_answered": String(a.get("crisis_answered", "")),
			"combos": a.get("combos", []),
		})
	var fbs: Array = []
	for f in feedbacks:
		fbs.append(String(f))
	var unlocks: Array = []
	for u in cards_unlocked:
		unlocks.append(String(u))
	return {
		"year": year,
		"income_money": income_money,
		"income_influence": income_influence,
		"income_penalty": String(income_penalty),
		"rebuild_bonus_applied": rebuild_bonus_applied,
		"project_events": project_events,
		"crises": crisis_rows,
		"actions": action_rows,
		"combos_fired": combos_fired,
		"combo_chain": combo_chain,
		"cards_unlocked": unlocks,
		"emissions": emissions,
		"absorption": absorption,
		"net": net,
		"sink_matured": sink_matured,
		"sink_stress": sink_stress,
		"warming_delta": warming_delta,
		"temp": temp,
		"band": band,
		"co_benefit": co_benefit,
		"overshoot_stress": overshoot_stress,
		"happiness": happiness,
		"feedbacks": fbs,
		"end_status": String(end_status),
		"kp_awarded": kp_awarded,
		"money": money,
		"influence": influence,
		"allies": allies,
		"resilience": resilience,
		"kp_earned": kp_earned,
	}


func to_jsonl_line() -> String:
	return JSON.stringify(to_dict())
