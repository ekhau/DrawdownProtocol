class_name CrisisDeck
extends RefCounted
## The 13-card deck (10 crises + 3 windfalls): shuffled draw, reshuffle when
## empty, band scaling on crisis costs. Windfalls ignore band scaling (spec §3).

var state: RunState
var deck: Array = []              # crisis ids remaining
var current: Dictionary = {}      # {crisis, responses} — responses pre-scaled
var pending := false


func _init(run_state: RunState) -> void:
	state = run_state
	_reshuffle()


func draw() -> Dictionary:
	if deck.is_empty():
		_reshuffle()
	var crisis: Dictionary = state.catalog.crises_by_id[deck.pop_back()]
	var band: Dictionary = state.band()
	var bump := int(band.cost_bump) if crisis.kind == "crisis" else 0
	var responses := []
	for r in crisis.responses:
		responses.append({
			"name": r.name,
			"archetype": r.archetype,
			"effects": Effects.scaled(r.effects, bump),
		})
	current = {"crisis": crisis, "responses": responses, "band": band.id}
	pending = true
	var kind_label: String = "Windfall" if crisis.kind == "windfall" else "Crisis (band %s)" % band.id
	state.log_event("%s: %s" % [kind_label, crisis.name])
	return current


func choose(index: int) -> bool:
	if not pending or index < 0 or index >= current.responses.size():
		return false
	var response: Dictionary = current.responses[index]
	pending = false
	Effects.apply(response.effects, "%s — %s" % [current.crisis.name, response.name], state)
	current = {}
	return true


func _reshuffle() -> void:
	deck.clear()
	for crisis in state.catalog.crises:
		deck.append(crisis.id)
	for i in range(deck.size() - 1, 0, -1):
		var j := state.rng.randi_range(0, i)
		var tmp = deck[i]
		deck[i] = deck[j]
		deck[j] = tmp
