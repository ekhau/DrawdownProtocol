extends TestBase
## The defeat post-mortem (docs/Phase_4/06): a pure heuristic over the turn
## log that names the pivotal turn, per outcome family.


func test_revolt_post_mortem() -> void:
	var rs := Strategies.autoplay(&"risky", 2030, true)
	eq(rs.records.back().end_status, &"LOSS_REVOLT", "canonical risky run revolts")
	var pm := PostMortem.analyze(rs.records, rs.catalog)
	check(not pm.is_empty(), "post-mortem produced")
	check("revolt" in String(pm["headline"]), "headline names the revolt")
	check(int(pm["pivot_turn"]) >= 1 and int(pm["pivot_turn"]) <= rs.records.size(),
		"pivotal turn inside the run")
	check((pm["lines"] as PackedStringArray).size() >= 1, "at least one explanation line")


func test_win_post_mortem() -> void:
	var rs := Strategies.autoplay(&"safe", 2030, true)
	eq(rs.records.back().end_status, &"WIN_NEUTRAL", "canonical safe run wins")
	var pm := PostMortem.analyze(rs.records, rs.catalog)
	check("drawdown" in String(pm["headline"]), "the win names its drawdown moment")
	eq(int(pm["pivot_year"]), rs.records.back().year, "pivot = the turn the curve bent")


func test_overheat_post_mortem_finds_worst_turn() -> void:
	# Synthetic: turn 3 took huge unanswered damage; turn 5 sealed the loss.
	var quiet := TurnRecord.new()
	quiet.year = 2030
	quiet.turn = 1
	var pivotal := TurnRecord.new()
	pivotal.year = 2040
	pivotal.turn = 3
	pivotal.crises = [
		{"id": &"flood_tsunami", "kind": "crisis", "answered": false,
			"damages": {"money": 60.0, "happiness": 4.0}},
		{"id": &"drought", "kind": "crisis", "answered": false,
			"damages": {"money": 30.0, "happiness": 4.0, "absorption": 0.6}},
	]
	var terminal := TurnRecord.new()
	terminal.year = 2050
	terminal.turn = 5
	terminal.end_status = &"LOSS_LIMIT_BREACHED"
	terminal.emissions_world = 40.0
	terminal.emissions_city = 45.0
	var records: Array[TurnRecord] = [quiet, pivotal, terminal]
	var pm := PostMortem.analyze(records, Catalog.load_default())
	eq(int(pm["pivot_turn"]), 3, "the damage turn is the pivot, not the death turn")
	eq(int(pm["pivot_year"]), 2040, "pivot year reported")
	check("overheat" in String(pm["headline"]), "headline names the overheat")


func test_timeout_post_mortem_names_the_gap() -> void:
	var rec := TurnRecord.new()
	rec.year = 2100
	rec.turn = 15
	rec.end_status = &"LOSS_NOT_NEUTRAL"
	rec.net = 12.0
	rec.emissions_world = 22.0
	rec.emissions_city = 6.0
	rec.absorption = 16.0
	var records: Array[TurnRecord] = [rec]
	var pm := PostMortem.analyze(records, Catalog.load_default())
	var joined := "\n".join(pm["lines"] as PackedStringArray)
	check("blocs" in joined or "diplomacy" in joined,
		"a world-heavy ledger points at the diplomacy lever")


func test_summit_miss_weighs_on_the_pivot() -> void:
	var summit_turn := TurnRecord.new()
	summit_turn.year = 2045
	summit_turn.turn = 4
	summit_turn.summit = {"id": "cop_2045", "name": "Global Stocktake 2045",
		"met": false, "value": 62.0, "target": 45.0}
	var terminal := TurnRecord.new()
	terminal.year = 2060
	terminal.turn = 7
	terminal.end_status = &"LOSS_LIMIT_BREACHED"
	var records: Array[TurnRecord] = [summit_turn, terminal]
	var pm := PostMortem.analyze(records, Catalog.load_default())
	eq(int(pm["pivot_turn"]), 4, "the failed summit is the pivotal turn")
	check("Stocktake" in "\n".join(pm["lines"] as PackedStringArray), "and it is named")
