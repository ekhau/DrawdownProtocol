class_name WorldGen
## Deterministic, seeded generation of the starting world (Tier A).
## Spec: docs/Phase_3/02_Procedural_Generation_Spec.md.
## Same seed => identical world. Sub-seed streams keep world/name/event
## randomness independent. All draws loop over arrays in fixed index order.

const ARCHETYPES_PATH := "res://data/archetypes.json"

static var _data: Dictionary = {}


class WorldGenResult:
	extends RefCounted
	var run_seed: int = 0
	var canonical: bool = false
	var regions: Array[RegionData] = []
	var sector_bases: Dictionary = {}      # StringName -> float (jittered or canonical)
	var absorption_start: float = 0.0
	var money_start: float = 0.0
	var happiness_start: float = 0.0
	var temp_start: float = 0.0

	func serialize() -> String:
		var arr: Array = []
		for r in regions:
			arr.append(r.to_dict())
		return JSON.stringify({
			"run_seed": run_seed,
			"regions": arr,
			"sector_bases": {
				"ind": sector_bases[&"ind"], "tra": sector_bases[&"tra"], "agr": sector_bases[&"agr"],
			},
			"absorption_start": absorption_start,
			"money_start": money_start,
			"happiness_start": happiness_start,
		})


static func _ensure_data() -> void:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARCHETYPES_PATH))
		assert(parsed is Dictionary, "Failed to parse archetypes.json")
		_data = parsed


## Generate the world for a run seed. canonical = true skips all start jitter
## (exact Phase 1 starting values; used by fixture and regression runs).
static func generate(run_seed: int, canonical: bool = false) -> WorldGenResult:
	_ensure_data()
	var rng_world := RandomNumberGenerator.new()
	rng_world.seed = SeedUtil.sub_seed(run_seed, SeedUtil.STREAM_WORLD)
	var rng_names := RandomNumberGenerator.new()
	rng_names.seed = SeedUtil.sub_seed(run_seed, SeedUtil.STREAM_NAMES)

	var res := WorldGenResult.new()
	res.run_seed = run_seed
	res.canonical = canonical

	var archetypes: Array = _data["archetypes"]
	var home_preset: Dictionary = {}
	var others: Array[Dictionary] = []
	for a: Dictionary in archetypes:
		if a.get("is_home", false):
			home_preset = a
		else:
			others.append(a)
	var n: int = int(_data["region_count"])

	# --- step 1: archetype assignment (home first, then bounded weighted fill) ---
	var assigned: Array[Dictionary] = []
	assigned.resize(n)
	assigned[0] = home_preset
	var counts: Dictionary = {}
	for i in range(1, n):
		var candidates: Array[Dictionary] = []
		for a in others:
			if int(counts.get(String(a["id"]), 0)) < int(a["max"]):
				candidates.append(a)
		var pick: Dictionary = candidates[rng_world.randi_range(0, candidates.size() - 1)]
		assigned[i] = pick
		counts[String(pick["id"])] = int(counts.get(String(pick["id"]), 0)) + 1
	# Fill unmet minimums by replacing instances of the most common type.
	for a in others:
		while int(counts.get(String(a["id"]), 0)) < int(a["min"]):
			var most_id := ""
			var most_count := 0
			for b in others:
				var cb := int(counts.get(String(b["id"]), 0))
				if cb > int(b["min"]) and cb > most_count:
					most_count = cb
					most_id = String(b["id"])
			if most_id.is_empty():
				break  # cannot rebalance further (data misconfigured); asserted below
			# Replace the highest-index region of the most common type (deterministic).
			for i in range(n - 1, 0, -1):
				if String(assigned[i]["id"]) == most_id:
					assigned[i] = a
					counts[most_id] = int(counts[most_id]) - 1
					counts[String(a["id"])] = int(counts.get(String(a["id"]), 0)) + 1
					break

	# --- build regions ---
	for i in n:
		var preset: Dictionary = assigned[i]
		var region := RegionData.new()
		region.id = StringName("region_%02d" % i)
		region.archetype = StringName(preset["id"])
		region.is_player_home = bool(preset.get("is_home", false))
		var tags: Array = preset.get("tags", [])
		region.coastal = tags.has("coastal")
		region.arid = tags.has("arid")
		region.forested = tags.has("forested")
		region.alliance_affinity = float(preset.get("affinity", 1.0))
		region.ally_state = WorldEnums.AllyState.PLAYER_HOME if region.is_player_home \
				else WorldEnums.AllyState.NEUTRAL
		res.regions.append(region)

	# --- steps 2-3: normalized share draws (fixed sector then region order) ---
	var jitter: Dictionary = _data["jitter"]
	var noise: Array = jitter["share_noise_range"]
	for sector in WorldEnums.SECTOR_ORDER:
		var raws: Array[float] = []
		var total := 0.0
		for i in n:
			var mult := float(assigned[i][String(sector)])
			var raw := mult * rng_world.randf_range(float(noise[0]), float(noise[1]))
			raws.append(raw)
			total += raw
		for i in n:
			var share := raws[i] / total
			match sector:
				&"ind": res.regions[i].ind_share = share
				&"tra": res.regions[i].tra_share = share
				&"agr": res.regions[i].agr_share = share
	var sink_raws: Array[float] = []
	var sink_total := 0.0
	for i in n:
		var raw := float(assigned[i]["sink"]) * rng_world.randf_range(float(noise[0]), float(noise[1]))
		sink_raws.append(raw)
		sink_total += raw
	for i in n:
		res.regions[i].sink_share = sink_raws[i] / sink_total

	# --- step 5: global start jitter (parameter-level procgen) ---
	var bases: Dictionary = Tuning.c("SECTOR_BASE")
	res.temp_start = float(Tuning.c("T_START"))  # thresholds are facts, never rolled
	if canonical:
		for sector in WorldEnums.SECTOR_ORDER:
			res.sector_bases[sector] = float(bases[String(sector)])
		res.absorption_start = float(Tuning.c("A_START"))
		res.money_start = float(Tuning.s("M_START"))
		res.happiness_start = float(Tuning.s("H_START"))
	else:
		var brange: Array = jitter["sector_base_range"]
		var total_base := 0.0
		for sector in WorldEnums.SECTOR_ORDER:
			var b := float(bases[String(sector)]) * rng_world.randf_range(float(brange[0]), float(brange[1]))
			res.sector_bases[sector] = b
			total_base += b
		var tclamp: Array = jitter["sector_total_clamp"]
		var clamped_total := clampf(total_base, float(tclamp[0]), float(tclamp[1]))
		if not is_equal_approx(clamped_total, total_base):
			var scale := clamped_total / total_base
			for sector in WorldEnums.SECTOR_ORDER:
				res.sector_bases[sector] = res.sector_bases[sector] * scale
		var arange: Array = jitter["absorption_range"]
		var aclamp: Array = jitter["absorption_clamp"]
		res.absorption_start = clampf(
			float(Tuning.c("A_START")) * rng_world.randf_range(float(arange[0]), float(arange[1])),
			float(aclamp[0]), float(aclamp[1]))
		var mrange: Array = jitter["money_range"]
		res.money_start = float(Tuning.s("M_START")) * rng_world.randf_range(float(mrange[0]), float(mrange[1]))
		var hrange: Array = jitter["happiness_delta_range"]
		res.happiness_start = float(Tuning.s("H_START")) + rng_world.randf_range(float(hrange[0]), float(hrange[1]))

	# --- step 6: names (independent stream) ---
	var used_names: Dictionary = {}
	for i in n:
		var syllables: Array = assigned[i].get("syllables", ["ter", "ra"])
		var name := ""
		for attempt in 16:
			name = _roll_name(rng_names, syllables)
			if not used_names.has(name):
				break
		if used_names.has(name):
			name += str(i)
		used_names[name] = true
		res.regions[i].display_name = name

	_assert_invariants(res)
	return res


static func _roll_name(rng: RandomNumberGenerator, syllables: Array) -> String:
	var count := rng.randi_range(2, 3)
	var name := ""
	for s in count:
		name += String(syllables[rng.randi_range(0, syllables.size() - 1)])
	return name.capitalize()


static func _assert_invariants(res: WorldGenResult) -> void:
	var homes := 0
	var coastal := 0
	var fire_eligible := 0
	var sums := {"ind": 0.0, "tra": 0.0, "agr": 0.0, "sink": 0.0}
	for r in res.regions:
		if r.is_player_home:
			homes += 1
		if r.coastal:
			coastal += 1
		if r.forested or r.arid:
			fire_eligible += 1
		sums["ind"] += r.ind_share
		sums["tra"] += r.tra_share
		sums["agr"] += r.agr_share
		sums["sink"] += r.sink_share
	assert(homes == 1, "exactly one player home")
	assert(coastal >= 2, "at least 2 coastal regions")
	assert(fire_eligible >= 2, "at least 2 fire-eligible regions")
	for k in sums:
		assert(absf(sums[k] - 1.0) < 0.001, "shares for %s sum to 1" % k)
