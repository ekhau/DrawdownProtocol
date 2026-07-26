extends TestBase
## T1-P4: ClimateCalc golden values (docs/Phase_4/03, fixture anchors).
## If one of these fails, the balance model changed - that is a design event.


func test_gross_emissions_golden() -> void:
	eq(ClimateCalc.gross_emissions([20.0, 15.0, 15.0], [0.0, 0.0, 0.0], 0.0), 50.0,
		"all sectors 0% => E = 50.0")
	eq(ClimateCalc.gross_emissions([20.0, 15.0, 15.0], [100.0, 100.0, 100.0], 0.0), 5.0,
		"all sectors 100% => E = 5.0 (10% residual)")
	approx(ClimateCalc.gross_emissions([20.0, 15.0, 15.0], [70.0, 70.0, 70.0], 0.0), 18.5, 1e-9,
		"70/70/70 => E = 18.5 (the Run B plateau)")
	eq(ClimateCalc.gross_emissions([20.0, 15.0, 15.0], [0.0, 0.0, 0.0], 2.0), 52.0,
		"e_extra adds to gross")


func test_warming_delta_golden() -> void:
	approx(ClimateCalc.warming_delta(30.0), 0.030, 1e-12, "N=+30 => dT=+0.030")
	approx(ClimateCalc.warming_delta(-20.0), -0.005, 1e-12, "N=-20 => dT=-0.005 (4x slower cooling)")
	eq(ClimateCalc.warming_delta(0.0), 0.0, "N=0 => dT=0")


func test_band_boundaries() -> void:
	eq(ClimateCalc.band(1.49), 0, "band(1.49) = 0")
	eq(ClimateCalc.band(1.50), 1, "band(1.50) = 1")
	eq(ClimateCalc.band(1.74), 1, "band(1.74) = 1")
	eq(ClimateCalc.band(1.75), 2, "band(1.75) = 2")


func test_sink_floor() -> void:
	# A 5.2, stress 0.25 => floor engaged at 5.0.
	var a := maxf(ClimateCalc.a_floor(), 5.2 - ClimateCalc.sink_stress(1.80))
	eq(a, 5.0, "absorption floor engages")
	eq(ClimateCalc.sink_stress(1.40), 0.0, "no stress below 1.5")
	eq(ClimateCalc.sink_stress(1.60), 0.10, "Overshoot I stress")
	eq(ClimateCalc.sink_stress(1.80), 0.25, "Overshoot II stress")


func test_warming_floor() -> void:
	eq(ClimateCalc.apply_warming(1.21, -100.0), 1.20, "T floor at 1.20")
