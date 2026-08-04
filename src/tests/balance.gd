extends SceneTree
## Balance harness. Run from src/:
##   godot --headless -s res://tests/balance.gd
## N seeds × each bot profile, printed against the §7 done criteria.
## Rebalancing = edit JSON → run this → read the table.

const SEEDS := 40

const PROFILES := [
	{"label": "do-nothing", "buy": "none", "crisis": "default"},
	{"label": "greedy (temptations)", "buy": "greedy", "crisis": "default"},
	{"label": "clean/combo", "buy": "clean", "crisis": "default"},
	{"label": "clean, always-pay", "buy": "clean", "crisis": "pay"},
	{"label": "clean, always-absorb", "buy": "clean", "crisis": "absorb"},
	{"label": "clean, always-mortgage", "buy": "clean", "crisis": "mortgage"},
]


func _init() -> void:
	var catalog := Catalog.load_all()
	if catalog == null:
		quit(1)
		return
	print("\n%-24s %6s %9s %8s %8s %10s %s" % ["profile", "wins", "win yr", "loss yr", "temp", "pop-death", "combos/run"])
	for profile in PROFILES:
		var wins := 0
		var win_years := 0
		var loss_years := 0
		var losses := 0
		var temp_sum := 0.0
		var popularity_deaths := 0
		var combo_count := 0
		for seed_value in SEEDS:
			var r := Bots.play(catalog, 1000 + seed_value, profile.buy, profile.crisis)
			temp_sum += r.temp
			combo_count += r.combos.size()
			if r.won:
				wins += 1
				win_years += int(r.year)
			else:
				losses += 1
				loss_years += int(r.year)
				if String(r.cause).begins_with("Popularity"):
					popularity_deaths += 1
		var avg_win := ("%d" % (win_years / wins)) if wins > 0 else "—"
		var avg_loss := ("%d" % (loss_years / losses)) if losses > 0 else "—"
		print("%-24s %3d/%d %9s %8s %7.2f° %10d %10.1f" % [
			profile.label, wins, SEEDS, avg_win, avg_loss,
			temp_sum / SEEDS, popularity_deaths, float(combo_count) / SEEDS])
	print("\nTargets (§7): do-nothing loses 2042±1 · clean/combo bot (perfect play) wins 2044-2046,")
	print("predicting a human window of 2045-2050 · always-absorb should die (absorb only when flush)\n")
	quit(0)
