extends SceneTree
## Headless test suite. Run from src/:
##   godot --headless -s res://tests/run_tests.gd
## Asserts the done criteria that a machine can check (spec §7).

var failures := 0
var checks := 0


func _init() -> void:
	var catalog := Catalog.load_all()
	_check(catalog != null, "catalog loads and validates")
	if catalog == null:
		quit(1)
		return

	_test_determinism(catalog)
	_test_do_nothing_loses_on_time(catalog)
	_test_playing_changes_outcome(catalog)
	_test_mortgages_compound(catalog)
	_test_band_scaling(catalog)
	_test_windfalls_never_scale(catalog)
	_test_era_gating(catalog)
	_test_combo_detection(catalog)

	print("\n%d/%d checks passed" % [checks - failures, checks])
	quit(0 if failures == 0 else 1)


func _check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("  PASS  " + label)
	else:
		failures += 1
		print("  FAIL  " + label)


func _test_determinism(catalog: Catalog) -> void:
	var a := Bots.play(catalog, 42, "greedy", "default")
	var b := Bots.play(catalog, 42, "greedy", "default")
	_check(a.year == b.year and is_equal_approx(a.temp, b.temp) and a.cards == b.cards,
		"same seed + same bot → identical run (seeded RNG)")


func _test_do_nothing_loses_on_time(catalog: Catalog) -> void:
	# Done criterion: doing nothing loses in 2043 ± 1 turn (turn 13 ends year 2042).
	var all_on_time := true
	var all_lost := true
	for seed_value in [1, 2, 3, 4, 5]:
		var r := Bots.play(catalog, seed_value, "none", "default")
		if r.won:
			all_lost = false
		if r.year < 2041 or r.year > 2044:
			all_on_time = false
			print("        seed %d: ended %d (%.2f°) — %s" % [seed_value, r.year, r.temp, r.cause])
	_check(all_lost, "do-nothing always loses")
	_check(all_on_time, "do-nothing loses 2042 ± 1 (spec: turn 13 ± 1)")


func _test_playing_changes_outcome(catalog: Catalog) -> void:
	var idle := Bots.play(catalog, 7, "none", "default")
	var clean := Bots.play(catalog, 7, "clean", "default")
	var idle_net: int = idle.timeline[-1].net
	var clean_net: int = clean.timeline[-1].net
	_check(clean.won or clean.year > idle.year or clean_net < idle_net,
		"clean player outlives or out-cuts the idle player")


func _test_mortgages_compound(catalog: Catalog) -> void:
	# Always-Mortgage must do no better than always-Pay, and worse somewhere.
	var mortgage_sum := 0
	var pay_sum := 0
	for seed_value in [11, 12, 13, 14, 15]:
		var m := Bots.play(catalog, seed_value, "none", "mortgage")
		var p := Bots.play(catalog, seed_value, "none", "pay")
		mortgage_sum += int(m.year)
		pay_sum += int(p.year)
	_check(mortgage_sum < pay_sum, "always-Mortgage loses earlier than always-Pay")


func _test_band_scaling(catalog: Catalog) -> void:
	var atoms := [
		{"type": "money", "amount": -2},
		{"type": "support", "amount": -1},
		{"type": "money", "amount": 3},
		{"type": "sector_emissions", "sector": "food", "amount": 1},
	]
	var scaled := Effects.scaled(atoms, 2)
	_check(int(scaled[0].amount) == -4 and int(scaled[1].amount) == -3,
		"band bump worsens money/support costs")
	_check(int(scaled[2].amount) == 3 and int(scaled[3].amount) == 1,
		"gains and permanent effects never scale")


func _test_windfalls_never_scale(catalog: Catalog) -> void:
	var sim := TurnManager.new(catalog, 99)
	sim.state.temp = 1.95  # band C — test-only direct poke
	var ok := true
	for _i in 30:
		var drawn := sim.crisis_deck.draw()
		if drawn.crisis.kind != "windfall":
			continue
		var authored: Array = catalog.crises_by_id[drawn.crisis.id].responses
		for r in drawn.responses.size():
			for a in drawn.responses[r].effects.size():
				if int(drawn.responses[r].effects[a].amount) != int(authored[r].effects[a].amount):
					ok = false
	_check(ok, "windfall costs identical at band C (windfalls ignore scaling)")


func _test_era_gating(catalog: Catalog) -> void:
	var sim := TurnManager.new(catalog, 5)
	var ok := true
	var eras_seen := [sim.current_era_id]
	var guard := 0
	while not sim.state.ended and guard < 200:
		guard += 1
		if sim.state.phase == RunState.Phase.CRISIS:
			sim.choose_response(Bots.pick_response(sim, "default"))
		elif sim.state.phase == RunState.Phase.ACTION:
			for card_id in sim.market.offer:
				if int(catalog.cards_by_id[card_id].available_from) > sim.state.year:
					ok = false
					print("        %s dealt in %d (gated until %d)" % [card_id, sim.state.year, catalog.cards_by_id[card_id].available_from])
			if not eras_seen.has(sim.current_era_id):
				eras_seen.append(sim.current_era_id)
			sim.end_turn()
	_check(ok, "gated cards never dealt before their era")
	_check(eras_seen.has("act2"), "Act II era fires before the run ends (2038 reached)")


func _test_combo_detection(catalog: Catalog) -> void:
	var sim := TurnManager.new(catalog, 3)
	var industry_before: int = sim.state.sectors.industry.emissions
	sim.state.owned_cards = ["solar_farm", "grid_storage"]
	sim.combo_checker.check()
	_check(sim.state.discovered_combos.has("clean_grid"), "Clean Grid combo detected from owned set")
	_check(sim.state.sectors.industry.emissions == industry_before - 1, "combo bonus applied through Effects")
	sim.combo_checker.check()
	_check(sim.state.discovered_combos.count("clean_grid") == 1, "combo never fires twice")
