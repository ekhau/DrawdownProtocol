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
	_test_era_brief(catalog)
	_test_market_buy_updates_offer(catalog)
	_test_market_reroll(catalog)
	_test_buy_blockers(catalog)
	_test_combo_detection(catalog)
	_test_neutrality_projection(catalog)
	_test_breakeven_gross(catalog)

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


func _test_era_brief(catalog: Catalog) -> void:
	var act1: Dictionary = catalog.era_brief("act1")
	_check(act1.new_cards.size() == 19 and act1.floor_drops.is_empty(),
		"act1 brief: 19 starting cards, no floor drops to report")
	var act2: Dictionary = catalog.era_brief("act2")
	_check(act2.new_cards.size() == 13, "act2 brief: 13 cards unlock in 2038")
	_check(act2.floor_drops.size() == 4, "act2 brief: all four sector floors fall")
	var total_cards: int = act1.new_cards.size() + act2.new_cards.size() \
		+ catalog.era_brief("act3").new_cards.size()
	_check(total_cards == catalog.cards.size(), "era briefs partition the whole card pool")


func _test_market_buy_updates_offer(catalog: Catalog) -> void:
	var sim := TurnManager.new(catalog, 42)
	while sim.state.phase == RunState.Phase.CRISIS:
		sim.choose_response(Bots.pick_response(sim, "default"))
	sim.state.money = 99  # test-only poke: afford anything
	var pings := [0]
	sim.state.market_changed.connect(func(): pings[0] += 1)
	var first: String = sim.market.offer[0]
	_check(sim.buy_card(first), "buy accepted with ample funds")
	_check(not sim.market.offer.has(first), "bought card leaves the offer")
	_check(sim.market.offer.size() == int(catalog.config.market_size), "offer refills after buy")
	_check(pings[0] >= 1, "market_changed fires after buy (the UI repaint hook)")
	_check(not sim.buy_card(first), "ghost click on the bought card is rejected")


func _test_market_reroll(catalog: Catalog) -> void:
	var sim := TurnManager.new(catalog, 6)
	while sim.state.phase == RunState.Phase.CRISIS:
		sim.choose_response(Bots.pick_response(sim, "default"))
	sim.state.money = 99  # test-only poke
	var pings := [0]
	sim.state.market_changed.connect(func(): pings[0] += 1)
	_check(sim.reroll(), "first reroll of the year accepted")
	_check(pings[0] >= 1, "market_changed fires after reroll")
	_check(not sim.reroll(), "second reroll the same year rejected")
	sim.end_turn()
	if sim.state.phase == RunState.Phase.CRISIS:
		sim.choose_response(Bots.pick_response(sim, "default"))
	_check(sim.market.can_reroll(), "reroll available again next year")


func _test_buy_blockers(catalog: Catalog) -> void:
	var sim := TurnManager.new(catalog, 9)
	var money_card := ""
	var support_card := ""
	for c in catalog.cards:
		if money_card == "" and int(c.cost_money) > 0:
			money_card = c.id
		if support_card == "" and int(c.cost_support) > 0:
			support_card = c.id
	sim.state.money = 0  # test-only pokes from here on
	_check(sim.market.blockers(money_card).has("money"), "empty wallet blocks money-cost cards")
	sim.state.money = 99
	sim.state.support = int(catalog.cards_by_id[support_card].cost_support)
	_check(sim.market.blockers(support_card).has("support_floor"),
		"support exactly at cost is blocked (would collapse to 0)")
	sim.state.support = int(catalog.cards_by_id[support_card].cost_support) + 1
	_check(sim.market.blockers(support_card).is_empty(), "one spare support point unblocks the buy")


func _test_combo_detection(catalog: Catalog) -> void:
	var sim := TurnManager.new(catalog, 3)
	var industry_before: int = sim.state.sectors.industry.emissions
	sim.state.owned_cards = ["solar_farm", "grid_storage"]
	sim.combo_checker.check()
	_check(sim.state.discovered_combos.has("clean_grid"), "Clean Grid combo detected from owned set")
	_check(sim.state.sectors.industry.emissions == industry_before - 1, "combo bonus applied through Effects")
	sim.combo_checker.check()
	_check(sim.state.discovered_combos.count("clean_grid") == 1, "combo never fires twice")


func _test_neutrality_projection(catalog: Catalog) -> void:
	# Fresh run, nothing bought: no pace → mercury pinned at the lose temp.
	var idle := TurnManager.new(catalog, 21)
	var p := ClimateCalc.neutrality_projection(idle.state)
	_check(not p.reachable and is_equal_approx(p.temp, float(catalog.config.lose_temp)),
		"projection: no cuts → pinned at +2.0°")
	# Already structurally neutral: marker sits at today's temp, this year.
	var done := TurnManager.new(catalog, 22)
	done.state.add_absorption(50)
	var q := ClimateCalc.neutrality_projection(done.state)
	_check(q.reachable and is_equal_approx(q.temp, done.state.temp) and q.year == done.state.year,
		"projection: structural net ≤ 0 → marker at current temp")
	# Steady cuts (2/yr): reachable, warmer than today, cooler than the lose temp.
	var steady := TurnManager.new(catalog, 23)
	steady.state.add_sector_emissions("industry", -3)
	steady.state.snapshot()
	steady.state.turn = 2
	steady.state.add_sector_emissions("transport", -3)
	steady.state.snapshot()
	steady.state.turn = 3
	var r := ClimateCalc.neutrality_projection(steady.state)
	_check(r.reachable and r.temp > steady.state.temp and r.temp < float(catalog.config.lose_temp),
		"projection: steady cuts → net zero before +2.0°")
	_check(int(r.year) >= 2044, "projection respects era floors (net zero needs Act III)")


func _test_breakeven_gross(catalog: Catalog) -> void:
	# No pace: only fully-absorbed emissions are safe — the line sits on the green edge.
	var idle := TurnManager.new(catalog, 31)
	_check(ClimateCalc.breakeven_gross(idle.state) == idle.state.absorption,
		"2.0° line: no cuts → line sits at absorption")
	# Steady cuts push the line past absorption, and the line must agree with
	# the ◆ verdict: gross within the line ⟺ projection says reachable.
	var steady := TurnManager.new(catalog, 32)
	steady.state.add_sector_emissions("industry", -3)
	steady.state.snapshot()
	steady.state.turn = 2
	steady.state.add_sector_emissions("transport", -3)
	steady.state.snapshot()
	steady.state.turn = 3
	var line := ClimateCalc.breakeven_gross(steady.state)
	_check(line > steady.state.absorption, "2.0° line: steady cuts move the line past absorption")
	var reachable: bool = ClimateCalc.neutrality_projection(steady.state).reachable
	_check(reachable == (steady.state.gross_emissions() <= line),
		"2.0° line agrees with the ◆ projection verdict")
