extends SceneTree
## Headless test runner:
##   godot --headless --path src --script res://tests/run_tests.gd
## Discovers test_*.gd suites listed below, runs every test_* method,
## prints a summary, exits non-zero on any failure.

const SUITE_PATHS: Array[String] = [
	"res://tests/test_seed_util.gd",
	"res://tests/test_worldgen.gd",
	"res://tests/test_climate_calc.gd",
	"res://tests/test_evaluator.gd",
	"res://tests/test_resolver.gd",
	"res://tests/test_society.gd",
	"res://tests/test_crises.gd",
	"res://tests/test_combos.gd",
	"res://tests/test_projects.gd",
	"res://tests/test_market.gd",
	"res://tests/test_world.gd",
	"res://tests/test_pipeline.gd",
	"res://tests/test_knowledge.gd",
	"res://tests/test_postmortem.gd",
	"res://tests/test_validator.gd",
	"res://tests/test_board_layout.gd",
	"res://tests/test_fixtures.gd",
]


func _initialize() -> void:
	var total_checks := 0
	var total_failures := 0
	var failed_suites: PackedStringArray = []
	print("=== The Drawdown Protocol - headless test run ===")
	for path in SUITE_PATHS:
		var script: GDScript = load(path)
		if script == null:
			print("  [LOAD FAIL] %s" % path)
			total_failures += 1
			failed_suites.append(path)
			continue
		var suite: TestBase = script.new()
		suite.suite_name = path.get_file()
		var methods: PackedStringArray = []
		for m in suite.get_method_list():
			if String(m["name"]).begins_with("test_"):
				methods.append(m["name"])
		for method in methods:
			suite.call(method)
		total_checks += suite.checks
		if suite.failures.is_empty():
			print("  [ OK ] %-28s %3d checks" % [suite.suite_name, suite.checks])
		else:
			print("  [FAIL] %-28s %3d checks, %d failures:" % [suite.suite_name, suite.checks, suite.failures.size()])
			for f in suite.failures:
				print("         - %s" % f)
			total_failures += suite.failures.size()
			failed_suites.append(suite.suite_name)
	print("=== %d checks, %d failures ===" % [total_checks, total_failures])
	if total_failures > 0:
		print("FAILED suites: %s" % ", ".join(failed_suites))
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)
