extends TestBase
## T8-P4 / T9-P5: knowledge nodes patch the in-memory catalog and grant state
## exactly as specified; the disk catalog is never mutated.


func test_affordable_evs() -> void:
	var base := Catalog.load_default()
	var patched := base.duplicate_patched(["affordable_evs"])
	eq(float(patched.card(&"TRA2")["cost_money"]), 84.0, "TRA2 cost 140 -> 84")
	eq(float(base.card(&"TRA2")["cost_money"]), 140.0, "base catalog untouched")


func test_healthy_sobriety() -> void:
	var patched := Catalog.load_default().duplicate_patched(["healthy_sobriety"])
	for id in [&"AGR1", &"TRA3"]:
		for eff: Dictionary in patched.card(id)["effects"]:
			if String(eff["op"]) == "happiness":
				eq(float(eff["amount"]), 2.0, "%s happiness -3 -> +2" % id)


func test_restoration_playbook_preserves_totals() -> void:
	var patched := Catalog.load_default().duplicate_patched(["restoration_playbook"])
	for eff: Dictionary in patched.card(&"SNK1")["effects"]:
		if String(eff["op"]) == "reforest":
			eq(int(eff["years"]), 3, "SNK1 matures in 3 years")
			approx(float(eff["per_year"]) * int(eff["years"]), 1.5, 1e-9, "SNK1 total preserved (1.5)")
	for eff: Dictionary in patched.card(&"SNK2")["effects"]:
		if String(eff["op"]) == "reforest":
			eq(int(eff["years"]), 3, "SNK2 matures in 3 years")
			approx(float(eff["per_year"]) * int(eff["years"]), 1.0, 1e-9, "SNK2 total preserved (1.0)")


func test_coalition_diplomacy() -> void:
	var patched := Catalog.load_default().duplicate_patched(["coalition_diplomacy"])
	eq(float(patched.card(&"DIP1")["cost_influence"]), 15.0, "DIP1 influence 25 -> 15")


func test_grants_at_init() -> void:
	var gen := WorldGen.generate(2030, true)
	var rs := RunState.new_run(gen, Catalog.load_default(), ["informed_public", "crisis_ready"])
	eq(rs.media, true, "informed_public grants media from year 1")
	eq(rs.adapt, 10.0, "crisis_ready grants +10 adaptation")
	var rs_plain := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	eq(rs_plain.media, false, "no grants without nodes")
	eq(rs_plain.adapt, 0.0, "no adapt without nodes")


func test_disk_catalog_unchanged() -> void:
	var before := FileAccess.get_file_as_string("res://data/cards.json")
	var base := Catalog.load_default()
	base.duplicate_patched(["affordable_evs", "healthy_sobriety", "restoration_playbook",
		"coalition_diplomacy"])
	var after := FileAccess.get_file_as_string("res://data/cards.json")
	eq(before, after, "cards.json on disk never mutated")
	eq(float(base.card(&"DIP1")["cost_influence"]), 25.0, "in-memory base untouched by patching")


func test_knowledge_changes_gameplay() -> void:
	# A run with affordable_evs can buy TRA2 with 90 money; a plain run cannot.
	var rs := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), ["affordable_evs"])
	rs.money = 90.0
	eq(rs.can_play_reason(&"TRA2"), &"ok", "patched run affords TRA2 at 84")
	var rs_plain := RunState.new_run(WorldGen.generate(2030, true), Catalog.load_default(), [])
	rs_plain.money = 90.0
	eq(rs_plain.can_play_reason(&"TRA2"), &"no_money", "plain run cannot")
