extends TestBase
## The per-turn project market: deterministic weighted deal, offer
## consumption, the answer-guarantee rule, event bonus-card injection and
## on-draw emission spikes (docs/Phase_4/01, docs/Phase_5/01).


func _fresh() -> RunState:
	return RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])


func test_market_dealt_each_turn() -> void:
	var rs := _fresh()
	for i in 4:
		var deal := int(Tuning.s("MARKET_SIZE"))
		check(rs.market.size() >= deal and rs.market.size() <= deal + 2,
			"market holds %d offers (+bonus injections at most), got %d" % [deal, rs.market.size()])
		var seen := {}
		for id in rs.market:
			check(not seen.has(String(id)), "no duplicate offers")
			seen[String(id)] = true
			check(not rs.catalog.card(id).is_empty(), "every offer resolves in the catalog")
		rs.resolve_year()


func test_market_is_deterministic() -> void:
	var a := _fresh()
	var b := _fresh()
	for i in 5:
		eq(str(a.market), str(b.market), "same seed => same market (turn %d)" % a.turn_index())
		a.resolve_year()
		b.resolve_year()


func test_offer_must_be_in_market() -> void:
	var rs := _fresh()
	rs.money = 10000.0
	rs.influence = 100.0
	var outside: StringName = &""
	for c in rs.available_cards():
		if not rs.market.has(StringName(String(c["id"]))):
			outside = StringName(String(c["id"]))
			break
	check(outside != &"", "some available card is off-market this turn")
	eq(rs.can_play_reason(outside), &"not_in_market", "off-market card refused with its reason")
	eq(rs.play_card(outside), ERR_UNAVAILABLE, "off-market error code")


func test_playing_consumes_the_offer() -> void:
	var rs := _fresh()
	rs.money = 10000.0
	rs.pending_crises = []
	rs.force_market(["IND1", "TRA2", "RSP1"])
	eq(rs.play_card(&"IND1"), OK, "offer funded")
	check(not rs.market.has(&"IND1"), "funded offer leaves the market")
	eq(rs.can_play_reason(&"IND1"), &"not_in_market", "cannot fund the same offer twice")
	eq(rs.play_card(&"TRA2"), OK, "other offers unaffected")


func test_answer_guarantee_rule() -> void:
	var rs := _fresh()
	rs.pending_crises = [{"id": &"drought", "kind": "crisis", "region_id": rs.world[3].id,
		"answered": false, "answered_by": &""}]
	# A market with no water/food card cannot answer the drought...
	rs.market = [&"IND1", &"TRA2", &"IND2", &"SOC2"] as Array[StringName]
	rs._ensure_answer_offer(rs.available_cards())
	# ...so the last slot swaps for the cheapest answering card (RSP4, food, 25).
	eq(String(rs.market[3]), "RSP4", "cheapest answering card swapped in")
	var covered := false
	for id in rs.market:
		for tag in rs.catalog.card(id).get("tags", []):
			if ["water", "food"].has(String(tag)):
				covered = true
	check(covered, "every turn's crises stay answerable from the market")


func test_bonus_card_injection_gated_by_happiness() -> void:
	var rs := _fresh()
	# Design-doc reference: a record heat wave injects the Heatwave Response
	# Plan into the market - but only while Happiness >= 40.
	rs.pending_crises = [{"id": &"heat_wave", "kind": "crisis", "region_id": &"",
		"answered": false, "answered_by": &""}]
	rs.happiness = 60.0
	rs._deal_market()
	check(rs.market.has(&"HWP1"), "bonus card injected when the gate is met")
	check(rs.market_bonus.has(&"HWP1"), "flagged as a bonus injection")
	eq(rs.is_card_available(&"HWP1"), true, "bonus-only card exists while offered")
	# Below the gate: the plan never materializes.
	rs.happiness = 30.0
	rs._deal_market()
	check(not rs.market.has(&"HWP1"), "no bonus card below the resource gate")
	eq(rs.is_card_available(&"HWP1"), false, "bonus-only card unavailable off-market")


func test_bonus_card_answers_its_crisis() -> void:
	var rs := _fresh()
	rs.money = 10000.0
	var crisis := {"id": &"heat_wave", "kind": "crisis", "region_id": &"",
		"answered": false, "answered_by": &""}
	rs.pending_crises = [crisis]
	rs.happiness = 60.0
	rs._deal_market()
	eq(rs.play_card(&"HWP1"), OK, "injected plan is playable")
	eq(crisis["answered"], true, "and it answers the heat wave (health/relief tags)")


func test_on_draw_spike_cleared_when_answered() -> void:
	var rs := _fresh()
	rs.market_enforced = false
	rs.money = 10000.0
	var crisis := {"id": &"heat_wave", "kind": "crisis", "region_id": &"",
		"answered": false, "answered_by": &""}
	rs.pending_crises = [crisis]
	rs._apply_on_draw_effects()
	approx(rs.e_extra, 1.0, 1e-9, "the heat dome bakes in +1.0 Gt on draw")
	rs.play_card(&"RSP1")  # health/relief answers it
	rs.resolve_year()
	approx(rs.e_extra, 0.0, 1e-9, "answered: the spike dissipates before the ledger")


func test_on_draw_spike_permanent_when_ignored() -> void:
	var rs := _fresh()
	rs.market_enforced = false
	var crisis := {"id": &"heat_wave", "kind": "crisis", "region_id": &"",
		"answered": false, "answered_by": &""}
	rs.pending_crises = [crisis]
	rs._apply_on_draw_effects()
	rs.resolve_year()
	approx(rs.e_extra, 1.0, 1e-9, "ignored: the spike is permanent")


func test_market_weight_bias_exists() -> void:
	# Diplomacy levers carry raised market weights so the global lever stays
	# reachable; over many turns they must appear notably more often than a
	# same-rarity weight-1 card would.
	var appearances := 0
	var turns := 0
	for s in range(1, 8):
		var rs := RunState.new_run(WorldGen.generate(s, false), Catalog.load_default(), [])
		var guard := 20
		while rs.phase != RunState.Phase.ENDED and guard > 0:
			guard -= 1
			turns += 1
			if rs.market.has(&"DIP4") or rs.market.has(&"DIP5"):
				appearances += 1
			rs.resolve_year()
	check(appearances >= turns / 4, "an actor lever is offered at least every 4th turn (%d/%d)" % [appearances, turns])
