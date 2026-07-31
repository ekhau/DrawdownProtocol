class_name Effects
extends RefCounted
## The effect resolver — the ONLY code allowed to mutate RunState.
## Applying here guarantees every change emits its signal and writes a log line,
## so the turn-log clarity rule holds by construction.
## Atom vocabulary (see catalog.gd): money, support, absorption,
## sector_emissions, sector_income, income_per_turn, gross_this_turn.

const PERM_TYPES := ["sector_emissions", "sector_income", "income_per_turn", "absorption"]


static func apply(atoms: Array, source: String, state: RunState) -> void:
	for atom in atoms:
		match atom.type:
			"money":
				state.add_money(int(atom.amount))
			"support":
				state.add_support(int(atom.amount))
			"absorption":
				state.add_absorption(int(atom.amount))
			"sector_emissions":
				state.add_sector_emissions(atom.sector, int(atom.amount))
			"sector_income":
				state.add_sector_income(atom.sector, int(atom.amount))
			"income_per_turn":
				state.add_income_bonus(int(atom.amount))
			"gross_this_turn":
				state.gross_this_turn_delta += int(atom.amount)
				state.resources_changed.emit()
			_:
				push_error("Effects.apply: unknown atom type '%s' from '%s'" % [atom.type, source])
	state.log_event("%s: %s" % [source, describe(atoms, state.catalog)])


## Deep-copies crisis-response atoms with band scaling applied: the bump makes
## money/support COSTS (negative amounts) worse. Gains and permanent effects
## never scale (spec §3). Windfalls skip this entirely (crisis_deck.gd).
static func scaled(atoms: Array, cost_bump: int) -> Array:
	var out := []
	for atom in atoms:
		var copy: Dictionary = atom.duplicate(true)
		if copy.type in ["money", "support"] and int(copy.amount) < 0:
			copy.amount = int(copy.amount) - cost_bump
		out.append(copy)
	return out


static func describe(atoms: Array, catalog: Catalog) -> String:
	var parts: PackedStringArray = []
	for atom in atoms:
		var n := int(atom.amount)
		var signed := ("+%d" % n) if n > 0 else str(n)
		var perm := " (perm)" if atom.type in PERM_TYPES else ""
		match atom.type:
			"money":
				parts.append("%s$" % signed)
			"support":
				parts.append("%s support" % signed)
			"absorption":
				parts.append("Absorption %s%s" % [signed, perm])
			"sector_emissions":
				parts.append("%s emissions %s%s" % [_sector_name(atom.sector, catalog), signed, perm])
			"sector_income":
				parts.append("%s income %s$/turn" % [_sector_name(atom.sector, catalog), signed])
			"income_per_turn":
				parts.append("%s$/turn" % signed)
			"gross_this_turn":
				parts.append("this turn's gross emissions %s" % signed)
	return ", ".join(parts)


static func is_permanent(atoms: Array) -> bool:
	for atom in atoms:
		if atom.type in PERM_TYPES:
			return true
	return false


static func _sector_name(id: String, catalog: Catalog) -> String:
	for s in catalog.config.sectors:
		if s.id == id:
			return s.name
	return id
