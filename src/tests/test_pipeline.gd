extends TestBase
## Pipeline end-to-end: T3-P4 (BAU loss), T11-P4 (feedback one-shots),
## T12-P4 (determinism replay), T14-P4 (signal audit), Phase 3 T6 (region
## decomposition), T8 (crisis targeting), T9 (DIP1 flavor-only targeting).


func test_all_pass_bau_loses() -> void:  # T3-P4
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	var guard := 40
	while rs.phase != RunState.Phase.ENDED and guard > 0:
		guard -= 1
		rs.resolve_year()
	var last: TurnRecord = rs.records.back()
	check(last.end_status == &"LOSS_REVOLT" or last.end_status == &"LOSS_LIMIT_BREACHED",
		"business as usual is a hard defeat (got %s)" % last.end_status)
	check(last.turn >= 5 and last.turn <= 11,
		"BAU dies mid-run - the clock is a real adversary (turn %d)" % last.turn)


func test_turn_structure() -> void:
	# One decision turn = 5 years; a full run is exactly 15 turns, 2030-2100.
	eq(RunState.total_turns(), 15, "15 decision turns per run")
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	eq(rs.year, 2030, "turn 1 = 2030")
	eq(rs.turn_index(), 1, "1-based turn index")
	rs.resolve_year()
	eq(rs.year, 2035, "each turn spans 5 years")
	eq(rs.turn_index(), 2, "turn index follows")


func test_determinism_replay() -> void:  # T12-P4
	var a := _jsonl(Strategies.autoplay(&"safe", 77, false))
	var b := _jsonl(Strategies.autoplay(&"safe", 77, false))
	eq(a, b, "identical runs => byte-identical JSONL")
	var c := _jsonl(Strategies.autoplay(&"safe", 78, false))
	check(a != c, "different seed => different timeline")


func _jsonl(rs: RunState) -> String:
	var lines: PackedStringArray = []
	for rec in rs.records:
		lines.append(rec.to_jsonl_line())
	return "\n".join(lines)


func test_feedback_one_shots() -> void:  # T11-P4
	# BAU overheats far enough that at least one feedback loop must fire.
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	var guard := 40
	while rs.phase != RunState.Phase.ENDED and guard > 0:
		guard -= 1
		rs.resolve_year()
	var seen := {}
	for rec in rs.records:
		for fb in rec.feedbacks:
			seen[fb] = int(seen.get(fb, 0)) + 1
	check(seen.size() >= 1, "BAU run triggered at least one feedback loop")
	for fb in seen:
		eq(int(seen[fb]), 1, "feedback %s fired exactly once" % fb)
	for fb_id in rs.feedback_years:
		check(seen.has(StringName(String(fb_id))), "trigger year recorded for %s" % fb_id)
	if rs.permafrost:
		check(rs.e_extra >= 2.0, "permafrost added permanent emissions")


func test_signal_audit() -> void:  # T14-P4
	var gen := WorldGen.generate(2030, true)
	var rs := RunState.new_run(gen, Catalog.load_default(), [])
	var counts := {"run_ended": 0, "band_changes": [], "year_advanced": 0}
	rs.run_ended.connect(func(_o: StringName, _kp: int) -> void:
		counts["run_ended"] += 1)
	rs.warming_band_changed.connect(func(band: int) -> void:
		counts["band_changes"].append(band))
	rs.year_advanced.connect(func(_r: TurnRecord) -> void:
		counts["year_advanced"] += 1)
	var guard := 40
	while rs.phase != RunState.Phase.ENDED and guard > 0:
		guard -= 1
		Strategies.play_turn(&"safe", rs)
	eq(int(counts["run_ended"]), 1, "run_ended fires exactly once")
	rs.resolve_year()  # no-op after ENDED
	eq(int(counts["run_ended"]), 1, "no signal after ENDED")
	var changes: Array = counts["band_changes"]
	check(changes.size() >= 1, "warming band changed at least once")
	check(changes.has(1), "entered Overshoot I")
	eq(int(counts["year_advanced"]), rs.records.size() - 1, "year_advanced fires for every non-terminal turn")


func test_curve_bent_signal() -> void:
	# The explosion moment: the first net<=0 turn emits curve_bent and, by
	# the race rules, wins the run on the spot.
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	var bent_years: Array = []
	rs.curve_bent.connect(func(y: int) -> void: bent_years.append(y))
	rs.absorption = 500.0  # force the drawdown moment
	rs.resolve_year()
	eq(bent_years.size(), 1, "curve_bent emitted once")
	eq(rs.curve_bent_year, bent_years[0], "curve_bent_year recorded")
	eq(rs.records.back().end_status, &"WIN_NEUTRAL", "neutrality before the tipping point wins")


func test_region_decomposition() -> void:  # Phase 3 T6
	var rs := RunState.new_run(WorldGen.generate(5, false), Catalog.load_default(), [])
	var guard := 15
	while rs.phase != RunState.Phase.ENDED and guard > 0:
		guard -= 1
		Strategies.play_turn(&"safe", rs)
		var sum_e := 0.0
		var sum_a := 0.0
		for r in rs.world:
			sum_e += rs.region_emissions(r)
			sum_a += rs.region_absorption(r)
		# Feedback extras and world actors are global-only; regions decompose
		# the city-sphere sector ledger.
		approx(sum_e, rs.gross_emissions() - rs.e_extra, 0.001,
			"region emissions sum to city sector emissions (year %d)" % rs.year)
		approx(sum_a, rs.absorption, 0.001, "region absorption sums to global A")


func test_crisis_targeting_rules() -> void:  # Phase 3 T8
	# Aggregate over several seeds so every crisis type appears in the draws.
	for s in [2030, 3, 5, 9, 13]:
		var rs := Strategies.autoplay(&"risky", s, false)
		for rec in rs.records:
			for crisis in rec.crises:
				var region := rs.region_by_id(crisis["region_id"])
				if region == null:
					continue
				match String(crisis["id"]):
					"flood_tsunami":
						check(region.coastal, "flood targets only coastal (seed %d)" % s)
					"mega_fire":
						check(region.forested or region.arid, "fire targets forested/arid (seed %d)" % s)
				if crisis.get("ally_lost", &"") != &"":
					var lost := rs.region_by_id(crisis["ally_lost"])
					check(not lost.is_player_home, "player home never lost as ally")


func test_dip1_target_flavor_only() -> void:  # Phase 3 T9
	var series_a := _dip1_series(3)
	var series_b := _dip1_series(7)
	eq(series_a, series_b, "DIP1 target choice never changes the timeline")


func _dip1_series(target_index: int) -> String:
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	rs.market_enforced = false
	rs.influence = 30.0
	var target := rs.neutral_regions()[target_index]
	rs.play_card(&"DIP1", target.id)
	var out: PackedStringArray = []
	for i in 20:
		if rs.phase == RunState.Phase.ENDED:
			break
		var rec := rs.resolve_year()
		out.append("%d|%.4f|%.2f|%.2f|%.2f|%d" % [rec.year, rec.temp, rec.money, rec.happiness, rec.influence, rec.allies])
	return "\n".join(out)


func test_flood_rebuild_rider() -> void:
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	rs.flood_rebuild = true
	rs.pending_crises = []  # an unanswered flood would re-arm the flag
	var p0 := rs.sector(&"tra").progress
	rs.resolve_year()  # consumed at next turn's step 1
	eq(rs.sector(&"tra").progress, p0 + 5.0, "flood rebuild grants +5 transport next turn")
	eq(rs.flood_rebuild, false, "flag consumed")
	check(rs.records.size() >= 1, "recorded")


func test_reforest_maturation() -> void:
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	rs.market_enforced = false
	rs.money = 1000.0
	rs.play_card(&"SNK1")  # +1.0/turn for 3 turns
	var rec := rs.resolve_year()
	approx(rec.sink_matured, 1.0, 1e-9, "first maturation tick")
	var total := rec.sink_matured
	for i in 3:
		total += rs.resolve_year().sink_matured
	eq(rs.reforest_queue.size(), 0, "program finished after 3 turns")
	approx(total, 3.0, 1e-9, "program delivered +3.0 absorption in total")
