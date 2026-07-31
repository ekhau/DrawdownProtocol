extends TestBase
## T2-P4: end-state evaluator truth table (docs/Phase_4/05), boundary sweep,
## and Knowledge Point anchors. The race framing: win = neutrality at ANY
## turn; losses = tipping point, revolt, or a net-positive 2100.


func test_truth_table() -> void:
	eq(EndState.evaluate(2054, 1.99, 12.0, 50.0), EndState.RunStatus.RUNNING, "2054/1.99/+12 RUNNING")
	eq(EndState.evaluate(2054, 2.00, 12.0, 50.0), EndState.RunStatus.LOSS_LIMIT_BREACHED, "2054/2.00 LOSS")
	eq(EndState.evaluate(2060, 1.60, -1.0, 50.0), EndState.RunStatus.WIN_NEUTRAL,
		"neutrality wins EARLY - before the tipping point, not only at 2100")
	eq(EndState.evaluate(2100, 1.46, -23.5, 50.0), EndState.RunStatus.WIN_NEUTRAL, "2100 neutral WIN")
	eq(EndState.evaluate(2100, 1.99, 0.1, 50.0), EndState.RunStatus.LOSS_NOT_NEUTRAL, "2100 N>0 soft loss")
	eq(EndState.evaluate(2100, 1.99, 0.0, 50.0), EndState.RunStatus.WIN_NEUTRAL, "N <= 0 inclusive")
	eq(EndState.evaluate(2100, 2.00, -5.0, 50.0), EndState.RunStatus.LOSS_LIMIT_BREACHED, "limit outranks the win")
	eq(EndState.evaluate(2099, 1.99, 5.0, 50.0), EndState.RunStatus.RUNNING, "century not over")


func test_revolt() -> void:
	eq(EndState.evaluate(2050, 1.70, 5.0, 0.0), EndState.RunStatus.LOSS_REVOLT,
		"happiness 0 = revolt, any year")
	eq(EndState.evaluate(2050, 2.00, 5.0, 0.0), EndState.RunStatus.LOSS_LIMIT_BREACHED,
		"the tipping point outranks the revolt")
	eq(EndState.evaluate(2050, 1.70, -5.0, 0.0), EndState.RunStatus.LOSS_REVOLT,
		"a neutral world in open revolt is still a lost run")
	eq(EndState.evaluate(2050, 1.70, 5.0, 0.1), EndState.RunStatus.RUNNING,
		"any happiness above zero keeps the city governed")


func test_boundary_sweep() -> void:
	eq(EndState.evaluate(2050, 1.999, 10.0, 50.0), EndState.RunStatus.RUNNING, "T 1.999 running")
	eq(EndState.evaluate(2050, 2.000, 10.0, 50.0), EndState.RunStatus.LOSS_LIMIT_BREACHED, "T 2.000 loss")
	eq(EndState.evaluate(2050, 1.4, -0.001, 50.0), EndState.RunStatus.WIN_NEUTRAL, "N -0.001 early win")
	eq(EndState.evaluate(2100, 1.4, 0.001, 50.0), EndState.RunStatus.LOSS_NOT_NEUTRAL, "N +0.001 soft loss")


func test_status_strings_stable() -> void:
	eq(EndState.status_string(EndState.RunStatus.WIN_NEUTRAL), &"WIN_NEUTRAL", "stable code")
	eq(EndState.status_string(EndState.RunStatus.LOSS_LIMIT_BREACHED), &"LOSS_LIMIT_BREACHED", "stable code")
	eq(EndState.status_string(EndState.RunStatus.LOSS_NOT_NEUTRAL), &"LOSS_NOT_NEUTRAL", "stable code")
	eq(EndState.status_string(EndState.RunStatus.LOSS_REVOLT), &"LOSS_REVOLT", "stable code")


func test_knowledge_points_anchors() -> void:
	# Decades survived + sectors at 70+ + allies/2 + win bonus, floored at 1.
	eq(EndState.knowledge_points(EndState.RunStatus.WIN_NEUTRAL, 2085, [100.0, 100.0, 100.0], 4), 13,
		"early win 2085: 5 + 3 + 2 + 3 = 13")
	eq(EndState.knowledge_points(EndState.RunStatus.LOSS_LIMIT_BREACHED, 2060, [40.0, 40.0, 40.0], 0), 3,
		"overheat 2060: 3 decades survived")
	eq(EndState.knowledge_points(EndState.RunStatus.LOSS_NOT_NEUTRAL, 2100, [100.0, 70.0, 40.0], 2), 10,
		"soft loss: 7 + 2 + 1 = 10")
	eq(EndState.knowledge_points(EndState.RunStatus.LOSS_REVOLT, 2035, [0.0, 0.0, 0.0], 0), 1,
		"even the fastest defeat pays the 1 KP floor - both ends feed the meta")
