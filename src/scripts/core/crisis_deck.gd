class_name CrisisDeck
extends RefCounted
## Two shuffled pools: the normal deck (crises + windfalls) and the social deck
## (strikes, riots, no-confidence — `social: true` in crises.json), drawn
## instead while popularity sits below the social threshold. Reshuffle when
## empty, band scaling on crisis costs. Windfalls ignore band scaling (spec §3).

var state: RunState
var deck: Array = []              # normal crisis ids remaining
var social_deck: Array = []       # social crisis ids remaining
var current: Dictionary = {}      # {crisis, responses} — responses pre-scaled
var pending := false


func _init(run_state: RunState) -> void:
	state = run_state
	_reshuffle(deck, false)


func draw() -> Dictionary:
	# Below the social threshold the streets take over: the year's crisis comes
	# from the social pool (replacing, never adding to, the normal draw) until
	# the player wins the public back.
	var social_mode: bool = state.popularity < int(state.catalog.config.social_crisis_threshold)
	var pool := social_deck if social_mode else deck
	if pool.is_empty():
		_reshuffle(pool, social_mode)
	var crisis: Dictionary = state.catalog.crises_by_id[pool.pop_back()]
	var band: Dictionary = state.band()
	var is_crisis: bool = crisis.kind == "crisis"
	var responses := []
	for r in crisis.responses:
		responses.append({
			"name": r.name,
			"archetype": r.archetype,
			"effects": Effects.scaled(r.effects,
				int(band.cost_bump_money) if is_crisis else 0,
				int(band.cost_bump_popularity) if is_crisis else 0),
		})
	current = {"crisis": crisis, "responses": responses, "band": band.id}
	pending = true
	var kind_label: String
	if crisis.get("social", false):
		kind_label = "Social crisis (band %s)" % band.id
	elif is_crisis:
		kind_label = "Crisis (band %s)" % band.id
	else:
		kind_label = "Windfall"
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


func _reshuffle(pool: Array, social: bool) -> void:
	pool.clear()
	for crisis in state.catalog.crises:
		if bool(crisis.get("social", false)) == social:
			pool.append(crisis.id)
	for i in range(pool.size() - 1, 0, -1):
		var j := state.rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
