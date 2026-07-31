extends TestBase
## Long-term projects: launch pays turn one, upkeep charges at each turn
## start, completion grants effects + permanent passives, failing to pay or
## abandoning applies the penalty, and completion feeds deck growth.
## Projects run 3 turns = 15 years.


func _fresh(money: float = 10000.0) -> RunState:
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	rs.market_enforced = false
	rs.money = money
	rs.influence = 100.0
	rs.pending_crises = []
	return rs


func _quiet_resolve(rs: RunState) -> void:
	rs.pending_crises = []  # keep crisis damage out of the accounting
	rs.resolve_year()


func test_launch_pays_first_turn() -> void:
	var rs := _fresh()
	var m0 := rs.money
	eq(rs.can_start_project_reason(&"global_sink_trust"), &"ok", "startable")
	eq(rs.start_project(&"global_sink_trust"), OK, "launched")
	eq(rs.money, m0 - 90.0, "first upkeep paid on launch")
	eq(rs.active_projects.size(), 1, "active")
	eq(rs.can_start_project_reason(&"global_sink_trust"), &"already_active", "no double launch")


func test_max_two_active() -> void:
	var rs := _fresh()
	rs.start_project(&"global_sink_trust")
	rs.start_project(&"continental_rail")
	eq(rs.can_start_project_reason(&"universal_services"), &"max_active", "two at once is the limit")
	eq(rs.start_project(&"universal_services"), ERR_UNAVAILABLE, "third refused")


func test_completion_after_three_payments() -> void:
	var rs := _fresh()
	var a0 := rs.absorption
	rs.start_project(&"global_sink_trust")  # payment 1 (launch turn)
	_quiet_resolve(rs)  # payment 2 at the next turn start
	eq(rs.active_projects.size(), 1, "still active after payment 2")
	eq(rs.projects_completed, 0, "not complete before the third payment")
	_quiet_resolve(rs)  # payment 3 -> completes
	eq(rs.projects_completed, 1, "completed after three paid turns")
	eq(rs.active_projects.size(), 0, "no longer active")
	eq(String(rs.project_history["global_sink_trust"]), "completed", "history records it")
	approx(float(rs.passives.get("absorption_per_turn", 0.0)), 0.8, 1e-9, "passive registered")
	# sink_now +2.0 on completion, +0.8 passive, minus stress noise:
	check(rs.absorption > a0 + 2.0 - 1.0, "completion sink bonus landed (a %f -> %f)" % [a0, rs.absorption])
	# The passive keeps paying: absorption grows at each new turn start.
	var a_now := rs.absorption
	_quiet_resolve(rs)
	check(rs.absorption >= a_now + 0.8 - 1.3, "passive absorption ticks per turn (stress-adjusted)")


func test_failed_payment_applies_penalty() -> void:
	var rs := _fresh()
	rs.start_project(&"world_climate_accord")  # upkeep 80M + 8 influence
	var h0 := rs.happiness
	rs.influence = 0.0  # per-turn influence income (6) cannot cover the 8I upkeep
	_quiet_resolve(rs)
	eq(rs.active_projects.size(), 0, "project collapsed")
	eq(String(rs.project_history["world_climate_accord"]), "failed", "failure recorded")
	eq(rs.happiness, h0 - 6.0, "happiness penalty")
	check(rs.influence < 8.0, "influence penalty applied (floored at zero)")
	eq(rs.can_start_project_reason(&"world_climate_accord"), &"already_done", "no relaunch after failure")


func test_abandon_applies_penalty() -> void:
	var rs := _fresh()
	rs.start_project(&"continental_rail")
	var h0 := rs.happiness
	var i0 := rs.influence
	eq(rs.abandon_project(&"continental_rail"), OK, "abandoned")
	eq(rs.happiness, h0 - 8.0, "happiness penalty")
	eq(rs.influence, i0 - 12.0, "influence penalty")
	eq(String(rs.project_history["continental_rail"]), "abandoned", "history records it")
	eq(rs.abandon_project(&"continental_rail"), ERR_DOES_NOT_EXIST, "cannot abandon twice")


func test_accord_completion_allies_and_income() -> void:
	var rs := _fresh()
	rs.start_project(&"world_climate_accord")
	for i in 2:
		_quiet_resolve(rs)
	eq(rs.projects_completed, 1, "accord completed")
	eq(rs.allies, 2, "two allies joined on completion")
	approx(float(rs.passives.get("income_money", 0.0)), 50.0, 1e-9, "permanent +50 income")
	var m0 := rs.money
	_quiet_resolve(rs)
	# Income: 250 base + 2 allies x40 + 50 passive = 380 (happiness healthy).
	approx(rs.money, m0 + 380.0, 1e-6, "income includes allies and the passive")


func test_completion_unlocks_blue_carbon() -> void:
	var rs := _fresh()
	rs.start_project(&"global_sink_trust")
	for i in 2:
		_quiet_resolve(rs)
	eq(rs.projects_completed, 1, "project completed")
	check(rs.unlocked_card_ids.has(&"SNK3"), "Blue Carbon Program unlocked by completion")


func test_project_events_recorded() -> void:
	var rs := _fresh()
	rs.start_project(&"global_sink_trust")
	var rec := rs.resolve_year()
	var launched := false
	for pe in rec.project_events:
		if String(pe["event"]) == "launched":
			launched = true
	check(launched, "launch recorded in the turn record")
	rs.pending_crises = []
	rec = rs.resolve_year()
	var charged := false
	for pe in rec.project_events:
		if String(pe["event"]) == "charged":
			charged = true
	check(charged, "per-turn charge recorded in the next record")
