class_name TurnRecord
extends RefCounted
## One immutable record per resolved year; the single source for the in-game
## log, the F3 overlay, and the headless CSV/JSONL harness.
## Spec: docs/Phase_4/06_Turn_Log_And_Analytics.md (YearReport == TurnRecord, A2).

var year: int = 0
# step 1 - income
var income_money: float = 0.0
var income_influence: float = 0.0
var income_penalty: StringName = &"none"     # &"none" | &"h_below_40" | &"h_below_25"
var rebuild_bonus_applied: bool = false
var rebuild_bonus_amount: float = 0.0
# step 2 - action
var action: StringName = &"pass"             # card id or &"pass"
var action_target: StringName = &""          # region id for DIP1, else &""
var costs_paid: Vector2 = Vector2.ZERO       # (money, influence); reflects fire_discount
var effects_applied: Array[Dictionary] = []  # [{op, ..., requested, applied}]
var waiver_used: StringName = &"none"        # &"none" | &"media" | &"window"
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
# step 6 - events
var events: Array[Dictionary] = []
#   [{id, region_id, mult, damages: {money, happiness, absorption, influence},
#     ally_lost, opportunity}]
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
# rendered log lines (template output; views display, never compute)
var log_lines: PackedStringArray = []


func to_dict() -> Dictionary:
	var evts: Array = []
	for e in events:
		evts.append({
			"id": String(e.get("id", "")),
			"region_id": String(e.get("region_id", "")),
			"mult": e.get("mult", 1.0),
			"damages": e.get("damages", {}),
			"ally_lost": String(e.get("ally_lost", "")),
			"opportunity": String(e.get("opportunity", "")),
		})
	var fbs: Array = []
	for f in feedbacks:
		fbs.append(String(f))
	return {
		"year": year,
		"income_money": income_money,
		"income_influence": income_influence,
		"income_penalty": String(income_penalty),
		"rebuild_bonus_applied": rebuild_bonus_applied,
		"action": String(action),
		"action_target": String(action_target),
		"costs_money": costs_paid.x,
		"costs_influence": costs_paid.y,
		"effects_applied": effects_applied,
		"waiver_used": String(waiver_used),
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
		"events": evts,
		"feedbacks": fbs,
		"end_status": String(end_status),
		"kp_awarded": kp_awarded,
		"money": money,
		"influence": influence,
		"allies": allies,
		"resilience": resilience,
	}


func to_jsonl_line() -> String:
	return JSON.stringify(to_dict())
