class_name WorldEnums
## Shared enums for the world model (docs/Phase_3/01_World_Model_And_Tile_Schema.md).

enum AllyState { NEUTRAL, ALLY, PLAYER_HOME }

const SECTOR_ORDER: Array[StringName] = [&"ind", &"tra", &"agr"]

const SECTOR_NAMES := {
	&"ind": "Industry",
	&"tra": "Transport",
	&"agr": "Agro-economy",
}
