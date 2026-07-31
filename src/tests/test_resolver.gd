extends TestBase
## T4-P4 (validation matrix), T5-P4 (stacking), T6-P4 (waiver precedence),
## T5-P5 (multi-play turn limit), T12-P5 (fire-discount path).
## Op-level suites disable market enforcement to compose exact scenarios;
## market behavior itself is covered by test_market.gd.


func _fresh() -> RunState:
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	rs.market_enforced = false
	return rs


func test_validation_matrix() -> void:  # T4-P4
	var rs := _fresh()
	rs.money = 10.0
	eq(rs.can_play_reason(&"IND1"), &"no_money", "insufficient money")
	eq(rs.can_play(&"IND1"), ERR_CANT_ACQUIRE_RESOURCE, "money error code")
	rs.money = 500.0
	rs.influence = 5.0
	eq(rs.can_play_reason(&"DIP1"), &"no_influence", "insufficient influence")
	eq(rs.can_play_reason(&"DIP2"), &"no_influence", "DIP2 influence checked before allies")
	rs.influence = 50.0
	eq(rs.can_play_reason(&"DIP2"), &"locked_allies", "DIP2 needs 2 allies")
	eq(rs.can_play(&"DIP2"), ERR_UNCONFIGURED, "allies error code")
	eq(rs.can_play_reason(&"XXX9"), &"unknown_card", "unknown card")


func test_multi_play_and_turn_limit() -> void:  # T5-P5 (rework)
	var rs := _fresh()
	rs.money = 10000.0
	eq(rs.play_card(&"IND1"), OK, "first card accepted")
	eq(rs.play_card(&"TRA2"), OK, "second card accepted the same turn (multi-play)")
	eq(rs.cards_played_this_turn(), 2, "two plays counted")
	eq(rs.play_card(&"RSP1"), OK, "third card")
	eq(rs.play_card(&"RSP2"), OK, "fourth card")
	eq(rs.play_card(&"RSP3"), OK, "fifth card")
	eq(rs.can_play_reason(&"RSP4"), &"turn_limit", "sixth play blocked by the turn limit")
	eq(rs.play_card(&"RSP4"), ERR_UNAVAILABLE, "turn-limit error code")
	var rec := rs.resolve_year()
	eq(rec.actions.size(), 5, "five actions in the record")
	eq(rs.cards_played_this_turn(), 0, "limit resets next turn")
	rs.market_enforced = false
	eq(rs.can_play_reason(&"RSP4"), &"ok", "playable again next turn")


func test_locked_card() -> void:  # deck growth gate
	var rs := _fresh()
	rs.money = 10000.0
	eq(rs.can_play_reason(&"RSP6"), &"card_locked", "unlockable card starts locked")
	eq(rs.play_card(&"RSP6"), ERR_UNCONFIGURED, "locked card rejected")
	check(not rs.available_cards().any(func(c: Dictionary) -> bool:
		return String(c["id"]) == "RSP6"), "locked card not in the available pool")


func test_meta_lesson_card_gate() -> void:
	# SOC4 exists only for players who lost a run to the revolt.
	var rs := _fresh()
	rs.money = 10000.0
	eq(rs.can_play_reason(&"SOC4"), &"card_locked", "meta card locked without the lesson")
	var gen := WorldGen.generate(2030, true)
	var rs2 := RunState.new_run(gen, Catalog.load_default(), [], &"", ["SOC4"])
	rs2.market_enforced = false
	rs2.money = 10000.0
	eq(rs2.can_play_reason(&"SOC4"), &"ok", "meta card available once the lesson is learned")
	var h0 := rs2.happiness
	rs2.pending_crises = []
	rs2.play_card(&"SOC4")
	eq(rs2.happiness, h0 + 6.0, "Public Support Fund softens the happiness trap")


func test_media_duplicate() -> void:
	var rs := _fresh()
	rs.play_card(&"SOC1")
	eq(rs.can_play_reason(&"SOC1"), &"media_active", "media cannot stack, same turn")
	rs.resolve_year()
	rs.market_enforced = false
	eq(rs.can_play_reason(&"SOC1"), &"media_active", "media cannot stack, next turn")
	eq(rs.can_play(&"SOC1"), ERR_ALREADY_IN_USE, "media error code")


func test_cap_stacking() -> void:  # T5-P4
	var rs := _fresh()
	var ind := rs.sector(&"ind")
	ind.progress = 65.0
	rs.money = 10000.0
	rs.play_card(&"IND2")  # +16 requested, cap 70
	var eff: Dictionary = rs.last_action_effects()[0]
	eq(float(eff["applied"]), 5.0, "progress clamps at the 70 cap")
	eq(float(eff["requested"]), 16.0, "requested amount reported")
	eq(ind.progress, 70.0, "at cap")
	eq(rs.can_play_reason(&"IND2"), &"capped", "tech card blocked at cap, same turn")
	eq(rs.can_play_reason(&"IND3"), &"ok", "sufficiency card still playable at cap")
	rs.play_card(&"IND3")  # lifts cap then +13, same turn
	eq(ind.suff_played, true, "sufficiency flag set")
	eq(ind.progress, 83.0, "cap lifted before adding")
	rs.resolve_year()
	rs.market_enforced = false
	eq(rs.can_play_reason(&"IND3"), &"ok", "sufficiency card replayable until 100")
	ind.progress = 100.0
	eq(rs.can_play_reason(&"IND3"), &"capped", "blocked at 100")


func test_joint_progress_clamps() -> void:  # T5-P4
	var rs := _fresh()
	rs.money = 10000.0
	rs.influence = 100.0
	rs.allies = 2
	rs.sector(&"ind").progress = 68.0
	rs.play_card(&"DIP2")
	var eff: Dictionary = rs.last_action_effects()[0]
	eq(float(eff["applied_ind"]), 2.0, "joint on near-capped sector clamps (requested 8, applied 2)")
	eq(float(eff["applied_tra"]), 8.0, "uncapped sector gets full amount")
	eq(float(eff["requested"]), 8.0, "requested reported")


func test_adapt_clamp() -> void:  # T5-P4 / C2 clarification
	var rs := _fresh()
	rs.money = 10000.0
	rs.adapt = 55.0
	rs.play_card(&"ADP1")  # +15 requested
	eq(rs.adapt, 60.0, "adapt clamps at 60")


func test_card_rewards_granted() -> void:  # cost/reward economy
	var rs := _fresh()
	rs.money = 1000.0
	rs.pending_crises = []  # isolate: no crisis response rewards
	var i0 := rs.influence
	rs.play_card(&"RSP1")  # 30M, rewards +3 influence
	eq(rs.money, 970.0, "cost paid")
	eq(rs.influence, i0 + 3.0, "influence reward granted")
	var rec_action: Dictionary = rs._turn_actions.back()
	eq(float(rec_action["rewards"]["influence"]), 3.0, "reward recorded on the action")


func test_happiness_cost_card() -> void:  # the carbon levy dilemma
	var rs := _fresh()
	rs.pending_crises = []
	var h0 := rs.happiness
	var m0 := rs.money
	var p0 := rs.sector(&"ind").progress
	eq(rs.play_card(&"IND5"), OK, "levy playable")
	eq(rs.happiness, h0 - 6.0, "paid in happiness, not money")
	eq(rs.money, m0 + 35.0, "the levy RAISES money")
	eq(rs.sector(&"ind").progress, p0 + 14.0, "and buys a deep industrial cut")
	rs.resolve_year()
	rs.market_enforced = false
	rs.happiness = 5.0
	eq(rs.can_play_reason(&"IND5"), &"no_happiness", "cannot tax an exhausted public")


func test_waiver_precedence() -> void:  # T6-P4, clarification C1
	# Neither flag: penalty applies.
	var rs := _fresh()
	rs.money = 10000.0
	rs.pending_crises = []
	var h0 := rs.happiness
	rs.play_card(&"TRA3")  # -3 waivable
	eq(rs.happiness, h0 - 3.0, "no waiver: penalty applies")
	# Media only.
	rs = _fresh()
	rs.money = 10000.0
	rs.pending_crises = []
	rs.media = true
	h0 = rs.happiness
	rs.play_card(&"TRA3")
	eq(rs.happiness, h0, "media waives the penalty")
	eq(rs.window, false, "window untouched")
	# Window only.
	rs = _fresh()
	rs.money = 10000.0
	rs.pending_crises = []
	rs.window = true
	h0 = rs.happiness
	rs.play_card(&"TRA3")
	eq(rs.happiness, h0, "window waives the penalty")
	eq(rs.window, false, "window consumed")
	# Both: media wins, window survives (C1).
	rs = _fresh()
	rs.money = 10000.0
	rs.pending_crises = []
	rs.media = true
	rs.window = true
	h0 = rs.happiness
	rs.play_card(&"TRA3")
	eq(rs.happiness, h0, "waived with both flags")
	eq(rs.window, true, "window NOT consumed when media covers it (C1)")
	# Positive happiness never waived.
	rs = _fresh()
	rs.money = 10000.0
	rs.pending_crises = []
	rs.media = true
	h0 = rs.happiness
	rs.play_card(&"TRA1")  # +2 not waivable
	eq(rs.happiness, h0 + 2.0, "positive happiness applies with media active")


func test_fire_discount() -> void:  # T12-P5, amendment A4
	var rs := _fresh()
	rs.money = 10000.0
	rs.pending_crises = []
	rs.fire_discount = true
	eq(rs.effective_cost_money(&"SNK1"), 35.0, "restoration card half price (preview)")
	eq(rs.effective_cost_money(&"SNK2"), 45.0, "second restoration card half price")
	eq(rs.effective_cost_money(&"IND1"), 90.0, "non-restoration card unaffected")
	var m0 := rs.money
	rs.play_card(&"SNK1")
	eq(m0 - rs.money, 35.0, "paid price equals preview price")
	eq(rs.fire_discount, false, "discount consumed on play")
	rs.resolve_year()
	rs.market_enforced = false
	rs.pending_crises = []
	eq(rs.effective_cost_money(&"SNK1"), 70.0, "price back to normal")


func test_ally_targeting() -> void:
	var rs := _fresh()
	rs.money = 10000.0
	rs.influence = 100.0
	var target := rs.neutral_regions()[3]
	eq(rs.play_card(&"DIP1", target.id), OK, "explicit target accepted")
	eq(rs.allies, 1, "ally count up")
	eq(target.ally_state, WorldEnums.AllyState.ALLY, "target flipped to ally")
	eq(rs.play_card(&"DIP1", target.id), ERR_INVALID_PARAMETER, "non-neutral target rejected")
	eq(rs.allies, 1, "no cost paid on invalid target")
	var home := rs.world[0]
	eq(rs.play_card(&"DIP1", home.id), ERR_INVALID_PARAMETER, "player home cannot be targeted")


func test_pass_is_recorded() -> void:
	var rs := _fresh()
	var rec := rs.resolve_year()
	eq(rec.actions.size(), 0, "passing plays no cards")
	check("No cards funded - funds banked." in rec.log_lines, "pass logged as an explicit decision")
