extends TestBase
## Pipeline end-to-end: T3-P4 (BAU loss), T11-P4 (feedback one-shots),
## T12-P4 (determinism replay), T14-P4 (signal audit), Phase 3 T6 (region
## decomposition), T8 (event targeting), T9 (DIP1 flavor-only targeting).


func test_all_pass_bau_loses_mid_2050s() -> void:  # T3-P4
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	var guard := 100
	while rs.phase != RunState.Phase.ENDED and guard > 0:
		guard -= 1
		rs.resolve_year()
	var last: TurnRecord = rs.records.back()
	eq(last.end_status, &"LOSS_LIMIT_BREACHED", "business as usual breaches the limit")
	check(last.year >= 2048 and last.year <= 2058,
		"BAU loss lands mid-2050s (got %d)" % last.year)


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
	var rs := Strategies.autoplay(&"risky", 2030, true)
	# Risky canonical run reaches Overshoot II: permafrost must have fired once.
	check(rs.permafrost, "permafrost triggered on the risky run")
	var seen := {}
	for rec in rs.records:
		for fb in rec.feedbacks:
			seen[fb] = int(seen.get(fb, 0)) + 1
	for fb in seen:
		eq(int(seen[fb]), 1, "feedback %s fired exactly once" % fb)
	check(rs.e_extra >= 2.0, "permafrost added permanent emissions")
	# Feedback years recorded for the debug overlay.
	check(rs.feedback_years.has("permafrost_methane"), "trigger year recorded")


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
	var guard := 100
	while rs.phase != RunState.Phase.ENDED and guard > 0:
		guard -= 1
		var choice := Strategies.decide(&"safe", rs)
		if choice["card"] != &"pass":
			rs.play_card(choice["card"], choice["target"])
		rs.resolve_year()
	eq(int(counts["run_ended"]), 1, "run_ended fires exactly once")
	rs.resolve_year()  # no-op after ENDED
	eq(int(counts["run_ended"]), 1, "no signal after ENDED")
	var changes: Array = counts["band_changes"]
	check(changes.size() >= 2, "band changed at least twice (in and out of Overshoot)")
	check(changes.has(1), "entered Overshoot I")
	check(changes.has(0), "exited Overshoot (the hopeful descent) - got %s" % str(changes))
	eq(int(counts["year_advanced"]), rs.records.size() - 1, "year_advanced fires for every non-terminal year")


func test_region_decomposition() -> void:  # Phase 3 T6
	var rs := RunState.new_run(WorldGen.generate(5, false), Catalog.load_default(), [])
	var guard := 30
	while rs.phase != RunState.Phase.ENDED and guard > 0:
		guard -= 1
		var choice := Strategies.decide(&"safe", rs)
		if choice["card"] != &"pass":
			rs.play_card(choice["card"], choice["target"])
		rs.resolve_year()
		var sum_e := 0.0
		var sum_a := 0.0
		for r in rs.world:
			sum_e += rs.region_emissions(r)
			sum_a += rs.region_absorption(r)
		# Feedback extras are global-only; regions decompose the sector ledger.
		approx(sum_e, rs.gross_emissions() - rs.e_extra, 0.001,
			"region emissions sum to global sector emissions (year %d)" % rs.year)
		approx(sum_a, rs.absorption, 0.001, "region absorption sums to global A")


func test_event_targeting_rules() -> void:  # Phase 3 T8
	# Aggregate over several seeds so every event type appears.
	for s in [2030, 3, 5, 9, 13]:
		var rs := Strategies.autoplay(&"risky", s, false)
		for rec in rs.records:
			for ev in rec.events:
				var region := rs.region_by_id(ev["region_id"])
				if region == null:
					continue
				match String(ev["id"]):
					"flood_tsunami":
						check(region.coastal, "flood targets only coastal (seed %d)" % s)
					"mega_fire":
						check(region.forested or region.arid, "fire targets forested/arid (seed %d)" % s)
				if ev["ally_lost"] != &"":
					var lost := rs.region_by_id(ev["ally_lost"])
					check(not lost.is_player_home, "player home never lost as ally")


func test_dip1_target_flavor_only() -> void:  # Phase 3 T9
	var series_a := _dip1_series(3)
	var series_b := _dip1_series(7)
	eq(series_a, series_b, "DIP1 target choice never changes the timeline")


func _dip1_series(target_index: int) -> String:
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	rs.influence = 30.0
	var target := rs.neutral_regions()[target_index]
	rs.play_card(&"DIP1", target.id)
	var out: PackedStringArray = []
	for i in 30:
		if rs.phase == RunState.Phase.ENDED:
			break
		var rec := rs.resolve_year()
		out.append("%d|%.4f|%.2f|%.2f|%.2f|%d" % [rec.year, rec.temp, rec.money, rec.happiness, rec.influence, rec.allies])
	return "\n".join(out)


func test_flood_rebuild_rider() -> void:
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	rs.flood_rebuild = true
	var p0 := rs.sector(&"tra").progress
	rs.resolve_year()  # consumed at next year's step 1
	eq(rs.sector(&"tra").progress, p0 + 5.0, "flood rebuild grants +5 transport next year")
	eq(rs.flood_rebuild, false, "flag consumed")
	check(rs.records.size() >= 1, "recorded")


func test_reforest_maturation() -> void:
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	rs.money = 1000.0
	rs.play_card(&"SNK1")  # +0.3/yr for 5 years
	var rec := rs.resolve_year()
	approx(rec.sink_matured, 0.3, 1e-9, "first maturation tick")
	var total := rec.sink_matured
	for i in 5:
		total += rs.resolve_year().sink_matured
	eq(rs.reforest_queue.size(), 0, "program finished after 5 years")
	approx(total, 1.5, 1e-9, "program delivered +1.5 absorption in total")
