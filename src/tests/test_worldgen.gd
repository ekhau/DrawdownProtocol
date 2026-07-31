extends TestBase
## Phase 3 tests T2-T5, T10: world generation determinism and invariants.

const BATCH := 100


func test_same_seed_identical() -> void:  # T2
	var a := WorldGen.generate(4242)
	var b := WorldGen.generate(4242)
	eq(a.serialize(), b.serialize(), "same seed => byte-identical serialized world")


func test_adjacent_seeds_differ() -> void:  # T3
	var a := WorldGen.generate(7)
	var b := WorldGen.generate(8)
	check(a.serialize() != b.serialize(), "seeds k and k+1 => different worlds")


func test_share_sums() -> void:  # T4
	for s in range(1, BATCH + 1):
		var gen := WorldGen.generate(s)
		var sums := {"ind": 0.0, "tra": 0.0, "agr": 0.0, "sink": 0.0}
		for r in gen.regions:
			sums["ind"] += r.ind_share
			sums["tra"] += r.tra_share
			sums["agr"] += r.agr_share
			sums["sink"] += r.sink_share
		for k in sums:
			if absf(float(sums[k]) - 1.0) > 0.001:
				check(false, "seed %d: %s shares sum %.5f != 1" % [s, k, sums[k]])
				return
	check(true, "share sums hold over %d seeds" % BATCH)


func test_archetype_invariants() -> void:  # T5
	var presets: Dictionary = {}
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/archetypes.json"))
	for a: Dictionary in parsed["archetypes"]:
		presets[String(a["id"])] = a
	for s in range(1, BATCH + 1):
		var gen := WorldGen.generate(s)
		var homes := 0
		var coastal := 0
		var fire_eligible := 0
		var counts := {}
		for r in gen.regions:
			if r.is_player_home:
				homes += 1
			if r.coastal:
				coastal += 1
			if r.forested or r.arid:
				fire_eligible += 1
			counts[String(r.archetype)] = int(counts.get(String(r.archetype), 0)) + 1
		if homes != 1 or coastal < 2 or fire_eligible < 2:
			check(false, "seed %d: home/coastal/fire floor violated (%d/%d/%d)" % [s, homes, coastal, fire_eligible])
			return
		for id in presets:
			var c := int(counts.get(id, 0))
			var preset: Dictionary = presets[id]
			if c < int(preset["min"]) or c > int(preset["max"]):
				check(false, "seed %d: archetype %s count %d outside %d-%d" % [s, id, c, preset["min"], preset["max"]])
				return
	check(true, "archetype invariants hold over %d seeds" % BATCH)


func test_jitter_clamps() -> void:  # T10
	for s in range(1, BATCH + 1):
		var gen := WorldGen.generate(s, false)
		var total := 0.0
		for sector in WorldEnums.SECTOR_ORDER:
			total += float(gen.sector_bases[sector])
		if total < 48.0 - 0.001 or total > 52.0 + 0.001:
			check(false, "seed %d: sector base total %.2f outside 48-52" % [s, total])
			return
		if gen.absorption_start < 18.0 or gen.absorption_start > 22.0:
			check(false, "seed %d: absorption start %.2f outside 18-22" % [s, gen.absorption_start])
			return
		if gen.happiness_start < 57.0 or gen.happiness_start > 63.0:
			check(false, "seed %d: happiness start %.2f outside 57-63" % [s, gen.happiness_start])
			return
		if gen.temp_start != 1.30:
			check(false, "seed %d: warming start rolled (must always be 1.30)" % s)
			return
	check(true, "jitter clamps hold over %d seeds" % BATCH)


func test_canonical_starts() -> void:
	var gen := WorldGen.generate(2030, true)
	eq(float(gen.sector_bases[&"ind"]), 20.0, "canonical ind base")
	eq(float(gen.sector_bases[&"tra"]), 15.0, "canonical tra base")
	eq(float(gen.sector_bases[&"agr"]), 15.0, "canonical agr base")
	eq(gen.absorption_start, 20.0, "canonical absorption")
	eq(gen.money_start, 150.0, "canonical money")
	eq(gen.happiness_start, 60.0, "canonical happiness")
