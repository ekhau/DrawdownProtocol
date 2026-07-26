class_name Sim
extends Node
## Scene-facing owner of the headless simulation (docs/Phase_3/03 architecture:
## "sim renders nothing, views own nothing"). Instantiated by Main; the same
## class is used headless by tools and tests via RunState directly.

signal run_started(rs: RunState)

var base_catalog: Catalog
var run_state: RunState
var current_seed: int = 0
var canonical: bool = false


func _ready() -> void:
	base_catalog = Catalog.load_default()


func start_run(seed_value: int, unlocked_knowledge: Array = [], canonical_start: bool = false) -> void:
	current_seed = seed_value
	canonical = canonical_start
	var gen := WorldGen.generate(seed_value, canonical_start)
	run_state = RunState.new_run(gen, base_catalog, unlocked_knowledge)
	run_started.emit(run_state)


## Debug autoplay: run a scripted strategy to run end at max speed.
func autoplay_to_end(strategy: StringName) -> void:
	if run_state == null or run_state.phase == RunState.Phase.ENDED:
		return
	var guard := 200
	while run_state.phase != RunState.Phase.ENDED and guard > 0:
		guard -= 1
		var choice := Strategies.decide(strategy, run_state)
		if choice["card"] != &"pass":
			run_state.play_card(choice["card"], choice["target"])
		run_state.resolve_year()


## Debug: advance N years passing (no cards).
func advance_years_passing(n: int) -> void:
	if run_state == null:
		return
	for i in n:
		if run_state.phase == RunState.Phase.ENDED:
			return
		run_state.resolve_year()
