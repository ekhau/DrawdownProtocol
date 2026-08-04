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


## Projection behind the climate bar's ◆ marker: if the player keeps their
## recent pace of structural-net decline — absorption frozen at today's value,
## era floors respected — where does the mercury stand when net reaches zero?
## Pure read, no mutation. Returns {reachable, temp, year, pace}; when the pace
## can't get there before lose_temp, reachable is false and temp pins there.
static func neutrality_projection(state: RunState) -> Dictionary:
	var pace := _recent_pace(state)
	var p := _project(state, float(state.structural_net()), pace)
	p.pace = pace
	return p


## The 2.0° line on the emissions gauge: the highest gross emissions from which,
## at the current pace of cuts (absorption frozen, era floors respected), net
## zero still arrives before lose_temp. Gross above the line = losing course.
## With no pace, only fully-absorbed emissions are safe: the line sits at
## absorption, the edge of the green zone.
static func breakeven_gross(state: RunState) -> int:
	var pace := _recent_pace(state)
	var gross := state.absorption
	for _i in 500:
		if not bool(_project(state, float(gross + 1 - state.absorption), pace).reachable):
			return gross
		gross += 1
	return gross


## The shared forward simulation: from a hypothetical structural net, does the
## current pace reach zero before lose_temp, and where does the mercury stop?
static func _project(state: RunState, start_net: float, pace: float) -> Dictionary:
	var lose := float(state.catalog.config.lose_temp)
	var per_unit := float(state.catalog.config.warming_per_net_emission)
	if start_net <= 0.0:
		return {"reachable": true, "temp": state.temp, "year": state.year}
	if pace <= 0.0:
		return {"reachable": false, "temp": lose, "year": state.year}
	# This year's climate phase runs at today's net; cuts land in later years.
	var remaining := start_net
	var temp := state.temp + remaining * per_unit
	var year := state.year + 1
	for _i in 500:
		if temp >= lose:
			break
		remaining = maxf(remaining - pace, float(_era_floor_net(state, year)))
		if remaining <= 0.0:
			return {"reachable": true, "temp": temp, "year": year}
		temp += remaining * per_unit
		year += 1
	return {"reachable": false, "temp": lose, "year": year}


## Average structural-net decline per year over the last ≤3 years, counting
## this turn's purchases as the current year's progress (so buying a card
## moves the marker immediately).
static func _recent_pace(state: RunState) -> float:
	var span := mini(3, state.turn)
	var ref_index := state.history.size() - span
	var ref_net := 0
	if ref_index < 0:
		for s in state.catalog.config.sectors:
			ref_net += int(s.emissions)
		ref_net -= int(state.catalog.config.start_absorption)
	else:
		var snap: Dictionary = state.history[ref_index]
		for id in snap.sectors:
			ref_net += int(snap.sectors[id].emissions)
		ref_net -= int(snap.absorption)
	return float(ref_net - state.structural_net()) / float(span)


## Lowest structural net that year's era allows with absorption frozen at
## today's value — the hard-to-abate floors made visible to the projection,
## so the ◆ never promises a pre-Act-III win the floors forbid.
static func _era_floor_net(state: RunState, year: int) -> int:
	var floor_sum := 0
	for value in state.era_for_year(year).min_sector_emissions.values():
		floor_sum += int(value)
	return floor_sum - state.absorption


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
