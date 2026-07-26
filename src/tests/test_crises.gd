extends TestBase
## The crisis loop: 3-per-year draw, tag-matched answering, contained vs
## struck resolution, opportunity events, and the crises_answered unlock path.


func _fresh() -> RunState:
	return RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])


func _force(rs: RunState, id: String, region: RegionData, kind: String = "crisis") -> Dictionary:
	var crisis := {
		"id": StringName(id), "kind": kind,
		"region_id": region.id if region != null else &"",
		"answered": false, "answered_by": &"",
	}
	rs.pending_crises = [crisis]
	return crisis


func test_three_crises_drawn_each_year() -> void:
	var rs := _fresh()
	for i in 5:
		eq(rs.pending_crises.size(), 3, "exactly 3 crises drawn (year %d)" % rs.year)
		var seen := {}
		for crisis in rs.pending_crises:
			check(not seen.has(String(crisis["id"])), "no duplicate crisis in one year")
			seen[String(crisis["id"])] = true
			check(not rs.crisis_def(crisis["id"]).is_empty(), "drawn id resolves in the catalog")
			check(["crisis", "opportunity"].has(String(crisis["kind"])), "drawable kinds only")
		rs.resolve_year()


func test_draw_is_deterministic() -> void:
	var a := _fresh()
	var b := _fresh()
	for i in 10:
		eq(str(a.pending_crises), str(b.pending_crises), "same seed => same draw (year %d)" % a.year)
		a.resolve_year()
		b.resolve_year()


func test_answering_contains_the_crisis() -> void:
	var rs := _fresh()
	rs.money = 10000.0
	var region := rs.world[4]
	var crisis := _force(rs, "drought", region)
	var a0 := rs.absorption
	var i0 := rs.influence
	rs.play_card(&"RSP2")  # water tag answers drought; +0.1 sink; +10M reward
	eq(crisis["answered"], true, "crisis flagged answered")
	eq(crisis["answered_by"], &"RSP2", "answering card recorded")
	eq(rs.crises_answered_total, 1, "answer counter up")
	approx(rs.absorption, a0 + 0.1, 1e-9, "card effect applied")
	approx(rs.influence, i0 + 2.0, 1e-9, "drought response reward: +2 influence")
	var h0 := rs.happiness
	var rec := rs.resolve_year()
	eq(rec.crises[0]["answered"], true, "record keeps the answered state")
	check(not rec.crises[0].has("damages"), "no damage from an answered crisis")
	check(rs.happiness >= h0 - 0.001, "no happiness hit from the contained drought")


func test_unanswered_crisis_strikes_with_rider() -> void:
	var rs := _fresh()
	var forested: RegionData = null
	for r in rs.world:
		if r.forested:
			forested = r
	_force(rs, "mega_fire", forested)
	var a0 := rs.absorption
	var scars0 := forested.scars.size()
	var rec := rs.resolve_year()
	var crisis: Dictionary = rec.crises[0]
	check(crisis.has("damages"), "unanswered crisis applied damages")
	check(rs.absorption < a0, "absorption lost to the fire")
	eq(rs.fires, 1, "fire counter up")
	eq(rs.fire_discount, true, "opportunity rider set (the door opens on a hit)")
	eq(forested.scars.size(), scars0 + 1, "scar appended")


func test_answered_crisis_opens_no_door() -> void:
	var rs := _fresh()
	rs.money = 10000.0
	var forested: RegionData = null
	for r in rs.world:
		if r.forested:
			forested = r
	_force(rs, "mega_fire", forested)
	rs.play_card(&"SNK1")  # forest tag answers the fire
	rs.resolve_year()
	eq(rs.fires, 0, "contained fire never burns")
	eq(rs.fire_discount, false, "no rebuild discount without ashes")


func test_first_matching_crisis_gets_the_card() -> void:
	var rs := _fresh()
	rs.money = 10000.0
	var region := rs.world[3]
	var first := {"id": &"drought", "kind": "crisis", "region_id": region.id,
		"answered": false, "answered_by": &""}
	var second := {"id": &"crop_failure", "kind": "crisis", "region_id": region.id,
		"answered": false, "answered_by": &""}
	rs.pending_crises = [first, second]
	rs.play_card(&"RSP2")  # water matches both; draw order wins
	eq(first["answered"], true, "first crisis answered")
	eq(second["answered"], false, "second still open")
	rs.play_card(&"AGR2")  # food/water answers the second
	eq(second["answered"], true, "second answered by the next card")
	eq(rs.crises_answered_total, 2, "both counted")


func test_opportunity_seized_and_missed() -> void:
	var rs := _fresh()
	rs.money = 10000.0
	_force(rs, "green_investment_wave", null, "opportunity")
	var m0 := rs.money
	rs.play_card(&"IND1")  # energy tag seizes the wave
	approx(rs.money, m0 - 80.0 + 30.0, 1e-9, "seized: +30 funds on top of the card")
	var rec := rs.resolve_year()
	eq(rec.crises[0]["answered"], true, "seized recorded")
	# Missed: nothing happens, nothing lost.
	rs = _fresh()
	_force(rs, "green_investment_wave", null, "opportunity")
	var h0 := rs.happiness
	var money0 := rs.money
	rec = rs.resolve_year()
	eq(rec.crises[0]["answered"], false, "missed recorded")
	check(not rec.crises[0].has("damages"), "a missed opportunity never damages")
	check(rs.money >= money0 - 0.001, "no money lost")
	check(rs.happiness >= h0 - 1.001, "only drift touches happiness")  # band stress possible


func test_crises_answered_unlock() -> void:
	var rs := _fresh()
	rs.money = 100000.0
	var region := rs.world[3]
	for i in 4:
		_force(rs, "drought", region)
		rs.play_card(&"RSP2")
		rs.resolve_year()
		rs.pending_crises = []
	eq(rs.crises_answered_total, 4, "four crises answered")
	check(rs.unlocked_card_ids.has(&"RSP6"), "RSP6 unlocked at 4 answers")
	eq(rs.can_play_reason(&"RSP6"), &"ok", "unlocked card is playable")
	var found := false
	for rec in rs.records:
		if rec.cards_unlocked.has(&"RSP6"):
			found = true
	check(found, "unlock recorded in a turn record")


func test_social_crisis_ally_loss_and_window() -> void:
	var rs := _fresh()
	rs.money = 10000.0
	rs.influence = 100.0
	var target := rs.neutral_regions()[0]
	rs.play_card(&"DIP1", target.id)
	rs.resolve_year()
	_force(rs, "social_crisis", target)
	var i0 := rs.influence
	rs.resolve_year()
	eq(rs.allies, 0, "targeted ally lost to the unanswered social crisis")
	eq(target.ally_state, WorldEnums.AllyState.NEUTRAL, "region back to neutral")
	eq(rs.window, true, "policy window rider set")
	check(rs.influence < i0, "influence damage applied")