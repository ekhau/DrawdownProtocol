extends TestBase
## T1-P5 (shipped catalogs pass) and T2-P5 (mutation suite: broken variants
## are rejected with the right rule id).


func _docs() -> Dictionary:
	return {
		"cards": JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json")),
		"events": JSON.parse_string(FileAccess.get_file_as_string("res://data/events.json")),
		"knowledge": JSON.parse_string(FileAccess.get_file_as_string("res://data/knowledge.json")),
		"templates": JSON.parse_string(FileAccess.get_file_as_string("res://data/log_templates.json")),
		"tutorial": JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorial.json")),
	}


func _validate(d: Dictionary) -> DataValidator:
	var v := DataValidator.new()
	v.validate_all(d["cards"], d["events"], d["knowledge"], d["templates"], d["tutorial"])
	return v


func test_shipped_catalogs_pass() -> void:  # T1-P5
	var v := _validate(_docs())
	eq(v.errors.size(), 0, "zero errors on shipped catalogs: %s" % "; ".join(v.errors))
	eq(v.warnings.size(), 1, "exactly the documented warning set")
	check(v.warnings.size() == 1 and v.warnings[0].begins_with("E7"),
		"the one warning is heat_wave E7 (no opportunity rider)")


func _expect_rule(v: DataValidator, rule: String, msg: String) -> void:
	var found := false
	for e in v.errors:
		if e.begins_with(rule):
			found = true
	check(found, "%s (errors: %s)" % [msg, "; ".join(v.errors)])


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
			c["tags"] = []
	_expect_rule(_validate(d), "C6", "lifts_cap without sufficiency tag rejected (C6)")


func test_mutation_long_name() -> void:
	var d := _docs()
	d["cards"] = d["cards"].duplicate(true)
	d["cards"]["cards"][0]["name"] = "A Very Long Card Name Indeed Beyond Limit"
	_expect_rule(_validate(d), "C2", "over-long name rejected (C2)")


func test_mutation_decreasing_probabilities() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	d["events"]["events"][0]["probabilities"] = [0.40, 0.25, 0.10]
	_expect_rule(_validate(d), "E3", "decreasing probabilities rejected (E3)")


func test_mutation_bad_target_tag() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	d["events"]["events"][1]["target"]["tags_any"] = ["volcanic"]
	_expect_rule(_validate(d), "E4", "unknown target tag rejected (E4)")


func test_mutation_unknown_damage() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	d["events"]["events"][0]["damages"] = {"reputation": 5}
	_expect_rule(_validate(d), "E5", "unknown damage key rejected (E5)")


func test_mutation_unknown_flag() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	d["events"]["events"][1]["opportunity"] = {"set_flag": "mystery_bonus", "teaser": "?"}
	_expect_rule(_validate(d), "E6", "unknown consumable flag rejected (E6)")


func test_mutation_duplicate_order() -> void:
	var d := _docs()
	d["events"] = d["events"].duplicate(true)
	d["events"]["events"][1]["order"] = 10
	_expect_rule(_validate(d), "E1", "duplicate event order rejected (E1)")


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
	_expect_rule(_validate(d), "T1", "missing event template rejected (T1)")


func test_additive_card_is_regression_free() -> void:  # T10-P5
	# Append a dummy 16th card via the authoring template: fixtures must not move.
	var baseline := _fixture_lines()
	var cards_doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	cards_doc = cards_doc.duplicate(true)
	cards_doc["cards"].append({
		"id": "SOC3", "name": "Dummy Test Card", "category": "society",
		"cost_money": 10, "cost_influence": 0, "requires": {}, "tags": [],
		"effects": [{"op": "wellbeing", "amount": 1}],
	})
	var cat := Catalog.new()
	cat._load_from(cards_doc,
		JSON.parse_string(FileAccess.get_file_as_string("res://data/events.json")),
		JSON.parse_string(FileAccess.get_file_as_string("res://data/knowledge.json")))
	var with_dummy := _fixture_lines_with_catalog(cat)
	eq(baseline, with_dummy, "adding an unused card leaves the seed-2030 fixtures byte-identical")


func _fixture_lines() -> String:
	return _fixture_lines_with_catalog(Catalog.load_default())


func _fixture_lines_with_catalog(cat: Catalog) -> String:
	var out: PackedStringArray = []
	for strat: StringName in [&"safe", &"risky"]:
		var gen := WorldGen.generate(2030, true)
		var rs := RunState.new_run(gen, cat, [])
		var guard := 100
		while rs.phase != RunState.Phase.ENDED and guard > 0:
			guard -= 1
			var choice := Strategies.decide(strat, rs)
			if choice["card"] != &"pass":
				rs.play_card(choice["card"], choice["target"])
			rs.resolve_year()
		out.append(BatchRunsTool.csv_row(2030, strat, rs))
	return "\n".join(out)
