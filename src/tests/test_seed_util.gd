extends TestBase
## T1 (Phase 3): sub_seed stability, determinism and stream independence.


func test_deterministic() -> void:
	eq(SeedUtil.sub_seed(2030, SeedUtil.STREAM_WORLD),
		SeedUtil.sub_seed(2030, SeedUtil.STREAM_WORLD), "same input, same output")


func test_streams_differ() -> void:
	var seen := {}
	for stream in [SeedUtil.STREAM_WORLD, SeedUtil.STREAM_EVENTS, SeedUtil.STREAM_TILES, SeedUtil.STREAM_NAMES]:
		var s := SeedUtil.sub_seed(2030, stream)
		check(not seen.has(s), "stream %d produces a distinct sub-seed" % stream)
		seen[s] = true


func test_seeds_differ() -> void:
	check(SeedUtil.sub_seed(2030, 1) != SeedUtil.sub_seed(2031, 1), "adjacent seeds differ")
	check(SeedUtil.sub_seed(0, 1) != SeedUtil.sub_seed(1, 1), "zero/one differ")


func test_golden_values() -> void:
	# Pinned on first implementation; a change here means the whole procgen
	# universe shifted (a design event, not a refactor).
	eq(SeedUtil.sub_seed(2030, 1), GOLDEN_2030_1, "sub_seed(2030, 1) golden value")
	eq(SeedUtil.sub_seed(2030, 2), GOLDEN_2030_2, "sub_seed(2030, 2) golden value")


# Golden values captured from the reference implementation (see test above).
const GOLDEN_2030_1 := 5365218872286590689
const GOLDEN_2030_2 := 67460221322984998
