extends TestBase
## T1-P4: ClimateCalc golden values (docs/Phase_4/03, fixture anchors).
## One turn = 5 years; all rates are per-turn. If one of these fails, the
## balance model changed - that is a design event.


func test_gross_emissions_golden() -> void:
	eq(ClimateCalc.gross_emissions([20.0, 15.0, 15.0], [0.0, 0.0, 0.0], 0.0), 50.0,
		"all sectors 0% => city E = 50.0")
	eq(ClimateCalc.gross_emissions([20.0, 15.0, 15.0], [100.0, 100.0, 100.0], 0.0), 5.0,
		"all sectors 100% => city E = 5.0 (10% residual)")
	approx(ClimateCalc.gross_emissions([20.0, 15.0, 15.0], [70.0, 70.0, 70.0], 0.0), 18.5, 1e-9,
		"70/70/70 => city E = 18.5 (the tech-rush plateau)")
	eq(ClimateCalc.gross_emissions([20.0, 15.0, 15.0], [0.0, 0.0, 0.0], 2.0), 52.0,
		"e_extra adds to gross")


func test_warming_delta_golden() -> void:
	approx(ClimateCalc.warming_delta(30.0), 0.033, 1e-12, "N=+30 => dT=+0.033/turn")
	approx(ClimateCalc.warming_delta(-20.0), -0.0056, 1e-12, "N=-20 => dT=-0.0056 (~4x slower cooling)")
	eq(ClimateCalc.warming_delta(0.0), 0.0, "N=0 => dT=0")


func test_band_boundaries() -> void:
	eq(ClimateCalc.band(1.49), 0, "band(1.49) = 0")
	eq(ClimateCalc.band(1.50), 1, "band(1.50) = 1")
	eq(ClimateCalc.band(1.74), 1, "band(1.74) = 1")
	eq(ClimateCalc.band(1.75), 2, "band(1.75) = 2")


func test_climate_clock() -> void:
	# The adversary gauge: 0% at +1.0 C, 100% at +2.0 C (tipping = defeat).
	approx(ClimateCalc.clock_pct(1.30), 30.0, 1e-9, "run starts at 30% on the clock")
	approx(ClimateCalc.clock_pct(2.00), 100.0, 1e-9, "tipping point = 100%")
	approx(ClimateCalc.clock_pct(0.90), 0.0, 1e-9, "clamped at 0%")
	approx(ClimateCalc.clock_pct(2.30), 100.0, 1e-9, "clamped at 100%")
	approx(ClimateCalc.clock_delta_pct(0.05), 5.0, 1e-9, "+0.05 C = +5 clock points")
	approx(ClimateCalc.clock_delta_pct(-0.01), -1.0, 1e-9, "cooling shows as negative points")


func test_sink_floor() -> void:
	# A 5.2, band-2 stress 1.2 => floor engaged at 5.0.
	var a := maxf(ClimateCalc.a_floor(), 5.2 - ClimateCalc.sink_stress(1.80))
	eq(a, 5.0, "absorption floor engages")
	eq(ClimateCalc.sink_stress(1.40), 0.0, "no stress below 1.5")
	eq(ClimateCalc.sink_stress(1.60), 0.5, "Overshoot I stress per turn")
	eq(ClimateCalc.sink_stress(1.80), 1.2, "Overshoot II stress per turn")


func test_warming_floor() -> void:
	eq(ClimateCalc.apply_warming(1.21, -100.0), 1.20, "T floor at 1.20")
