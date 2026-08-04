extends Node
## Autoload "Game" — the thin façade between the pure sim and the scene tree.
## Owns the Catalog and the current TurnManager, re-emits the sim's signals for
## the UI, and forwards the five verbs. NO game logic lives here or below in UI.

signal resources_changed
signal sector_changed(sector_id: String)
signal temperature_changed(temp: float)
signal phase_changed(phase: int)
signal market_changed
signal combo_discovered(combo_id: String)
signal risk_resolved(card_id: String, success: bool)
signal tipping_point_crossed(tipping_id: String)
signal era_started(era_id: String)
signal log_line(text: String)
signal run_ended(result: Dictionary)
signal run_started

var catalog: Catalog
var sim: TurnManager


func _ready() -> void:
	catalog = Catalog.load_all()
	if catalog == null:
		push_error("Catalog failed to load — see errors above. Quitting.")
		get_tree().quit(1)


# --- the five verbs -----------------------------------------------------------

func new_run(seed_value: int = -1) -> void:
	if seed_value < 0:
		seed_value = randi()
	sim = TurnManager.new(catalog, seed_value)
	var s := sim.state
	s.resources_changed.connect(func(): resources_changed.emit())
	s.sector_changed.connect(func(id): sector_changed.emit(id))
	s.temperature_changed.connect(func(t): temperature_changed.emit(t))
	s.phase_changed.connect(func(p): phase_changed.emit(p))
	s.market_changed.connect(func(): market_changed.emit())
	s.combo_discovered.connect(func(id): combo_discovered.emit(id))
	s.risk_resolved.connect(func(id, ok): risk_resolved.emit(id, ok))
	s.tipping_point_crossed.connect(func(id): tipping_point_crossed.emit(id))
	s.era_started.connect(func(id): era_started.emit(id))
	s.log_line.connect(func(t): log_line.emit(t))
	s.run_ended.connect(func(r): run_ended.emit(r))
	run_started.emit()


func choose_response(index: int) -> void:
	sim.choose_response(index)


func buy_card(card_id: String, boosts: int = 0) -> void:
	sim.buy_card(card_id, boosts)


func reroll() -> void:
	sim.reroll()


func end_turn() -> void:
	sim.end_turn()


# --- read-only helpers for UI -------------------------------------------------

func state() -> RunState:
	return sim.state if sim else null


func neutrality_projection() -> Dictionary:
	return ClimateCalc.neutrality_projection(sim.state)


## Read-only, for the climate bar's tipping-point markers and tooltips:
## the catalog's list (ascending temp) with each point's crossed status.
func tipping_points() -> Array:
	var crossed: Array = sim.state.crossed_tipping_points if sim != null else []
	var out := []
	for tp in catalog.config.tipping_points:
		out.append({"id": tp.id, "name": tp.name, "temp": float(tp.temp),
			"flavor": tp.flavor, "effects": tp.effects, "crossed": crossed.has(tp.id)})
	return out


func era_palette() -> Gradient:
	var era := sim.state.era_for_year(sim.state.year)
	return palette_gradient(era.palette)


func palette_gradient(palette_id: String) -> Gradient:
	var stops: Array = catalog.config.palettes[palette_id]
	var gradient := Gradient.new()
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for stop in stops:
		offsets.append(float(stop.t))
		colors.append(Color(stop.color))
	gradient.offsets = offsets
	gradient.colors = colors
	return gradient
