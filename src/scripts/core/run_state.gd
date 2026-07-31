class_name RunState
extends RefCounted
## THE game state: resources, sectors, thermometer, owned cards, history.
## Pure — no Nodes. All mutation goes through Effects.apply() (the single door);
## the setters here are for Effects and the phase machinery only.
## UI learns everything from these signals and may never write back.

signal resources_changed
signal sector_changed(sector_id: String)
signal temperature_changed(temp: float)
signal phase_changed(phase: int)
signal combo_discovered(combo_id: String)
signal era_started(era_id: String)
signal log_line(text: String)
signal run_ended(result: Dictionary)

enum Phase { CRISIS, ACTION, INCOME, CLIMATE, ENDED }

var catalog: Catalog
var rng := RandomNumberGenerator.new()
var run_seed: int = 0

var turn: int = 0                  # 1-based; year = start_year + turn - 1
var year: int = 0
var phase: int = Phase.ACTION
var temp: float = 0.0
var money: int = 0
var support: int = 0
var absorption: int = 0
var income_bonus: int = 0          # flat $/turn from income_per_turn atoms
var gross_this_turn_delta: int = 0 # transient, reset each turn (e.g. Mild Winter)
var sectors: Dictionary = {}       # id -> {name, emissions, income, start_emissions}
var owned_cards: Array = []        # card ids, purchase order
var discovered_combos: Array = []
var history: Array = []            # one snapshot per climate phase
var ended: bool = false
var result: Dictionary = {}


func _init(cat: Catalog, seed_value: int) -> void:
	catalog = cat
	run_seed = seed_value
	rng.seed = seed_value
	var cfg := cat.config
	turn = 1
	year = int(cfg.start_year)
	temp = float(cfg.start_temp)
	money = int(cfg.start_money)
	support = int(cfg.start_support)
	absorption = int(cfg.start_absorption)
	for s in cfg.sectors:
		sectors[s.id] = {
			"name": s.name,
			"emissions": int(s.emissions),
			"income": int(s.income),
			"start_emissions": int(s.emissions),
		}


# --- derived values -----------------------------------------------------------

func gross_emissions() -> int:
	var total := 0
	for id in sectors:
		total += sectors[id].emissions
	return maxi(0, total + gross_this_turn_delta)


func net_emissions() -> int:
	return gross_emissions() - absorption


## Net without transient effects (e.g. Mild Winter). Winning requires
## STRUCTURAL neutrality — a lucky warm year slows the clock but is not a win.
func structural_net() -> int:
	var total := 0
	for id in sectors:
		total += sectors[id].emissions
	return total - absorption


func total_income() -> int:
	var total := income_bonus
	for id in sectors:
		total += sectors[id].income
	return maxi(0, total)


func band() -> Dictionary:
	var current: Dictionary = catalog.config.bands[0]
	for b in catalog.config.bands:
		if temp >= float(b.min_temp):
			current = b
	return current


func era_for_year(y: int) -> Dictionary:
	var current: Dictionary = catalog.config.eras[0]
	for e in catalog.config.eras:
		if y >= int(e.from_year):
			current = e
	return current


func decarbonization(sector_id: String) -> float:
	var s: Dictionary = sectors[sector_id]
	if s.start_emissions <= 0:
		return 1.0
	return 1.0 - float(s.emissions) / float(s.start_emissions)


# --- setters (Effects + phase machinery only — never UI) ----------------------

func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	resources_changed.emit()


func add_support(amount: int) -> void:
	support = mini(support + amount, int(catalog.config.support_cap))
	resources_changed.emit()


func add_absorption(amount: int) -> void:
	absorption = maxi(0, absorption + amount)
	resources_changed.emit()


func add_sector_emissions(sector_id: String, amount: int) -> void:
	var before: int = sectors[sector_id].emissions
	var target := maxi(0, before + amount)
	if amount < 0:
		# Hard-to-abate floor: this era's tech can't cut below it (depth over time,
		# made mechanical — net zero needs Act III). Wasted cuts are logged, never silent.
		var floor_value := sector_floor(sector_id)
		if target < floor_value:
			target = mini(before, floor_value)
			log_event("%s is at this era's hard-to-abate floor (%d) — deeper cuts need later tech" % [
				sectors[sector_id].name, floor_value])
	sectors[sector_id].emissions = target
	sector_changed.emit(sector_id)


func sector_floor(sector_id: String) -> int:
	return int(era_for_year(year).min_sector_emissions.get(sector_id, 0))


func add_sector_income(sector_id: String, amount: int) -> void:
	sectors[sector_id].income = maxi(0, sectors[sector_id].income + amount)
	sector_changed.emit(sector_id)


func add_income_bonus(amount: int) -> void:
	income_bonus += amount
	resources_changed.emit()


func add_temp(amount: float) -> void:
	temp += amount
	temperature_changed.emit(temp)


func set_phase(p: int) -> void:
	phase = p
	phase_changed.emit(p)


func log_event(text: String) -> void:
	log_line.emit(text)


func snapshot() -> void:
	var sector_states := {}
	for id in sectors:
		sector_states[id] = {"emissions": sectors[id].emissions, "income": sectors[id].income}
	history.append({
		"turn": turn, "year": year, "temp": temp,
		"gross": gross_emissions(), "net": net_emissions(),
		"money": money, "support": support, "absorption": absorption,
		"sectors": sector_states,
	})


func end_run(won: bool, cause: String) -> void:
	if ended:
		return
	ended = true
	set_phase(Phase.ENDED)
	result = {
		"won": won, "cause": cause, "year": year, "turn": turn,
		"temp": temp, "seed": run_seed,
		"timeline": history.duplicate(true),
		"combos": discovered_combos.duplicate(),
		"cards": owned_cards.duplicate(),
	}
	run_ended.emit(result)
