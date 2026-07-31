extends TestBase
## T13-P4 / T3-P5: the load-bearing regression test. The three scripted
## strategies on canonical seed 2030 must reproduce the stored golden fixture
## byte-for-byte, with the structural outcomes and KP anchors of the
## clock-race loop:
## Safe WIN 2095 12 KP - Risky LOSS_REVOLT 2065 3 KP - Mixed WIN 2095 12 KP.
##
## Regenerate deliberately via tools/gen_fixtures.gd when a balance change is
## intended; the diff is the design review artifact (docs/Phase_5/05).

const FIXTURE_PATH := "res://tests/fixtures/seed2030_expected.csv"


func test_fixture_regression() -> void:
	var expected := FileAccess.get_file_as_string(FIXTURE_PATH)
	check(not expected.is_empty(), "fixture file present (run tools/gen_fixtures.gd once)")
	var lines: PackedStringArray = []
	for strat in Strategies.NAMES:
		var rs := Strategies.autoplay(strat, 2030, true)
		lines.append(BatchRunsTool.csv_row(2030, strat, rs))
	var actual := "\n".join(lines) + "\n"
	eq(actual, expected, "seed-2030 canonical runs match the golden fixture byte-for-byte")


func test_structural_outcomes() -> void:
	var safe := Strategies.autoplay(&"safe", 2030, true)
	var last: TurnRecord = safe.records.back()
	eq(last.end_status, &"WIN_NEUTRAL", "Safe wins: neutrality before the tipping point")
	eq(last.year, 2095, "Safe bends the curve on turn 14 (fixture anchor)")
	eq(last.kp_awarded, 12, "Safe earns 12 KP (fixture anchor)")
	check(safe.curve_bent_year == 2095, "the drawdown moment recorded")
	check(safe.combos_total >= 8, "Safe chains combos across the run (got %d)" % safe.combos_total)
	check(safe.crises_answered_total >= 20, "Safe answers the century's crises (got %d)" % safe.crises_answered_total)
	check(safe.projects_completed >= 1, "Safe completes the Global Sink Trust")
	check(last.emissions_world < 20.0, "Safe bought down the world's blocs (%.1f)" % last.emissions_world)

	var risky := Strategies.autoplay(&"risky", 2030, true)
	last = risky.records.back()
	eq(last.end_status, &"LOSS_REVOLT", "Risky governs past the people and loses the city")
	eq(last.year, 2065, "Risky revolts on turn 8 (fixture anchor)")
	eq(last.kp_awarded, 3, "Risky earns 3 KP (fixture anchor)")
	for sid in WorldEnums.SECTOR_ORDER:
		check(risky.sector(sid).progress <= 70.0, "tech rush never lifts the 70%% cap (%s)" % sid)
	eq(risky.allies, 0, "moonshot rush makes no friends")
	check(last.emissions_world >= 38.0, "the ignored world kept drifting (%.1f)" % last.emissions_world)

	var mixed := Strategies.autoplay(&"mixed", 2030, true)
	last = mixed.records.back()
	eq(last.end_status, &"WIN_NEUTRAL", "Mixed wins carbon-neutral")
	eq(last.year, 2095, "Mixed bends the curve on turn 14 (fixture anchor)")
	eq(last.kp_awarded, 12, "Mixed earns 12 KP (fixture anchor)")
	check(mixed.projects_completed >= 1, "Mixed completes the Continental Rail Compact")
	check(last.emissions_world < 20.0, "Mixed treatied the world down (%.1f)" % last.emissions_world)


func test_batch_structural_20_seeds() -> void:  # T12 (Phase 3 done criterion 4)
	# The corridor is a RATE corridor: the market deal is deliberate variance
	# (docs/Phase_1/05). Risky must never win; the two competent scripts must
	# clear their win-rate floors.
	var wins := {&"safe": 0, &"mixed": 0}
	for s in range(1, 21):
		for strat in Strategies.NAMES:
			var rs := Strategies.autoplay(strat, s, false)
			var last: TurnRecord = rs.records.back()
			var won := last.end_status == &"WIN_NEUTRAL"
			if strat == &"risky":
				check(not won, "risky must never win (seed %d)" % s)
			elif won:
				wins[strat] = int(wins[strat]) + 1
	check(int(wins[&"safe"]) >= 10, "safe wins at least 10/20 seeds (got %d)" % wins[&"safe"])
	check(int(wins[&"mixed"]) >= 8, "mixed wins at least 8/20 seeds (got %d)" % wins[&"mixed"])
