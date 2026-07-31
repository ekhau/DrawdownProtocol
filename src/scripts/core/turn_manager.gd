class_name TurnManager
extends RefCounted
## The composition root of one run and its phase state machine:
## Crisis (player choice) → Action (player buys/rerolls/ends) → Income → Climate (auto).
## Exposes the five verbs the UI may call: new run is _init; then
## choose_response(i) / buy_card(id) / reroll() / end_turn().
## Pure — no Nodes; drives everything through Effects and the sub-systems.

var state: RunState
var market: Market
var crisis_deck: CrisisDeck
var combo_checker: ComboChecker
var current_era_id: String = ""


func _init(catalog: Catalog, seed_value: int) -> void:
	state = RunState.new(catalog, seed_value)
	market = Market.new(state)
	crisis_deck = CrisisDeck.new(state)
	combo_checker = ComboChecker.new(state)
	current_era_id = state.era_for_year(state.year).id
	state.log_event("Timeline seed %d — %d, %.2f°. The run begins." % [seed_value, state.year, state.temp])
	_start_turn()


# --- the five verbs -----------------------------------------------------------

func choose_response(index: int) -> bool:
	if state.ended or state.phase != RunState.Phase.CRISIS:
		return false
	if not crisis_deck.choose(index):
		return false
	if _check_support_collapse():
		return true
	state.set_phase(RunState.Phase.ACTION)
	return true


func buy_card(card_id: String) -> bool:
	if state.ended or state.phase != RunState.Phase.ACTION:
		return false
	if not market.buy(card_id):
		return false
	combo_checker.check()
	_check_support_collapse()
	return true


func reroll() -> bool:
	if state.ended or state.phase != RunState.Phase.ACTION:
		return false
	return market.reroll()


func end_turn() -> bool:
	if state.ended or state.phase != RunState.Phase.ACTION:
		return false
	# Income phase
	state.set_phase(RunState.Phase.INCOME)
	var income := state.total_income()
	Effects.apply([{"type": "money", "amount": income}], "Income", state)
	# Climate phase
	state.set_phase(RunState.Phase.CLIMATE)
	ClimateCalc.run_phase(state)
	if state.ended:
		return true
	# Next year
	state.turn += 1
	state.year += 1
	_start_turn()
	return true


# --- internals ----------------------------------------------------------------

func _start_turn() -> void:
	state.gross_this_turn_delta = 0
	market.on_turn_start()
	var era := state.era_for_year(state.year)
	if era.id != current_era_id:
		current_era_id = era.id
		state.log_event("=== %s — %s ===" % [era.name, era.banner])
		market.refresh()  # free era refresh
		state.era_started.emit(era.id)
	if state.turn >= int(state.catalog.config.crisis_start_turn):
		state.set_phase(RunState.Phase.CRISIS)
		crisis_deck.draw()
	else:
		state.set_phase(RunState.Phase.ACTION)


func _check_support_collapse() -> bool:
	if not state.ended and state.support <= 0:
		state.snapshot()
		state.end_run(false, "Support collapsed — the city voted the Institute out.")
		return true
	return false
