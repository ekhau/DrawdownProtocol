class_name ClimateCalc
extends RefCounted
## Climate phase: net emissions -> warming, tipping points, snapshot, win/lose.
## Pure — mutates only through RunState setters and Effects.apply.


static func run_phase(state: RunState) -> Dictionary:
	var gross := state.gross_emissions()
	var net := state.net_emissions()
	var warming := 0.0
	if net > 0:
		warming = net * float(state.catalog.config.warming_per_net_emission)
		state.add_temp(warming)
	state.log_event("Climate: gross %d − absorption %d = net %d → %+.3f° (now %.2f°)" % [
		gross, state.absorption, net, warming, state.temp])
	# The planet doesn't wait for the press conference: thresholds crossed by
	# this year's warming scar the world BEFORE the win check — a dieback can
	# legitimately steal a same-year win.
	_process_crossings(state)
	state.snapshot()

	if state.structural_net() <= 0:
		state.end_run(true, "Net emissions reached zero — the drawdown begins.")
	elif state.temp >= float(state.catalog.config.lose_temp):
		state.end_run(false, _cause_of_loss(state))
	return {"gross": gross, "net": net, "warming": warming}


## Fire every not-yet-crossed tipping point the mercury has reached, in
## ascending threshold order (a hot year can cross two at once). Each fires at
## most once per run; deterministic, no RNG. The catalog guarantees the config
## list is sorted ascending at load.
static func _process_crossings(state: RunState) -> void:
	for tp in state.catalog.config.tipping_points:
		if state.crossed_tipping_points.has(tp.id):
			continue
		if state.temp < float(tp.temp):
			continue
		state.crossed_tipping_points.append(tp.id)
		state.log_event("☠ TIPPING POINT — %s (+%.2f°): %s" % [tp.name, float(tp.temp), tp.flavor])
		Effects.apply(tp.effects, tp.name, state)
		state.tipping_point_crossed.emit(tp.id)


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
## The ◆ prices the future honestly: when the projected mercury crosses a
## not-yet-crossed tipping point, its NET-relevant scars apply from that
## projected year on — planetary emissions join the remaining net AND the era
## floor (they are uncuttable), diebacks eat the frozen absorption (floor 0).
## Income/popularity scars are ignored here: they don't move the thermometer.
static func _project(state: RunState, start_net: float, pace: float) -> Dictionary:
	var lose := float(state.catalog.config.lose_temp)
	var per_unit := float(state.catalog.config.warming_per_net_emission)
	if start_net <= 0.0:
		return {"reachable": true, "temp": state.temp, "year": state.year}
	if pace <= 0.0:
		return {"reachable": false, "temp": lose, "year": state.year}
	var pending := _pending_tipping_points(state)
	# world: planetary emissions gained by PROJECTED crossings only — today's are
	# already inside start_net and the floor. absorption: frozen at today's
	# value, then eaten by projected diebacks. remaining: the walking net.
	var proj := {"world": 0, "absorption": state.absorption, "remaining": start_net}
	# This year's climate phase runs at today's net; cuts land in later years.
	var temp: float = state.temp + proj.remaining * per_unit
	_apply_projected_crossings(pending, temp, proj)
	var year := state.year + 1
	for _i in 500:
		if temp >= lose:
			break
		proj.remaining = maxf(proj.remaining - pace, float(_era_floor_net(state, year, proj)))
		if proj.remaining <= 0.0:
			return {"reachable": true, "temp": temp, "year": year}
		temp += proj.remaining * per_unit
		_apply_projected_crossings(pending, temp, proj)
		year += 1
	return {"reachable": false, "temp": lose, "year": year}


static func _pending_tipping_points(state: RunState) -> Array:
	var out := []
	for tp in state.catalog.config.tipping_points:  # sorted ascending at load
		if not state.crossed_tipping_points.has(tp.id):
			out.append(tp)
	return out


## Mirror of _process_crossings for the projection walk: pops every pending
## point the projected mercury has reached and folds its net-relevant effects
## into the projection state (see _project).
static func _apply_projected_crossings(pending: Array, temp: float, proj: Dictionary) -> void:
	while not pending.is_empty() and temp >= float(pending[0].temp):
		var tp: Dictionary = pending.pop_front()
		for atom in tp.effects:
			match atom.type:
				"world_emissions":
					proj.world += int(atom.amount)
					proj.remaining += int(atom.amount)
				"absorption":
					if int(atom.amount) < 0:
						var eaten: int = int(proj.absorption) - maxi(0, int(proj.absorption) + int(atom.amount))
						proj.absorption -= eaten
						proj.remaining += eaten


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
		ref_net += int(snap.get("world_emissions", 0))
		ref_net -= int(snap.absorption)
	return float(ref_net - state.structural_net()) / float(span)


## Lowest structural net that year's era allows under the projection's frozen
## assumptions — hard-to-abate floors plus uncuttable planetary emissions
## (today's and the projection's own), minus the projected absorption. The ◆
## never promises a pre-Act-III win the floors forbid.
static func _era_floor_net(state: RunState, year: int, proj: Dictionary) -> int:
	var floor_sum := 0
	for value in state.era_for_year(year).min_sector_emissions.values():
		floor_sum += int(value)
	return floor_sum + state.world_emissions + int(proj.world) - int(proj.absorption)


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
