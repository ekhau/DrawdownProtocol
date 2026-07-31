extends TestBase
## T1-P5 (shipped catalogs pass) and T2-P5 (mutation suite: broken variants
## are rejected with the right rule id) over the crisis/combo/project schema.


func _docs() -> Dictionary:
	return {
		"cards": JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json")),
		"events": JSON.parse_string(FileAccess.get_file_as_string("res://data/events.json")),
		"knowledge": JSON.parse_string(FileAccess.get_file_as_string("res://data/knowledge.json")),
		"templates": JSON.parse_string(FileAccess.get_file_as_string("res://data/log_templates.json")),
		"tutorial": JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorial.json")),
		"combos": JSON.parse_string(FileAccess.get_file_as_string("res://data/combos.json")),
		"projects": JSON.parse_string(FileAccess.get_file_as_string("res://data/projects.json")),
		"actors": JSON.parse_string(FileAccess.get_file_as_string("res://data/world_actors.json")),
		"archetypes": JSON.parse_string(FileAccess.get_file_as_string("res://data/city_archetypes.json")),
		"summits": JSON.parse_string(FileAccess.get_file_as_string("res://data/summits.json")),
	}


func _validate(d: Dictionary) -> DataValidator:
	var v := DataValidator.new()
	v.validate_all(d["cards"], d["events"], d["knowledge"], d["templates"],
		d["tutorial"], d["combos"], d["projects"], d["actors"], d["archetypes"],
		d["summits"])
	return v


func test_shipped_catalogs_pass() -> void:  # T1-P5
	var v := _validate(_docs())
	eq(v.errors.size(), 0, "zero errors on shipped catalogs: %s" % "; ".join(v.errors))
	eq(v.warnings.size(), 0, "zero warnings on shipped catalogs: %s" % "; ".join(v.warnings))


func _expect_rule(v: DataValidator, rule: String, msg: String) -> void:
	var found := false
	for e in v.errors:
		if e.begins_with(rule):
			found = true
	check(found, "%s (errors: %s)" % [msg, "; ".join(v.errors)])


func _expect_warning(v: DataValidator, rule: String, msg: String) -> void:
	var found := false
	for w in v.warnings:
		if w.begins_with(rule):
			found = true
	check(found, "%s (warnings: %s)" % [msg, "; ".join(v.warnings)])


func test_mutation_duplicate_card_id() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	d["cards"]["cards"][1]["id"] = "IND1"
	_expect_rule(_validate(d), "C2", "duplicate card id rejected (C2)")


func test_mutation_bad_category() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	d["cards"]["cards"][0]["category"] = "banking"
	_expect_rule(_validate(d), "C3", "unknown category rejected (C3)")


func test_mutation_negative_cost() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	d["cards"]["cards"][0]["cost_money"] = -10
	_expect_rule(_validate(d), "C4", "negative cost rejected (C4)")


func test_mutation_unknown_op() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	d["cards"]["cards"][0]["effects"] = [{"op": "geoengineer", "amount": 99}]
	_expect_rule(_validate(d), "C5", "unknown op rejected (C5)")


func test_mutation_sufficiency_mismatch() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	# IND1 has no lifts_cap effect; tag it sufficiency.
	d["cards"]["cards"][0]["tags"] = ["sufficiency"]
	_expect_rule(_validate(d), "C6", "sufficiency tag without lifts_cap rejected (C6)")
	d = _docs()
	d["cards"] = d["cards"].duplicate(true)
	# TRA1 lifts cap; remove its tag.
	for c in d["cards"]["cards"]:
		if c["id"] == "TRA1":
			c["tags"] = ["mobility", "health"]
	_expect_rule(_validate(d), "C6", "lifts_cap without sufficiency tag rejected (C6)")


func test_mutation_long_name() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	d["cards"]["cards"][0]["name"] = "A Very Long Card Name Indeed Beyond Limit"
	_expect_rule(_validate(d), "C2", "over-long name rejected (C2)")


func test_mutation_bad_reward_key() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	d["cards"]["cards"][0]["rewards"] = {"reputation": 5}
	_expect_rule(_validate(d), "C10", "unknown reward key rejected (C10)")


func test_mutation_bad_unlock() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	d["cards"]["cards"][0]["unlock"] = {"kind": "moon_landing", "count": 1}
	_expect_rule(_validate(d), "C11", "unknown unlock kind rejected (C11)")


func test_mutation_unknown_tag() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	d["cards"]["cards"][0]["tags"] = ["vibes"]
	_expect_rule(_validate(d), "C12", "unknown tag rejected (C12)")


func test_mutation_decreasing_crisis_weights() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	d["events"]["events"][0]["weights"] = [2.0, 1.0, 0.5]
	_expect_rule(_validate(d), "E3", "decreasing crisis weights rejected (E3)")


func test_mutation_bad_target_tag() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	d["events"]["events"][2]["target"]["tags_any"] = ["volcanic"]
	_expect_rule(_validate(d), "E4", "unknown target tag rejected (E4)")


func test_mutation_unknown_damage() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	d["events"]["events"][0]["damages"] = {"reputation": 5}
	_expect_rule(_validate(d), "E5", "unknown damage key rejected (E5)")


func test_mutation_opportunity_with_damages() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	for e in d["events"]["events"]:
		if e["id"] == "climate_summit":
			e["damages"] = {"money": 10}
	_expect_rule(_validate(d), "E5", "opportunity with damages rejected (E5)")


func test_mutation_unknown_flag() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	d["events"]["events"][2]["opportunity"] = {"set_flag": "mystery_bonus", "teaser": "?"}
	_expect_rule(_validate(d), "E6", "unknown consumable flag rejected (E6)")


func test_mutation_duplicate_order() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	d["events"]["events"][1]["order"] = 10
	_expect_rule(_validate(d), "E1", "duplicate event order rejected (E1)")


func test_mutation_missing_response() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	d["events"]["events"][0].erase("response")
	_expect_rule(_validate(d), "E9", "crisis without a response rejected (E9)")


func test_mutation_unanswerable_crisis() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	d["cards"] = d["cards"].duplicate(true)
	# Make drought's only answer a tag that exists solely on an unlockable card.
	for c in d["cards"]["cards"]:
		if not c.has("unlock") and (c["tags"] as Array).has("water"):
			c["tags"].erase("water")
	d["events"]["events"][0]["response"] = {"tags_any": ["water"], "rewards": {}}
	_expect_rule(_validate(d), "E10", "crisis unanswerable at run start rejected (E10)")


func test_mutation_feedback_with_weights() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	for e in d["events"]["events"]:
		if e["id"] == "permafrost_methane":
			e["weights"] = [0.1, 0.1, 0.1]
	_expect_rule(_validate(d), "E2", "feedback with weights rejected (E2)")


func test_mutation_combo_single_tag() -> void:
	var d := _docs()
	d["combos"] = d["combos"].duplicate(true)
	d["combos"]["combos"][0]["tags_required"] = ["energy"]
	_expect_rule(_validate(d), "CB2", "single-tag combo rejected (CB2)")


func test_mutation_combo_unknown_tag() -> void:
	var d := _docs()
	d["combos"] = d["combos"].duplicate(true)
	d["combos"]["combos"][0]["tags_required"] = ["energy", "vibes"]
	_expect_rule(_validate(d), "CB2", "unknown combo tag rejected (CB2)")


func test_mutation_combo_no_payoff() -> void:
	var d := _docs()
	d["combos"] = d["combos"].duplicate(true)
	d["combos"]["combos"][0]["rewards"] = {}
	d["combos"]["combos"][0]["effects"] = []
	_expect_rule(_validate(d), "CB3", "payoff-free combo rejected (CB3)")


func test_mutation_combo_forbidden_op() -> void:
	var d := _docs()
	d["combos"] = d["combos"].duplicate(true)
	d["combos"]["combos"][0]["effects"] = [{"op": "ally"}]
	_expect_rule(_validate(d), "CB4", "ally op in combo rejected (CB4)")


func test_mutation_combo_single_card_coverage() -> void:
	var d := _docs()
	d["combos"] = d["combos"].duplicate(true)
	# TRA1 carries mobility+health: a combo needing exactly those is a one-card combo.
	d["combos"]["combos"][0]["tags_required"] = ["mobility", "health"]
	_expect_warning(_validate(d), "CB5", "single-card combo coverage warned (CB5)")


func test_mutation_project_turns_range() -> void:
	var d := _docs()
	d["projects"] = d["projects"].duplicate(true)
	d["projects"]["projects"][0]["turns"] = 1
	_expect_rule(_validate(d), "PR1", "1-turn project rejected (PR1)")


func test_mutation_bad_risk_chance() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	for c in d["cards"]["cards"]:
		if c["id"] == "RND1":
			c["risk"]["chance"] = 1.0
	_expect_rule(_validate(d), "C13", "certain 'risk' rejected - odds must be honest (C13)")


func test_mutation_risk_forbidden_op() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	for c in d["cards"]["cards"]:
		if c["id"] == "RND2":
			c["risk"]["on_success"]["effects"] = [{"op": "media"}]
	_expect_rule(_validate(d), "C13", "media op in a risk branch rejected (C13)")


func test_mutation_codex_too_short() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	d["cards"]["cards"][0]["codex"] = {"title": "x", "body": "too short"}
	_expect_rule(_validate(d), "C14", "stub codex body rejected (C14)")


func test_mutation_meta_unlock_bad_ending() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	for c in d["cards"]["cards"]:
		if c["id"] == "SOC4":
			c["meta_unlock"] = {"on": "LOSS_BOREDOM"}
	_expect_rule(_validate(d), "C15", "meta_unlock on unknown ending rejected (C15)")


func test_mutation_on_draw_on_opportunity() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	for e in d["events"]["events"]:
		if e["id"] == "climate_summit":
			e["on_draw"] = {"e_extra": 1.0}
	_expect_rule(_validate(d), "E7", "on_draw on an opportunity rejected (E7)")


func test_mutation_bonus_card_unknown() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	for e in d["events"]["events"]:
		if e["id"] == "heat_wave":
			e["bonus_card"]["card"] = "ZZZ9"
	_expect_rule(_validate(d), "E8", "bonus_card to unknown card rejected (E8)")


func test_mutation_actor_floor() -> void:
	var d := _docs()
	d["actors"] = d["actors"].duplicate(true)
	d["actors"]["actors"][0]["floor"] = 0.0
	_expect_rule(_validate(d), "A2", "zero actor floor rejected (A2)")


func test_mutation_no_locked_archetype() -> void:
	var d := _docs()
	d["archetypes"] = d["archetypes"].duplicate(true)
	for a in d["archetypes"]["archetypes"]:
		a.erase("unlock")
	_expect_rule(_validate(d), "Y3", "all-unlocked archetypes rejected (Y3: meta-progression)")


func test_mutation_summit_bad_metric() -> void:
	var d := _docs()
	d["summits"] = d["summits"].duplicate(true)
	d["summits"]["summits"][0]["goal"] = {"metric": "vibes", "lte": 10}
	_expect_rule(_validate(d), "S2", "unknown summit metric rejected (S2)")


func test_mutation_summit_without_penalty() -> void:
	var d := _docs()
	d["summits"] = d["summits"].duplicate(true)
	d["summits"]["summits"][0].erase("penalty")
	_expect_rule(_validate(d), "S3", "penalty-free summit rejected (S3: failure must matter)")


func test_mutation_project_free_upkeep() -> void:
	var d := _docs()
	d["projects"] = d["projects"].duplicate(true)
	d["projects"]["projects"][0]["upkeep_money"] = 0
	d["projects"]["projects"][0]["upkeep_influence"] = 0
	_expect_rule(_validate(d), "PR1", "free project rejected (PR1)")


func test_mutation_project_unknown_passive() -> void:
	var d := _docs()
	d["projects"] = d["projects"].duplicate(true)
	d["projects"]["projects"][0]["completion"]["passive"] = {"win_button": 1}
	_expect_rule(_validate(d), "PR2", "unknown passive rejected (PR2)")


func test_mutation_project_missing_penalty() -> void:
	var d := _docs()
	d["projects"] = d["projects"].duplicate(true)
	d["projects"]["projects"][0].erase("abandon_penalty")
	_expect_rule(_validate(d), "PR3", "missing abandon penalty rejected (PR3)")


func test_mutation_knowledge_unknown_card() -> void:
	var d := _docs()
	d["knowledge"] = d["knowledge"].duplicate(true)
	d["knowledge"]["nodes"][0]["patch"] = {"card": "ZZZ9", "cost_money": 1}
	_expect_rule(_validate(d), "K1", "patch referencing unknown card rejected (K1)")


func test_mutation_knowledge_cost_range() -> void:
	var d := _docs()
	d["knowledge"] = d["knowledge"].duplicate(true)
	d["knowledge"]["nodes"][0]["kp_cost"] = 99
	_expect_rule(_validate(d), "K1", "kp_cost out of 1-20 rejected (K1)")


func test_mutation_tutorial_bad_target() -> void:
	var d := _docs()
	d["tutorial"] = d["tutorial"].duplicate(true)
	d["tutorial"]["steps"][0]["target"] = "minimap"
	_expect_rule(_validate(d), "TU3", "unknown tutorial target rejected (TU3)")


func test_mutation_tutorial_bad_signal() -> void:
	var d := _docs()
	d["tutorial"] = d["tutorial"].duplicate(true)
	d["tutorial"]["steps"][0]["advance"] = {"type": "signal", "signal": "meteor_struck"}
	_expect_rule(_validate(d), "TU4", "unknown advance signal rejected (TU4)")


func test_mutation_tutorial_empty_text() -> void:
	var d := _docs()
	d["tutorial"] = d["tutorial"].duplicate(true)
	d["tutorial"]["steps"][1]["text"] = ""
	_expect_rule(_validate(d), "TU2", "empty step text rejected (TU2)")


func test_tutorial_signals_match_layer_vocabulary() -> void:
	# Every advance signal in the shipped steps must be one the TutorialLayer
	# can actually receive via Main's notify() hooks.
	var doc: Dictionary = _docs()["tutorial"]
	for s: Dictionary in doc["steps"]:
		var advance: Dictionary = s.get("advance", {})
		if String(advance.get("type", "")) == "signal":
			check(DataValidator.TUTORIAL_SIGNALS.has(String(advance.get("signal", ""))),
				"step %s uses a wired signal" % s.get("id", "?"))


func test_mutation_missing_template() -> void:
	var d := _docs()
	d["templates"] = d["templates"].duplicate(true)
	d["templates"]["events"].erase("heat_wave_hit")
	_expect_rule(_validate(d), "T1", "missing crisis template rejected (T1)")
	d = _docs()
	d["templates"] = d["templates"].duplicate(true)
	d["templates"]["events"].erase("climate_summit_seized")
	_expect_rule(_validate(d), "T1", "missing opportunity template rejected (T1)")
	d = _docs()
	d["templates"] = d["templates"].duplicate(true)
	d["templates"]["system"].erase("combo")
	_expect_rule(_validate(d), "T1", "missing combo template rejected (T1)")


func test_additive_bonus_card_is_regression_free() -> void:  # T10-P5 (rework)
	# The market deals from the whole pool, so a NORMAL additive card now
	# legitimately shifts timelines (it changes the deal). The additive
	# guarantee holds for bonus-only cards: outside the pool until an event
	# injects them, so appending one must leave fixtures byte-identical.
	var baseline := _fixture_lines()
	var cards_doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	cards_doc = cards_doc.duplicate(true)
	cards_doc["cards"].append({
		"id": "SOC9", "name": "Dummy Test Card", "category": "society",
		"cost_money": 10, "cost_influence": 0, "requires": {}, "tags": [],
		"bonus_only": true,
		"effects": [{"op": "wellbeing", "amount": 1}],
	})
	var cat := Catalog.new()
	cat._load_from(cards_doc,
		JSON.parse_string(FileAccess.get_file_as_string("res://data/events.json")),
		JSON.parse_string(FileAccess.get_file_as_string("res://data/knowledge.json")),
		JSON.parse_string(FileAccess.get_file_as_string("res://data/combos.json")),
		JSON.parse_string(FileAccess.get_file_as_string("res://data/projects.json")))
	cat._load_world(
		JSON.parse_string(FileAccess.get_file_as_string("res://data/world_actors.json")),
		JSON.parse_string(FileAccess.get_file_as_string("res://data/city_archetypes.json")),
		JSON.parse_string(FileAccess.get_file_as_string("res://data/summits.json")))
	var with_dummy := _fixture_lines_with_catalog(cat)
	eq(baseline, with_dummy, "adding a bonus-only card leaves the seed-2030 fixtures byte-identical")


func _fixture_lines() -> String:
	return _fixture_lines_with_catalog(Catalog.load_default())


func _fixture_lines_with_catalog(cat: Catalog) -> String:
	var out: PackedStringArray = []
	for strat: StringName in [&"safe", &"risky"]:
		var gen := WorldGen.generate(2030, true)
		var rs := RunState.new_run(gen, cat, [])
		var guard := 60
		while rs.phase != RunState.Phase.ENDED and guard > 0:
			guard -= 1
			Strategies.play_turn(strat, rs)
		out.append(BatchRunsTool.csv_row(2030, strat, rs))
	return "\n".join(out)