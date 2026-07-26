extends TestBase
## T9-P4 (resilience multipliers), T10-P4 (social crisis formula and income
## penalties), T7-P5 (social crisis flatness).


func test_income_penalties() -> void:
	eq(float(SocietyCalc.income(60.0, 0)["amount"]), 100.0, "baseline income")
	eq(float(SocietyCalc.income(60.0, 4)["amount"]), 180.0, "+20 per ally")
	eq(float(SocietyCalc.income(39.9, 0)["amount"]), 75.0, "x0.75 below 40")
	eq(SocietyCalc.income(39.9, 0)["penalty"], &"h_below_40", "penalty id 40")
	eq(float(SocietyCalc.income(40.0, 0)["amount"]), 100.0, "no penalty at exactly 40")
	eq(float(SocietyCalc.income(24.9, 0)["amount"]), 50.0, "x0.5 below 25 (strongest only)")
	eq(SocietyCalc.income(24.9, 0)["penalty"], &"h_below_25", "penalty id 25")


func test_influence_income() -> void:
	eq(SocietyCalc.influence_income(0, false), 2.0, "base influence")
	eq(SocietyCalc.influence_income(3, false), 5.0, "+1 per ally")
	eq(SocietyCalc.influence_income(3, true), 6.0, "+1 media")


func test_resilience_and_mult() -> void:  # T9-P4
	eq(SocietyCalc.resilience(0.0, 0.0), 0.0, "R at zero")
	eq(SocietyCalc.resilience(100.0, 60.0), 100.0, "R capped at 100")
	eq(SocietyCalc.resilience(50.0, 30.0), 50.0, "R = 0.4H + adapt")
	eq(SocietyCalc.damage_mult(0.0, 0.0), 1.0, "R=0 => x1.0")
	eq(SocietyCalc.damage_mult(50.0, 30.0), 0.75, "R=50 => x0.75")
	eq(SocietyCalc.damage_mult(100.0, 60.0), 0.5, "R=100 => x0.5 (halved)")


func test_happiness_drift() -> void:
	var d := SocietyCalc.happiness_drift(100.0, 0)
	eq(float(d["co_benefit"]), 1.5, "max co-benefit at full transition")
	eq(float(d["stress"]), 0.0, "no stress in band 0")
	d = SocietyCalc.happiness_drift(0.0, 2)
	eq(float(d["co_benefit"]), 0.0, "no co-benefit at 0%")
	eq(float(d["stress"]), 1.0, "Overshoot II stress")


func _social_formula() -> Dictionary:
	for ev in Catalog.load_default().events:
		if String(ev["id"]) == "social_crisis":
			return ev["probability_formula"]
	return {}


func test_social_crisis_probability() -> void:  # T10-P4
	var f := _social_formula()
	approx(SocietyCalc.social_crisis_p(39.9, 0, false, f), 0.25, 1e-9, "low happiness base")
	approx(SocietyCalc.social_crisis_p(40.0, 0, false, f), 0.05, 1e-9, "threshold at exactly 40")
	approx(SocietyCalc.social_crisis_p(39.9, 2, false, f), 0.375, 1e-9, "band 2 scale x1.5")
	approx(SocietyCalc.social_crisis_p(39.9, 2, true, f), 0.1875, 1e-9, "media halves")
	approx(SocietyCalc.social_crisis_p(60.0, 1, true, f), 0.03125, 1e-9, "happy + media: near-never")


func test_social_crisis_flat_damage() -> void:  # T7-P5
	# scaled_by_resilience: false => identical damages at R=0 and R=100.
	var social: Dictionary = {}
	for ev in Catalog.load_default().events:
		if String(ev["id"]) == "social_crisis":
			social = ev
	for setup in [[0.0, 0.0], [100.0, 60.0]]:
		var rs := RunState.new_run(WorldGen.generate(11, true), Catalog.load_default(), [])
		rs.happiness = setup[0]
		rs.adapt = setup[1]
		rs.influence = 50.0
		rs.money = 500.0
		var rec := TurnRecord.new()
		rs._apply_event(social, SocietyCalc.damage_mult(rs.happiness, rs.adapt), rec)
		var damages: Dictionary = rec.events[0]["damages"]
		eq(float(damages["influence"]), 10.0, "flat influence damage at R=%s" % rs.resilience())
		eq(float(damages["money"]), 20.0, "flat money damage at R=%s" % rs.resilience())


func test_scaled_event_damage() -> void:  # T9-P4 applied
	var heat: Dictionary = {}
	for ev in Catalog.load_default().events:
		if String(ev["id"]) == "heat_wave":
			heat = ev
	var rs := RunState.new_run(WorldGen.generate(11, true), Catalog.load_default(), [])
	rs.happiness = 100.0
	rs.adapt = 60.0  # R = 100 => mult 0.5
	rs.money = 500.0
	var rec := TurnRecord.new()
	rs._apply_event(heat, SocietyCalc.damage_mult(rs.happiness, rs.adapt), rec)
	var damages: Dictionary = rec.events[0]["damages"]
	eq(float(damages["money"]), 10.0, "heat money damage halved at R=100")
	eq(float(damages["happiness"]), 1.5, "heat happiness damage halved at R=100")
