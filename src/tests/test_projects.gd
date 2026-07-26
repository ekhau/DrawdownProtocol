extends TestBase
## Long-term projects: launch pays year one, upkeep charges at each year
## start, completion grants effects + permanent passives, failing to pay or
## abandoning applies the penalty, and completion feeds deck growth.


func _fresh(money: float = 10000.0) -> RunState:
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	rs.money = money
	rs.influence = 100.0
	rs.pending_crises = []
	return rs


func _quiet_resolve(rs: RunState) -> void:
	rs.pending_crises = []  # keep crisis damage out of the accounting
	rs.resolve_year()


func test_launch_pays_first_year() -> void:
	var rs := _fresh()
	var m0 := rs.money
	eq(rs.can_start_project_reason(&"global_sink_trust"), &"ok", "startable")
	eq(rs.start_project(&"global_sink_trust"), OK, "launched")
	eq(rs.money, m0 - 35.0, "first upkeep paid on launch")
	eq(rs.active_projects.size(), 1, "active")
	eq(rs.can_start_project_reason(&"global_sink_trust"), &"already_active", "no double launch")


func test_max_two_active() -> void:
	var rs := _fresh()
	rs.start_project(&"global_sink_trust")
	rs.start_project(&"continental_rail")
	eq(rs.can_start_project_reason(&"universal_services"), &"max_active", "two at once is the limit")
	eq(rs.start_project(&"universal_services"), ERR_UNAVAILABLE, "third refused")


func test_completion_after_five_payments() -> void:
	var rs := _fresh()
	var a0 := rs.absorption
	rs.start_project(&"global_sink_trust")  # payment 1 (launch year)
	for i in 3:
		_quiet_resolve(rs)  # payments 2-4 at the next year starts
		eq(rs.active_projects.size(), 1, "still active after payment %d" % (i + 2))
	eq(rs.projects_completed, 0, "not complete before the fifth payment")
	_quiet_resolve(rs)  # payment 5 -> completes
	eq(rs.projects_completed, 1, "completed after five paid years")
	eq(rs.active_projects.size(), 0, "no longer active")
	eq(String(rs.project_history["global_sink_trust"]), "completed", "history records it")
	approx(float(rs.passives.get("absorption_per_year", 0.0)), 0.15, 1e-9, "passive registered")
	# sink_now +1.0 on completion, +0.15 passive, minus 4 years of maturation noise:
	check(rs.absorption > a0 + 1.0 - 0.5, "completion sink bonus landed (a %f -> %f)" % [a0, rs.absorption])
	# The passive keeps paying: absorption grows at each new year start.
	var a_now := rs.absorption
	_quiet_resolve(rs)
	check(rs.absorption >= a_now + 0.15 - 0.20, "passive absorption ticks yearly (stress-adjusted)")


func test_failed_payment_applies_penalty() -> void:
	var rs := _fresh()
	rs.start_project(&"world_climate_accord")  # upkeep 30M + 4 influence
	var h0 := rs.happiness
	rs.influence = 0.0  # yearly influence income (2) cannot cover the 4I upkeep
	_quiet_resolve(rs)
	eq(rs.active_projects.size(), 0, "project collapsed")
	eq(String(rs.project_history["world_climate_accord"]), "failed", "failure recorded")
	eq(rs.happiness, h0 - 3.0, "happiness penalty")
	eq(rs.influence, 0.0, "influence penalty floors at zero (2 income - 12 penalty)")
	eq(rs.can_start_project_reason(&"world_climate_accord"), &"already_done", "no relaunch after failure")


func test_abandon_applies_penalty() -> void:
	var rs := _fresh()
	rs.start_project(&"continental_rail")
	var h0 := rs.happiness
	var i0 := rs.influence
	eq(rs.abandon_project(&"continental_rail"), OK, "abandoned")
	eq(rs.happiness, h0 - 4.0, "happiness penalty")
	eq(rs.influence, i0 - 10.0, "influence penalty")
	eq(String(rs.project_history["continental_rail"]), "abandoned", "history records it")
	eq(rs.abandon_project(&"continental_rail"), ERR_DOES_NOT_EXIST, "cannot abandon twice")


func test_accord_completion_allies_and_income() -> void:
	var rs := _fresh()
	rs.start_project(&"world_climate_accord")
	for i in 4:
		_quiet_resolve(rs)
	eq(rs.projects_completed, 1, "accord completed")
	eq(rs.allies, 2, "two allies joined on completion")
	approx(float(rs.passives.get("income_money", 0.0)), 20.0, 1e-9, "permanent +20 income")
	var m0 := rs.money
	_quiet_resolve(rs)
	# Income: 100 base + 2 allies x20 + 20 passive = 160 (happiness is healthy).
	approx(rs.money, m0 + 160.0, 1e-6, "income includes allies and the passive")


func test_completion_unlocks_blue_carbon() -> void:
	var rs := _fresh()
	rs.start_project(&"global_sink_trust")
	for i in 4:
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
	check(charged, "yearly charge recorded in the next record")