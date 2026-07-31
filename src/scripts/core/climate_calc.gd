class_name ClimateCalc
extends RefCounted
## Climate phase: net emissions -> warming, snapshot, win/lose check.
## Pure — mutates only through RunState setters.


static func run_phase(state: RunState) -> Dictionary:
	var gross := state.gross_emissions()
	var net := state.net_emissions()
	var warming := 0.0
	if net > 0:
		warming = net * float(state.catalog.config.warming_per_net_emission)
		state.add_temp(warming)
	state.log_event("Climate: gross %d − absorption %d = net %d → %+.3f° (now %.2f°)" % [
		gross, state.absorption, net, warming, state.temp])
	state.snapshot()

	if state.structural_net() <= 0:
		state.end_run(true, "Net emissions reached zero — the drawdown begins.")
	elif state.temp >= float(state.catalog.config.lose_temp):
		state.end_run(false, _cause_of_loss(state))
	return {"gross": gross, "net": net, "warming": warming}


## One-line post-mortem cause: the sector that decarbonized least.
static func _cause_of_loss(state: RunState) -> String:
	var worst_id := ""
	var worst := 1.1
	for id in state.sectors:
		var d := state.decarbonization(id)
		if d < worst:
			worst = d
			worst_id = id
	var name: String = state.sectors[worst_id].name
	if worst <= 0.0:
		return "+2.0° reached. %s never decarbonized." % name
	return "+2.0° reached. %s was cut only %d%%." % [name, int(worst * 100)]
