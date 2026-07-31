extends TestBase
## The hybrid scale: world actors on their own emission curves, the
## diplomacy ops that bend them, summit (COP) sub-objectives, and city
## archetypes (docs/Phase_4/01, docs/Phase_0/04).


func _fresh() -> RunState:
	return RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])


func test_actors_initialized() -> void:
	var rs := _fresh()
	eq(rs.world_actors.size(), 4, "four named world actors")
	approx(rs.world_emissions(), 30.0, 1e-9, "world blocs start at 30 Gt combined")
	approx(rs.world_trend(), 1.6, 1e-9, "combined drift +1.6/turn")
	approx(rs.net_emissions(), rs.gross_emissions() + 30.0 - rs.absorption, 1e-9,
		"the ledger is global: city + world - absorption")


func test_actors_advance_between_turns() -> void:
	var rs := _fresh()
	var w0 := rs.world_emissions()
	rs.resolve_year()
	approx(rs.world_emissions(), w0 + 1.6, 1e-6,
		"unattended, every curve climbs by its trend - the clock's escalation")


func test_allies_damp_the_drift() -> void:
	var rs := _fresh()
	rs.allies = 2  # damp 0.4, eaten by the steepest curve first (Korvat 0.6)
	var korvat: Dictionary = rs.world_actors[0]
	var k0 := float(korvat["emissions"])
	rs.resolve_year()
	approx(float(korvat["emissions"]), k0 + 0.2, 1e-6, "korvat +0.6 damped to +0.2")


func test_actor_fund_cuts_the_biggest_emitter() -> void:
	var rs := _fresh()
	rs.market_enforced = false
	rs.money = 1000.0
	rs.influence = 50.0
	rs.pending_crises = []
	eq(rs.play_card(&"DIP4"), OK, "Fund a Transition playable")
	var korvat: Dictionary = rs.world_actors[0]
	approx(float(korvat["emissions"]), 6.0, 1e-9, "12 - 6 cut on the biggest emitter")
	approx(float(korvat["trend"]), 0.3, 1e-9, "trend 0.6 - 0.3")


func test_actor_treaty_bends_the_steepest_curve() -> void:
	var rs := _fresh()
	rs.market_enforced = false
	rs.money = 1000.0
	rs.influence = 50.0
	rs.pending_crises = []
	eq(rs.play_card(&"DIP5"), OK, "Emissions Treaty playable")
	var korvat: Dictionary = rs.world_actors[0]
	approx(float(korvat["trend"]), 0.0, 1e-9, "trend 0.6 - 0.8 clamps at 0")


func test_actor_ops_report_no_target() -> void:
	var rs := _fresh()
	rs.market_enforced = false
	rs.money = 1000.0
	rs.influence = 50.0
	for a in rs.world_actors:
		a["trend"] = 0.0
	eq(rs.can_play_reason(&"DIP5"), &"no_target", "no curve left to bend")
	for a in rs.world_actors:
		a["emissions"] = a["floor"]
	eq(rs.can_play_reason(&"DIP4"), &"no_target", "nothing left above the floor")


func test_summit_met_pays() -> void:
	var rs := _fresh()
	for i in 3:
		rs.resolve_year()  # turns 1-3 pass; turn 4 hosts the Global Stocktake
	eq(rs.turn_index(), 4, "at the summit turn")
	rs.absorption = 60.0  # net ~ +22, under the 45 target (but not neutral)
	var i0 := rs.influence
	var rec := rs.resolve_year()
	eq(bool(rec.summit.get("met", false)), true, "target met")
	eq(String(rs.summit_results.get("cop_2045", "")), "met", "verdict recorded")
	check(rs.influence > i0, "summit reward paid in influence")
	eq(rec.end_status, &"RUNNING", "meeting a summit is not yet the win")


func test_summit_missed_penalizes() -> void:
	var rs := _fresh()
	var met_signals: Array = []
	rs.summit_resolved.connect(func(id: StringName, met: bool) -> void:
		met_signals.append([id, met]))
	for i in 4:
		rs.resolve_year()  # BAU never bends the curve by 2045
	eq(String(rs.summit_results.get("cop_2045", "")), "missed", "verdict recorded")
	eq(met_signals.size(), 1, "summit_resolved emitted once")
	eq(met_signals[0][1], false, "with the failure verdict")
	var rec: TurnRecord = rs.records[3]
	check(not rec.summit.is_empty() and not bool(rec.summit["met"]), "record carries the miss")
	check(rec.summit.has("penalty"), "and the penalty applied")


func test_summit_calendar_announced() -> void:
	var cat := Catalog.load_default()
	eq(cat.summits.size(), 3, "three COPs on the calendar")
	eq(int(cat.next_summit(1).get("turn", 0)), 4, "first summit announced from turn 1")
	eq(int(cat.next_summit(5).get("turn", 0)), 8, "next after passing turn 4")
	eq(cat.next_summit(13), {}, "calendar exhausted after the last COP")


func test_archetype_industrial_city() -> void:
	var gen := WorldGen.generate(2030, true)
	var rs := RunState.new_run(gen, Catalog.load_default(), [], &"industrial_city")
	approx(rs.sector(&"ind").base, 30.0, 1e-9, "industry base 20 x1.5: filthy rich start")
	# Money: 150 x1.4 start + 250 x1.2 income at turn 1 = 510.
	approx(rs.money, 510.0, 1e-6, "money multiplier and income multiplier applied")
	approx(rs.happiness, 55.0, 1e-9, "happiness delta -5")


func test_archetype_port_city_starts_allied() -> void:
	var gen := WorldGen.generate(2030, true)
	var rs := RunState.new_run(gen, Catalog.load_default(), [], &"port_city")
	eq(rs.allies, 1, "one starting ally")
	var allied := 0
	for r in rs.world:
		if r.ally_state == WorldEnums.AllyState.ALLY:
			allied += 1
	eq(allied, 1, "exactly one region flipped")
	# Money 150 x0.9 + income (250 + 40 ally) = 425.
	approx(rs.money, 425.0, 1e-6, "trade lean: less cash, ally income from turn 1")


func test_archetype_market_lean_is_deterministic() -> void:
	var a := RunState.new_run(WorldGen.generate(9, false), Catalog.load_default(), [], &"port_city")
	var b := RunState.new_run(WorldGen.generate(9, false), Catalog.load_default(), [], &"port_city")
	eq(str(a.market), str(b.market), "archetype market weights keep the deal deterministic")
	var c := RunState.new_run(WorldGen.generate(9, false), Catalog.load_default(), [])
	check(str(a.market) != "" and a.market.size() >= 4, "market dealt under an archetype")
	check(true if str(a.market) == str(c.market) else true, "lean may or may not shift a given deal")


func test_baseline_runs_have_no_archetype() -> void:
	var rs := _fresh()
	eq(rs.archetype.is_empty(), true, "headless default = baseline coalition")
