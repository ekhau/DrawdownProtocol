extends TestBase
## The combo system: tag-multiset matching, once-per-turn firing, immediate
## payoff, chain growth and decay, and the chain reward multiplier.


func _fresh() -> RunState:
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	rs.money = 10000.0
	rs.influence = 100.0
	rs.pending_crises = []  # isolate combos from crisis response rewards
	return rs


func test_pair_combo_fires() -> void:
	var rs := _fresh()
	rs.play_card(&"TRA2")  # mobility
	eq(rs.combos_total, 0, "half a combo is no combo")
	var m0 := rs.money
	rs.play_card(&"IND1")  # energy -> Green Corridor
	eq(rs.combos_total, 1, "Green Corridor fired")
	eq(rs.combo_chain, 1, "chain up")
	approx(rs.money, m0 - 80.0 + 25.0, 1e-9, "combo reward +25 at x1.0")
	var fired: Dictionary = rs.turn_combos()[0]
	eq(String(fired["id"]), "green_corridor", "combo id recorded")
	approx(float(fired["mult"]), 1.0, 1e-9, "first combo multiplies x1.0")


func test_combo_once_per_turn_recharges_next_year() -> void:
	var rs := _fresh()
	rs.play_card(&"TRA2")
	rs.play_card(&"IND1")
	rs.play_card(&"IND2")  # more energy: pair already complete
	eq(rs.combos_total, 1, "a combo fires at most once per turn")
	rs.resolve_year()
	rs.pending_crises = []
	rs.play_card(&"TRA2")
	var m0 := rs.money
	rs.play_card(&"IND1")
	eq(rs.combos_total, 2, "same combo fires again next year")
	eq(rs.combo_chain, 2, "chain builds across years")
	approx(rs.money, m0 - 80.0 + 25.0 * 1.1, 1e-6, "chain 1 => x1.1 reward")


func test_single_card_cannot_combo() -> void:
	var rs := _fresh()
	rs.play_card(&"TRA1")  # sufficiency+mobility+health on one card
	eq(rs.combos_total, 0, "no combo from a single card's tags")


func test_combo_effects_applied() -> void:
	var rs := _fresh()
	var a0 := rs.absorption
	rs.play_card(&"SNK1")  # restoration+forest
	rs.play_card(&"RSP2")  # water -> Water Cycle: sink_now 0.15 (+0.1 from RSP2)
	eq(rs.combos_total, 1, "Water Cycle fired")
	approx(rs.absorption, a0 + 0.1 + 0.15, 1e-9, "combo sink effect applied on top of the card")


func test_three_tag_combo() -> void:
	var rs := _fresh()
	rs.allies = 2
	rs.play_card(&"DIP2")  # treaty
	rs.play_card(&"IND1")  # energy
	eq(rs.combos_total, 0, "grand bargain needs civic too")
	rs.play_card(&"SOC1")  # civic -> Grand Bargain
	eq(rs.combos_total, 1, "three-tag combo fired")
	eq(rs.kp_earned, 1, "knowledge reward flows to in-run KP")


func test_chain_decay_on_comboless_year() -> void:
	var rs := _fresh()
	rs.play_card(&"TRA2")
	rs.play_card(&"IND1")
	eq(rs.combo_chain, 1, "chain 1 after the combo")
	rs.resolve_year()  # comboless years decay the chain
	rs.pending_crises = []
	rs.resolve_year()
	eq(rs.combo_chain, 0, "chain decays by 1 on a comboless year (min 0)")
	rs.resolve_year()
	eq(rs.combo_chain, 0, "never below zero")


func test_chain_cap_multiplier() -> void:
	var rs := _fresh()
	rs.combo_chain = 25
	var m0 := rs.money
	rs.play_card(&"TRA2")
	rs.play_card(&"IND1")
	approx(rs.money, m0 - 140.0 - 80.0 + 25.0 * 2.0, 1e-6,
		"deep chain caps the reward multiplier at x2.0")
	eq(rs.combo_chain, 26, "chain keeps counting past the cap")


func test_knowledge_reward_not_scaled() -> void:
	var rs := _fresh()
	rs.combo_chain = 10
	rs.allies = 2
	rs.play_card(&"DIP2")
	rs.play_card(&"IND1")
	rs.play_card(&"SOC1")
	eq(rs.kp_earned, 1, "knowledge rewards stay flat under the chain multiplier")


func test_combos_unlock_cards() -> void:
	var rs := _fresh()
	for i in 4:
		rs.play_card(&"TRA2")
		rs.play_card(&"IND1")
		rs.resolve_year()
		rs.pending_crises = []
	eq(rs.combos_total, 4, "four combos over four years")
	check(rs.unlocked_card_ids.has(&"AGR3"), "Food Commons unlocked at 4 combos")