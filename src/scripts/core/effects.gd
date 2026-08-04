class_name Effects
extends RefCounted
## The effect resolver — the ONLY code allowed to mutate RunState.
## Applying here guarantees every change emits its signal and writes a log line,
## so the turn-log clarity rule holds by construction.
## Atom vocabulary (see catalog.gd): money, popularity, absorption,
## sector_emissions, sector_income, income_per_turn, gross_this_turn,
## world_emissions.

const PERM_TYPES := ["sector_emissions", "sector_income", "income_per_turn", "absorption", "world_emissions"]


static func apply(atoms: Array, source: String, state: RunState) -> void:
	for atom in atoms:
		match atom.type:
			"money":
				state.add_money(int(atom.amount))
			"popularity":
				state.add_popularity(int(atom.amount))
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
			"world_emissions":
				state.add_world_emissions(int(atom.amount))
			_:
				push_error("Effects.apply: unknown atom type '%s' from '%s'" % [atom.type, source])
	state.log_event("%s: %s" % [source, describe(atoms, state.catalog)])


## Deep-copies crisis-response atoms with band scaling applied: the bumps make
## money/popularity COSTS (negative amounts) worse — each resource has its own
## bump because they live on different scales (money in M$, popularity in %).
## Gains and permanent effects never scale (spec §3). Windfalls skip this
## entirely (crisis_deck.gd).
static func scaled(atoms: Array, money_bump: int, popularity_bump: int) -> Array:
	var out := []
	for atom in atoms:
		var copy: Dictionary = atom.duplicate(true)
		if int(copy.amount) < 0:
			if copy.type == "money":
				copy.amount = int(copy.amount) - money_bump
			elif copy.type == "popularity":
				copy.amount = int(copy.amount) - popularity_bump
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
				parts.append("%sM$" % signed)
			"popularity":
				parts.append("%s%% popularity" % signed)
			"absorption":
				parts.append("Absorption %s%s" % [signed, perm])
			"sector_emissions":
				parts.append("%s emissions %s%s" % [_sector_name(atom.sector, catalog), signed, perm])
			"sector_income":
				parts.append("%s income %sM$/turn" % [_sector_name(atom.sector, catalog), signed])
			"income_per_turn":
				parts.append("%sM$/turn" % signed)
			"gross_this_turn":
				parts.append("this turn's gross emissions %s" % signed)
			"world_emissions":
				parts.append("planetary emissions %s%s" % [signed, perm])
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
