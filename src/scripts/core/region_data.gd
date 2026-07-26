class_name RegionData
extends Resource
## One region (country) of the Tier A world model.
## Spec: docs/Phase_3/01_World_Model_And_Tile_Schema.md.
## Regions DECOMPOSE global simulation values for display and event flavor;
## they never own simulation state.

@export var id: StringName
@export var display_name: String
@export var archetype: StringName
# --- decomposition of global simulation values (fractions, generated once) ---
@export var ind_share: float = 0.0
@export var tra_share: float = 0.0
@export var agr_share: float = 0.0
@export var sink_share: float = 0.0
# --- vulnerability tags (event targeting weights, flavor only) ---
@export var coastal: bool = false
@export var arid: bool = false
@export var forested: bool = false
# --- diplomacy ---
@export var is_player_home: bool = false
@export var alliance_affinity: float = 1.0  # 0.8-1.2; MVP: flavor only, no cost effect
# --- runtime (owned by RunState, mirrored here for the view) ---
var ally_state: WorldEnums.AllyState = WorldEnums.AllyState.NEUTRAL
var scars: Array[StringName] = []


func has_tag(tag: StringName) -> bool:
	match tag:
		&"coastal": return coastal
		&"arid": return arid
		&"forested": return forested
	return false


func share_for(sector: StringName) -> float:
	match sector:
		&"ind": return ind_share
		&"tra": return tra_share
		&"agr": return agr_share
	return 0.0


## Deep serialization for determinism tests (deep-equal comparison).
func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"display_name": display_name,
		"archetype": String(archetype),
		"ind_share": ind_share,
		"tra_share": tra_share,
		"agr_share": agr_share,
		"sink_share": sink_share,
		"coastal": coastal,
		"arid": arid,
		"forested": forested,
		"is_player_home": is_player_home,
		"alliance_affinity": alliance_affinity,
	}
