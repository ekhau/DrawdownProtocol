class_name BatchRunsTool
extends SceneTree
## Headless batch harness (docs/Phase_3/05_Debug_View_Spec.md):
##   godot --headless --path src --script res://tools/batch_runs.gd -- \
##     --seeds 100 --strategy safe --csv out.csv [--canonical] [--start-seed 1]
## Runs N seeds x strategy through the real sim (no UI), writes one CSV row per
## run: seed, strategy, outcome, end_year, kp + decade samples of T/N/M/H
## (the docs/Phase_1/05_Balance_Bands.md metrics). Exits non-zero on any
## world-gen invariant violation or structural-outcome violation
## (safe/mixed must win, risky must never win) when --enforce is passed.

const DECADES := [2040, 2050, 2060, 2070, 2080, 2090, 2100]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seeds := 20
	var start_seed := 1
	var strategy := "all"
	var csv_path := ""
	var canonical := false
	var enforce := false
	var i := 0
	while i < args.size():
		match args[i]:
			"--seeds":
				i += 1
				seeds = int(args[i])
			"--start-seed":
				i += 1
				start_seed = int(args[i])
			"--strategy":
				i += 1
				strategy = args[i]
			"--csv":
				i += 1
				csv_path = args[i]
			"--canonical":
				canonical = true
			"--enforce":
				enforce = true
		i += 1

	var strategies: Array[StringName] = []
	if strategy == "all":
		strategies = Strategies.NAMES.duplicate()
	else:
		strategies = [StringName(strategy)]

	var lines: PackedStringArray = []
	var header := "seed,strategy,outcome,end_year,kp"
	for d in DECADES:
		header += ",T%d,N%d,M%d,H%d" % [d, d, d, d]
	lines.append(header)

	var violations := 0
	for s in range(start_seed, start_seed + seeds):
		for strat in strategies:
			var rs := Strategies.autoplay(strat, s, canonical)
			lines.append(csv_row(s, strat, rs))
			var last: TurnRecord = rs.records.back()
			var won := last.end_status == &"WIN_NEUTRAL"
			if strat == &"risky" and won:
				print("VIOLATION: risky won on seed %d" % s)
				violations += 1
			elif strat != &"risky" and not won:
				print("VIOLATION: %s lost on seed %d (%s, %d)" % [strat, s, last.end_status, last.year])
				violations += 1

	var out := "\n".join(lines) + "\n"
	if csv_path.is_empty():
		print(out)
	else:
		var f := FileAccess.open(csv_path, FileAccess.WRITE)
		f.store_string(out)
		print("wrote %s (%d rows)" % [csv_path, lines.size() - 1])
	print("batch done: %d runs, %d structural violations" % [seeds * strategies.size(), violations])
	quit(1 if (enforce and violations > 0) else 0)


static func csv_row(seed_v: int, strat: StringName, rs: RunState) -> String:
	var last: TurnRecord = rs.records.back()
	var row := "%d,%s,%s,%d,%d" % [seed_v, strat, last.end_status, last.year, last.kp_awarded]
	var by_year := {}
	for rec in rs.records:
		by_year[rec.year] = rec
	for d in DECADES:
		if by_year.has(d):
			var rec: TurnRecord = by_year[d]
			row += ",%.3f,%.2f,%.1f,%.1f" % [rec.temp, rec.net, rec.money, rec.happiness]
		else:
			row += ",,,,"  # run ended before this decade
	return row
