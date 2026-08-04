class_name Bots
extends RefCounted
## Scripted players for headless tests and the balance harness.
## Buy policies: "none" (do nothing), "greedy" (buy everything affordable,
## temptations included), "clean" (combo cards first, never temptations).
## Crisis policies: "default" (pay with money when possible), or force an
## archetype: "pay" / "absorb" / "mortgage" / "invest".


static func play(catalog: Catalog, seed_value: int, buy_policy: String, crisis_policy: String) -> Dictionary:
	var sim := TurnManager.new(catalog, seed_value)
	var guard := 0
	while not sim.state.ended and guard < 200:
		guard += 1
		if sim.state.phase == RunState.Phase.CRISIS:
			sim.choose_response(pick_response(sim, crisis_policy))
		elif sim.state.phase == RunState.Phase.ACTION:
			act(sim, buy_policy)
			sim.end_turn()
	if not sim.state.ended:
		sim.state.end_run(false, "Stalemate — timeline abandoned after %d turns" % sim.state.turn)
	return sim.state.result


static func pick_response(sim: TurnManager, policy: String) -> int:
	var responses: Array = sim.crisis_deck.current.responses
	if sim.crisis_deck.current.crisis.kind == "windfall":
		return _best_popularity(responses)
	if policy != "default":
		for i in responses.size():
			if responses[i].archetype == policy:
				return i
	# Default: first money-only option we can afford, else least popularity loss.
	for i in responses.size():
		if _money_only(responses[i].effects) and _affordable(sim.state, responses[i].effects):
			return i
	return _best_popularity(responses)


static func act(sim: TurnManager, policy: String) -> void:
	if policy == "none":
		return
	var bought := true
	while bought and not sim.state.ended:
		bought = false
		for card_id in _wishlist(sim, policy):
			if sim.state.phase == RunState.Phase.ACTION and sim.market.can_buy(card_id):
				sim.buy_card(card_id)
				bought = true
				break


static func _wishlist(sim: TurnManager, policy: String) -> Array:
	var offer := sim.market.offer.duplicate()
	if policy == "greedy":
		return offer
	# "clean": combo cards first, then cheapest; temptations never; skip cards
	# whose cuts would be fully wasted on era floors (a human sees the floor flag).
	var combo_cards := []
	var rest := []
	for id in offer:
		var card: Dictionary = sim.state.catalog.cards_by_id[id]
		if card.sector == "temptation":
			continue
		if card.has("risk") and sim.market.success_chance(id) < 70:
			continue  # clean bot only gambles on good odds; greedy gambles on anything
		if _fully_wasted(sim.state, card):
			continue
		if card.has("combo"):
			combo_cards.append(id)
		else:
			rest.append(id)
	rest.sort_custom(func(a, b):
		return int(sim.state.catalog.cards_by_id[a].cost_money) < int(sim.state.catalog.cards_by_id[b].cost_money))
	return combo_cards + rest


static func _fully_wasted(state: RunState, card: Dictionary) -> bool:
	var has_cut := false
	for atom in card.effects:
		match atom.type:
			"sector_emissions":
				if int(atom.amount) < 0:
					has_cut = true
					if state.sectors[atom.sector].emissions > state.sector_floor(atom.sector):
						return false
			"absorption", "income_per_turn", "popularity", "money":
				if int(atom.amount) > 0:
					return false
	return has_cut


static func _money_only(effects: Array) -> bool:
	for atom in effects:
		if atom.type != "money":
			return false
	return true


static func _affordable(state: RunState, effects: Array) -> bool:
	var delta := 0
	for atom in effects:
		if atom.type == "money":
			delta += int(atom.amount)
	return state.money + delta >= 0


static func _best_popularity(responses: Array) -> int:
	var best := 0
	var best_delta := -999
	for i in responses.size():
		var delta := 0
		for atom in responses[i].effects:
			if atom.type == "popularity":
				delta += int(atom.amount)
		if delta > best_delta:
			best_delta = delta
			best = i
	return best
