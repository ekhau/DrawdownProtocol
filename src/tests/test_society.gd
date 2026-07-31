extends TestBase
## T9-P4 (resilience multipliers), T10-P4 (social crisis formula and income
## penalties), T7-P5 (social crisis flatness). Per-turn values (1 turn = 5 yr).


func test_income_penalties() -> void:
	eq(float(SocietyCalc.income(60.0, 0)["amount"]), 250.0, "baseline income per turn")
	eq(float(SocietyCalc.income(60.0, 4)["amount"]), 410.0, "+40 per ally")
	eq(float(SocietyCalc.income(39.9, 0)["amount"]), 187.5, "x0.75 below 40")
	eq(SocietyCalc.income(39.9, 0)["penalty"], &"h_below_40", "penalty id 40")
	eq(float(SocietyCalc.income(40.0, 0)["amount"]), 250.0, "no penalty at exactly 40")
	eq(float(SocietyCalc.income(24.9, 0)["amount"]), 125.0, "x0.5 below 25 (strongest only)")
	eq(SocietyCalc.income(24.9, 0)["penalty"], &"h_below_25", "penalty id 25")


func test_influence_income() -> void:
	eq(SocietyCalc.influence_income(0, false), 6.0, "base influence per turn")
	eq(SocietyCalc.influence_income(3, false), 12.0, "+2 per ally")
	eq(SocietyCalc.influence_income(3, true), 14.0, "+2 media")


func test_resilience_and_mult() -> void:  # T9-P4
	eq(SocietyCalc.resilience(0.0, 0.0), 0.0, "R at zero")
	eq(SocietyCalc.resilience(100.0, 60.0), 100.0, "R capped at 100")
	eq(SocietyCalc.resilience(50.0, 30.0), 50.0, "R = 0.4H + adapt")
	eq(SocietyCalc.damage_mult(0.0, 0.0), 1.0, "R=0 => x1.0")
	eq(SocietyCalc.damage_mult(50.0, 30.0), 0.75, "R=50 => x0.75")
	eq(SocietyCalc.damage_mult(100.0, 60.0), 0.5, "R=100 => x0.5 (halved)")


func test_happiness_drift() -> void:
	var d := SocietyCalc.happiness_drift(100.0, 0)
	eq(float(d["co_benefit"]), 4.0, "max co-benefit at full transition (per turn)")
	eq(float(d["stress"]), 0.0, "no stress in band 0")
	d = SocietyCalc.happiness_drift(0.0, 2)
	eq(float(d["co_benefit"]), 0.0, "no co-benefit at 0%")
	eq(float(d["stress"]), 4.0, "Overshoot II stress per turn")


func _event_def(id: String) -> Dictionary:
	for ev in Catalog.load_default().events:
		if String(ev["id"]) == id:
			return ev
	return {}


func test_crisis_draw_weights() -> void:  # T10-P4
	var social := _event_def("social_crisis")
	approx(SocietyCalc.crisis_weight(social, 0, 60.0, false), 0.5, 1e-9, "band 0 base weight")
	approx(SocietyCalc.crisis_weight(social, 2, 60.0, false), 1.2, 1e-9, "band 2 weight")
	approx(SocietyCalc.crisis_weight(social, 0, 39.9, false), 1.5, 1e-9, "low happiness x3")
	approx(SocietyCalc.crisis_weight(social, 0, 40.0, false), 0.5, 1e-9, "threshold at exactly 40")
	approx(SocietyCalc.crisis_weight(social, 0, 39.9, true), 0.75, 1e-9, "media halves")
	var heat := _event_def("heat_wave")
	approx(SocietyCalc.crisis_weight(heat, 1, 20.0, true), 1.4, 1e-9,
		"no weight_mods: happiness and media ignored")


func test_combo_mult() -> void:
	approx(SocietyCalc.combo_mult(0), 1.0, 1e-9, "first combo x1.0")
	approx(SocietyCalc.combo_mult(5), 1.5, 1e-9, "chain 5 => x1.5")
	approx(SocietyCalc.combo_mult(10), 2.0, 1e-9, "chain cap => x2.0")
	approx(SocietyCalc.combo_mult(25), 2.0, 1e-9, "beyond cap stays x2.0")


func _forced_crisis(rs: RunState, id: String, region: RegionData) -> Dictionary:
	var crisis := {
		"id": StringName(id), "kind": "crisis",
		"region_id": region.id if region != null else &"",
		"answered": false, "answered_by": &"",
	}
	rs.pending_crises = [crisis]
	return crisis


func test_social_crisis_flat_damage() -> void:  # T7-P5
	# scaled_by_resilience: false => identical damages at R=0 and R=100.
	for setup in [[0.0, 0.0], [100.0, 60.0]]:
		var rs := RunState.new_run(WorldGen.generate(11, true), Catalog.load_default(), [])
		rs.happiness = setup[0]
		rs.adapt = setup[1]
		rs.influence = 50.0
		rs.money = 500.0
		var crisis := _forced_crisis(rs, "social_crisis", rs.world[3])
		rs._apply_crisis_hit(crisis, SocietyCalc.damage_mult(rs.happiness, rs.adapt))
		var damages: Dictionary = crisis["damages"]
		eq(float(damages["influence"]), 12.0, "flat influence damage at R=%s" % rs.resilience())
		eq(float(damages["money"]), 30.0, "flat money damage at R=%s" % rs.resilience())


func test_scaled_crisis_damage() -> void:  # T9-P4 applied
	var rs := RunState.new_run(WorldGen.generate(11, true), Catalog.load_default(), [])
	rs.happiness = 100.0
	rs.adapt = 60.0  # R = 100 => mult 0.5
	rs.money = 500.0
	var crisis := _forced_crisis(rs, "heat_wave", rs.world[3])
	rs._apply_crisis_hit(crisis, SocietyCalc.damage_mult(rs.happiness, rs.adapt))
	var damages: Dictionary = crisis["damages"]
	eq(float(damages["money"]), 20.0, "heat money damage halved at R=100")
	eq(float(damages["happiness"]), 3.0, "heat happiness damage halved at R=100")
