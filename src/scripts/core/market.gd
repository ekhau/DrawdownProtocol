class_name Market
extends RefCounted
## Card market: pool shuffle, deal N face-up, reroll, buy without replacement.
## Era gating lives here: only cards with available_from <= current year are dealt.
## Unbought cards cycle back into the pool; bought cards leave it for the run.

var state: RunState
var pool: Array = []        # card ids not owned, shuffled at run start
var offer: Array = []       # card ids currently face-up (up to market_size)
var rerolled_this_turn := false


func _init(run_state: RunState) -> void:
	state = run_state
	for card in state.catalog.cards:
		pool.append(card.id)
	_shuffle(pool)
	refresh()


func refresh() -> void:
	# Return the current offer to the pool, then deal fresh from unlocked cards.
	for id in offer:
		pool.append(id)
	offer.clear()
	_shuffle(pool)
	_fill()


func _fill() -> void:
	# Top up empty offer slots from the pool without touching face-up cards.
	var size := int(state.catalog.config.market_size)
	var i := 0
	while offer.size() < size and i < pool.size():
		var card: Dictionary = state.catalog.cards_by_id[pool[i]]
		if int(card.available_from) <= state.year:
			offer.append(pool[i])
			pool.remove_at(i)
		else:
			i += 1
	# Every offer mutation ends here — the one signal the market UI repaints from.
	state.market_changed.emit()


func can_reroll() -> bool:
	return not rerolled_this_turn and state.money >= int(state.catalog.config.reroll_cost)


func reroll() -> bool:
	if not can_reroll():
		return false
	rerolled_this_turn = true
	Effects.apply([{"type": "money", "amount": -int(state.catalog.config.reroll_cost)}], "Market reroll", state)
	refresh()
	return true


func can_buy(card_id: String) -> bool:
	return offer.has(card_id) and blockers(card_id).is_empty()


## Read-only, for the UI: why this card can't be bought right now. Empty = buyable.
## Popularity has two rules: `requires_popularity` is a gate (checked, never
## spent), and spending is strict — a purchase may never drop popularity into
## the collapse zone. Only crises can bring a government down; for risk cards
## that extends to the failure outcome (`risk_floor`), which doubles as a soft
## popularity gate on gambles.
func blockers(card_id: String) -> Dictionary:
	var card: Dictionary = state.catalog.cards_by_id[card_id]
	var out := {}
	if state.money < int(card.cost_money):
		out.money = int(card.cost_money) - state.money
	var gate := int(card.get("requires_popularity", 0))
	if gate > 0 and state.popularity < gate:
		out.popularity_gate = gate
	var cost := int(card.cost_popularity)
	if cost > 0:
		if state.popularity < cost:
			out.popularity = cost - state.popularity
		elif state.popularity - cost < int(state.catalog.config.popularity_collapse):
			out.popularity_floor = true
	if card.has("risk"):
		var fail_pop := 0
		for atom in card.risk.on_fail:
			if atom.type == "popularity" and int(atom.amount) < 0:
				fail_pop += int(atom.amount)
		if state.popularity - cost + fail_pop < int(state.catalog.config.popularity_collapse):
			out.risk_floor = true
	return out


## Success chance for a risk card: popularity + the card's offset + campaign
## boosts, clamped to [0, cap]. Money improves the odds but never buys certainty.
func success_chance(card_id: String, boosts: int = 0) -> int:
	var risk: Dictionary = state.catalog.cards_by_id[card_id].risk
	var n := clampi(boosts, 0, int(risk.boost_max))
	return clampi(state.popularity + int(risk.offset) + n * int(risk.boost_amount), 0, int(risk.cap))


func buy(card_id: String, boosts: int = 0) -> bool:
	if not can_buy(card_id):
		return false
	var card: Dictionary = state.catalog.cards_by_id[card_id]
	var money_cost := int(card.cost_money)
	if card.has("risk"):
		boosts = clampi(boosts, 0, int(card.risk.boost_max))
		money_cost += boosts * int(card.risk.boost_cost)
		if state.money < money_cost:
			return false
	# Leave the offer BEFORE costs land: applying costs emits resources_changed,
	# and any repaint that fires mid-buy must already see the card gone.
	offer.erase(card_id)
	var cost_atoms := []
	if money_cost > 0:
		cost_atoms.append({"type": "money", "amount": -money_cost})
	if int(card.cost_popularity) > 0:
		cost_atoms.append({"type": "popularity", "amount": -int(card.cost_popularity)})
	if not cost_atoms.is_empty():
		var verb := "Attempted" if card.has("risk") else "Bought"
		Effects.apply(cost_atoms, "%s %s" % [verb, card.name], state)
	if card.has("risk"):
		# One attempt per run: the card is consumed win or lose, money is spent,
		# and the roll is logged — dice must be as traceable as everything else.
		var chance := success_chance(card_id, boosts)
		var roll := state.rng.randi_range(1, 100)
		var success := roll <= chance
		state.log_event("%s: rolled %d vs %d%% — the reform %s" % [
			card.name, roll, chance, "passes" if success else "fails"])
		if success:
			Effects.apply(card.effects, card.name, state)
			state.owned_cards.append(card_id)
		else:
			Effects.apply(card.risk.on_fail, "%s — backlash" % card.name, state)
		state.risk_resolved.emit(card_id, success)
	else:
		Effects.apply(card.effects, card.name, state)
		state.owned_cards.append(card_id)
	# Refill only the emptied slot — buying must not reroll the rest of the offer.
	_fill()
	return true


func on_turn_start() -> void:
	rerolled_this_turn = false


func _shuffle(arr: Array) -> void:
	# Fisher-Yates with the run's seeded RNG — deterministic per seed.
	for i in range(arr.size() - 1, 0, -1):
		var j := state.rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
