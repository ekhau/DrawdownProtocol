extends TestBase
## T4-P4 (validation matrix), T5-P4 (stacking), T6-P4 (waiver precedence),
## T5-P5 (one-card lock), T12-P5 (fire-discount path).


func _fresh() -> RunState:
	return RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])


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


func test_one_card_lock() -> void:  # T4-P4 / T5-P5
	var rs := _fresh()
	rs.money = 500.0
	eq(rs.play_card(&"IND1"), OK, "first card accepted")
	eq(rs.can_play_reason(&"TRA1"), &"action_taken", "second card blocked")
	eq(rs.play_card(&"TRA1"), ERR_UNAVAILABLE, "second play rejected")
	var rec := rs.resolve_year()
	eq(rec.action, &"IND1", "exactly one action in the record")
	eq(rs.action_taken, false, "lock released next year")


func test_media_duplicate() -> void:
	var rs := _fresh()
	rs.play_card(&"SOC1")
	rs.resolve_year()
	eq(rs.can_play_reason(&"SOC1"), &"media_active", "media cannot stack")
	eq(rs.can_play(&"SOC1"), ERR_ALREADY_IN_USE, "media error code")


func test_cap_stacking() -> void:  # T5-P4
	var rs := _fresh()
	var ind := rs.sector(&"ind")
	ind.progress = 65.0
	rs.money = 10000.0
	rs.play_card(&"IND2")  # +15 requested, cap 70
	var eff: Dictionary = rs.pending_effects()[0]
	eq(float(eff["applied"]), 5.0, "progress clamps at the 70 cap")
	eq(float(eff["requested"]), 15.0, "requested amount reported")
	eq(ind.progress, 70.0, "at cap")
	eq(rs.can_play_reason(&"IND2"), &"action_taken", "turn locked after play")
	rs.resolve_year()
	eq(rs.can_play_reason(&"IND2"), &"capped", "tech card blocked at cap")
	eq(rs.can_play_reason(&"IND3"), &"ok", "sufficiency card still playable at cap")
	rs.play_card(&"IND3")  # lifts cap then +10
	eq(ind.suff_played, true, "sufficiency flag set")
	eq(ind.progress, 80.0, "cap lifted before adding")
	rs.resolve_year()
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
	var eff: Dictionary = rs.pending_effects()[0]
	eq(float(eff["applied_ind"]), 2.0, "joint on near-capped sector clamps (requested 6, applied 2)")
	eq(float(eff["applied_tra"]), 6.0, "uncapped sector gets full amount")
	eq(float(eff["requested"]), 6.0, "requested reported")


func test_adapt_clamp() -> void:  # T5-P4 / C2 clarification
	var rs := _fresh()
	rs.money = 10000.0
	rs.adapt = 55.0
	rs.play_card(&"ADP1")  # +15 requested
	eq(rs.adapt, 60.0, "adapt clamps at 60")


func test_waiver_precedence() -> void:  # T6-P4, clarification C1
	# Neither flag: penalty applies.
	var rs := _fresh()
	rs.money = 10000.0
	var h0 := rs.happiness
	rs.play_card(&"TRA3")  # -3 waivable
	eq(rs.happiness, h0 - 3.0, "no waiver: penalty applies")
	# Media only.
	rs = _fresh()
	rs.money = 10000.0
	rs.media = true
	h0 = rs.happiness
	rs.play_card(&"TRA3")
	eq(rs.happiness, h0, "media waives the penalty")
	eq(rs.window, false, "window untouched")
	# Window only.
	rs = _fresh()
	rs.money = 10000.0
	rs.window = true
	h0 = rs.happiness
	rs.play_card(&"TRA3")
	eq(rs.happiness, h0, "window waives the penalty")
	eq(rs.window, false, "window consumed")
	# Both: media wins, window survives (C1).
	rs = _fresh()
	rs.money = 10000.0
	rs.media = true
	rs.window = true
	h0 = rs.happiness
	rs.play_card(&"TRA3")
	eq(rs.happiness, h0, "waived with both flags")
	eq(rs.window, true, "window NOT consumed when media covers it (C1)")
	# Positive happiness never waived.
	rs = _fresh()
	rs.money = 10000.0
	rs.media = true
	h0 = rs.happiness
	rs.play_card(&"TRA1")  # +2 not waivable
	eq(rs.happiness, h0 + 2.0, "positive happiness applies with media active")


func test_fire_discount() -> void:  # T12-P5, amendment A4
	var rs := _fresh()
	rs.money = 10000.0
	rs.fire_discount = true
	eq(rs.effective_cost_money(&"SNK1"), 35.0, "restoration card half price (preview)")
	eq(rs.effective_cost_money(&"SNK2"), 45.0, "second restoration card half price")
	eq(rs.effective_cost_money(&"IND1"), 80.0, "non-restoration card unaffected")
	var m0 := rs.money
	rs.play_card(&"SNK1")
	eq(m0 - rs.money, 35.0, "paid price equals preview price")
	eq(rs.fire_discount, false, "discount consumed on play")
	rs.resolve_year()
	eq(rs.effective_cost_money(&"SNK1"), 70.0, "price back to normal")


func test_ally_targeting() -> void:
	var rs := _fresh()
	rs.money = 10000.0
	rs.influence = 100.0
	var target := rs.neutral_regions()[3]
	eq(rs.play_card(&"DIP1", target.id), OK, "explicit target accepted")
	eq(rs.allies, 1, "ally count up")
	eq(target.ally_state, WorldEnums.AllyState.ALLY, "target flipped to ally")
	rs.resolve_year()
	eq(rs.play_card(&"DIP1", target.id), ERR_INVALID_PARAMETER, "non-neutral target rejected")
	eq(rs.allies, 1, "no cost paid on invalid target")
	var home := rs.world[0]
	eq(rs.play_card(&"DIP1", home.id), ERR_INVALID_PARAMETER, "player home cannot be targeted")


func test_pass_is_recorded() -> void:
	var rs := _fresh()
	var rec := rs.resolve_year()
	eq(rec.action, &"pass", "passing is an explicit logged decision")
