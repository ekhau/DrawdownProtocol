extends SceneTree
## Regenerates the golden regression fixture (canonical seed-2030 runs of the
## three scripted strategies) at res://tests/fixtures/seed2030_expected.csv.
## Run ONLY when a deliberate balance change is made; the diff is the design
## review artifact (docs/Phase_5/05, designer workflow step 3).
##   godot --headless --path src --script res://tools/gen_fixtures.gd

const OUT_PATH := "res://tests/fixtures/seed2030_expected.csv"


func _initialize() -> void:
	var lines: PackedStringArray = []
	for strat in Strategies.NAMES:
		var rs := Strategies.autoplay(strat, 2030, true)
		lines.append(BatchRunsTool.csv_row(2030, strat, rs))
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	print("wrote %s" % OUT_PATH)
	for l in lines:
		print("  " + l)
	quit(0)
