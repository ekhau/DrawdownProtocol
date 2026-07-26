extends TestBase
## T2-P4: end-state evaluator truth table (docs/Phase_4/05), boundary sweep,
## and Knowledge Point fixture anchors.


func test_truth_table() -> void:
	eq(EndState.evaluate(2054, 1.99, 12.0), EndState.RunStatus.RUNNING, "2054/1.99/+12 RUNNING")
	eq(EndState.evaluate(2054, 2.00, 12.0), EndState.RunStatus.LOSS_LIMIT_BREACHED, "2054/2.00 LOSS")
	eq(EndState.evaluate(2100, 1.46, -23.5), EndState.RunStatus.WIN_NEUTRAL, "2100 neutral WIN")
	eq(EndState.evaluate(2100, 1.99, 0.1), EndState.RunStatus.LOSS_NOT_NEUTRAL, "2100 N>0 soft loss")
	eq(EndState.evaluate(2100, 1.99, 0.0), EndState.RunStatus.WIN_NEUTRAL, "N <= 0 inclusive")
	eq(EndState.evaluate(2100, 2.00, -5.0), EndState.RunStatus.LOSS_LIMIT_BREACHED, "limit outranks calendar")
	eq(EndState.evaluate(2099, 1.99, -5.0), EndState.RunStatus.RUNNING, "century not over")


func test_boundary_sweep() -> void:
	eq(EndState.evaluate(2050, 1.999, 10.0), EndState.RunStatus.RUNNING, "T 1.999 running")
	eq(EndState.evaluate(2050, 2.000, 10.0), EndState.RunStatus.LOSS_LIMIT_BREACHED, "T 2.000 loss")
	eq(EndState.evaluate(2100, 1.4, -0.001), EndState.RunStatus.WIN_NEUTRAL, "N -0.001 win")
	eq(EndState.evaluate(2100, 1.4, 0.001), EndState.RunStatus.LOSS_NOT_NEUTRAL, "N +0.001 soft loss")


func test_status_strings_stable() -> void:
	eq(EndState.status_string(EndState.RunStatus.WIN_NEUTRAL), &"WIN_NEUTRAL", "stable code")
	eq(EndState.status_string(EndState.RunStatus.LOSS_LIMIT_BREACHED), &"LOSS_LIMIT_BREACHED", "stable code")
	eq(EndState.status_string(EndState.RunStatus.LOSS_NOT_NEUTRAL), &"LOSS_NOT_NEUTRAL", "stable code")


func test_knowledge_points_anchors() -> void:
	# Risky fixture: loss 2099, three sectors at 70, 0 allies => 6 + 3 + 0 = 9.
	eq(EndState.knowledge_points(EndState.RunStatus.LOSS_LIMIT_BREACHED, 2099, [70.0, 70.0, 70.0], 0), 9,
		"Risky anchor: 9 KP")
	# Safe fixture: win 2100, all sectors 100, 4 allies => 7 + 3 + 2 + 3 = 15.
	eq(EndState.knowledge_points(EndState.RunStatus.WIN_NEUTRAL, 2100, [100.0, 100.0, 100.0], 4), 15,
		"Safe anchor: 15 KP")
	# Mixed fixture: win 2100, all sectors 100, 6 allies => 7 + 3 + 3 + 3 = 16.
	eq(EndState.knowledge_points(EndState.RunStatus.WIN_NEUTRAL, 2100, [100.0, 100.0, 100.0], 6), 16,
		"Mixed anchor: 16 KP")
	# Soft loss earns everything except the +3.
	eq(EndState.knowledge_points(EndState.RunStatus.LOSS_NOT_NEUTRAL, 2100, [100.0, 70.0, 40.0], 2), 10,
		"soft loss: 7 + 2 + 1 = 10")
