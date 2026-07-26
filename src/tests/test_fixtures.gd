extends TestBase
## T13-P4 / T3-P5: the load-bearing regression test. The three scripted
## strategies on canonical seed 2030 must reproduce the stored golden fixture
## byte-for-byte, with the Phase 1 structural outcomes and KP anchors:
## Safe WIN 15 KP - Risky LOSS_LIMIT_BREACHED 2099 9 KP - Mixed WIN 16 KP.
##
## NOTE: the Phase 1 sample-run decade TABLES cannot be byte-reproduced (the
## paper model's throwaway script and its exact RNG stream were never
## committed - golden rule 4). The fixture stored here pins THIS
## implementation; the structural outcomes and KP values match Phase 1.

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
	eq(last.end_status, &"WIN_NEUTRAL", "Safe wins carbon-neutral")
	eq(last.kp_awarded, 15, "Safe earns 15 KP (Phase 1 anchor)")

	var risky := Strategies.autoplay(&"risky", 2030, true)
	last = risky.records.back()
	eq(last.end_status, &"LOSS_LIMIT_BREACHED", "Risky breaches the limit")
	eq(last.year, 2099, "Risky dies in 2099, one year short (Phase 1 anchor)")
	eq(last.kp_awarded, 9, "Risky earns 9 KP (Phase 1 anchor)")
	eq(risky.sector(&"ind").progress, 70.0, "tech rush frozen at the 70% cap")
	eq(risky.sector(&"tra").progress, 70.0, "tech rush frozen at the 70% cap")
	eq(risky.sector(&"agr").progress, 70.0, "tech rush frozen at the 70% cap")

	var mixed := Strategies.autoplay(&"mixed", 2030, true)
	last = mixed.records.back()
	eq(last.end_status, &"WIN_NEUTRAL", "Mixed wins carbon-neutral")
	eq(last.kp_awarded, 16, "Mixed earns 16 KP (Phase 1 anchor)")
	eq(last.allies, 6, "Mixed ends with the full coalition")


func test_batch_structural_20_seeds() -> void:  # T12 (Phase 3 done criterion 4)
	for s in range(1, 21):
		for strat in Strategies.NAMES:
			var rs := Strategies.autoplay(strat, s, false)
			var last: TurnRecord = rs.records.back()
			var won := last.end_status == &"WIN_NEUTRAL"
			if strat == &"risky":
				check(not won, "risky must never win (seed %d)" % s)
			else:
				check(won, "%s must always win (seed %d, got %s in %d)" % [strat, s, last.end_status, last.year])
