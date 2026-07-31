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
	if not offer.has(card_id):
		return false
	var card: Dictionary = state.catalog.cards_by_id[card_id]
	return state.money >= int(card.cost_money) and state.support > int(card.cost_support)


func buy(card_id: String) -> bool:
	if not can_buy(card_id):
		return false
	var card: Dictionary = state.catalog.cards_by_id[card_id]
	var cost_atoms := []
	if int(card.cost_money) > 0:
		cost_atoms.append({"type": "money", "amount": -int(card.cost_money)})
	if int(card.cost_support) > 0:
		cost_atoms.append({"type": "support", "amount": -int(card.cost_support)})
	if not cost_atoms.is_empty():
		Effects.apply(cost_atoms, "Bought %s" % card.name, state)
	Effects.apply(card.effects, card.name, state)
	state.owned_cards.append(card_id)
	# Refill only the emptied slot — buying must not reroll the rest of the offer.
	offer.erase(card_id)
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
