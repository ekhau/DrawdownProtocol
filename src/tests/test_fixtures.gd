extends TestBase
## T13-P4 / T3-P5: the load-bearing regression test. The three scripted
## strategies on canonical seed 2030 must reproduce the stored golden fixture
## byte-for-byte, with the structural outcomes and KP anchors of the
## crisis-response loop:
## Safe WIN 18 KP - Risky LOSS_LIMIT_BREACHED 2064 4 KP - Mixed WIN 18 KP.
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
	eq(last.end_status, &"WIN_NEUTRAL", "Safe wins carbon-neutral")
	eq(last.kp_awarded, 18, "Safe earns 18 KP (fixture anchor)")
	eq(last.allies, 6, "Safe ends fully allied")
	check(safe.combos_total >= 30, "Safe chains combos all run (got %d)" % safe.combos_total)
	check(safe.crises_answered_total >= 100, "Safe answers the century's crises (got %d)" % safe.crises_answered_total)
	eq(safe.projects_completed, 1, "Safe completes the Global Sink Trust")
	check(safe.unlocked_card_ids.size() >= 5, "deck growth: most unlockables reached")

	var risky := Strategies.autoplay(&"risky", 2030, true)
	last = risky.records.back()
	eq(last.end_status, &"LOSS_LIMIT_BREACHED", "Risky breaches the limit")
	eq(last.year, 2064, "Risky dies in 2064, bled by unanswered crises (fixture anchor)")
	eq(last.kp_awarded, 4, "Risky earns 4 KP (fixture anchor)")
	for sid in WorldEnums.SECTOR_ORDER:
		check(risky.sector(sid).progress <= 70.0, "tech rush never lifts the 70%% cap (%s)" % sid)
	eq(risky.combos_total, 0, "single-family tech spam builds no combos")
	eq(risky.feedback_years.size(), 3, "all three feedback loops fired on the risky run")
	check(risky.fires >= 3, "unanswered fires accumulated")

	var mixed := Strategies.autoplay(&"mixed", 2030, true)
	last = mixed.records.back()
	eq(last.end_status, &"WIN_NEUTRAL", "Mixed wins carbon-neutral")
	eq(last.kp_awarded, 18, "Mixed earns 18 KP (fixture anchor)")
	eq(last.allies, 6, "Mixed ends with the full coalition")
	eq(mixed.projects_completed, 1, "Mixed completes the Continental Rail Compact")


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