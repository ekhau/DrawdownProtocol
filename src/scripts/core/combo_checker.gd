class_name ComboChecker
extends RefCounted
## Set detection: after every purchase, check undiscovered combos; when one
## completes, apply its bonus (through Effects, like everything) and announce it.

var state: RunState


func _init(run_state: RunState) -> void:
	state = run_state


func check() -> void:
	for combo in state.catalog.combos:
		if state.discovered_combos.has(combo.id):
			continue
		var complete := true
		for card_id in combo.cards:
			if not state.owned_cards.has(card_id):
				complete = false
				break
		if complete:
			state.discovered_combos.append(combo.id)
			Effects.apply(combo.effects, "COMBO — %s" % combo.name, state)
			state.combo_discovered.emit(combo.id)
