extends Node
## Autoload "Meta": rogue-lite meta-progression that persists across runs.
## Knowledge Points + unlocked Knowledge nodes, meta-lesson cards earned by
## specific defeats, the codex of discovered real-world solutions, and the
## selected city archetype. Saved to user://.
## Spec: docs/Phase_0/04 (meta section), docs/Phase_4/05 (KP award).

const SAVE_PATH := "user://knowledge_save.json"

var kp_total: int = 0
var unlocked: Array = []          # Array[String] of knowledge node ids
var unlocked_cards: Array = []    # Array[String] of meta-lesson card ids (e.g. SOC4)
var codex_seen: Array = []        # Array[String] of card ids played at least once
var selected_archetype: String = ""  # "" = never chosen (first-boot picker)
var last_seed: int = 0
var tutorial_done: bool = false   # completed OR dismissed; never auto-reshow


func _ready() -> void:
	load_state()


func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		kp_total = int(parsed.get("kp_total", 0))
		unlocked = parsed.get("unlocked", [])
		unlocked_cards = parsed.get("unlocked_cards", [])
		codex_seen = parsed.get("codex_seen", [])
		selected_archetype = String(parsed.get("selected_archetype", ""))
		last_seed = int(parsed.get("last_seed", 0))
		tutorial_done = bool(parsed.get("tutorial_done", false))


func save_state() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not save meta state to %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify({
		"kp_total": kp_total,
		"unlocked": unlocked,
		"unlocked_cards": unlocked_cards,
		"codex_seen": codex_seen,
		"selected_archetype": selected_archetype,
		"last_seed": last_seed,
		"tutorial_done": tutorial_done,
	}))


func award_kp(amount: int) -> void:
	kp_total += amount
	save_state()


func is_unlocked(node_id: String) -> bool:
	return unlocked.has(node_id)


func can_unlock(node: Dictionary) -> bool:
	return not is_unlocked(String(node["id"])) and kp_total >= int(node["kp_cost"])


func unlock(node: Dictionary) -> bool:
	if not can_unlock(node):
		return false
	kp_total -= int(node["kp_cost"])
	unlocked.append(String(node["id"]))
	save_state()
	return true


## First play of a card unlocks its codex entry (the real-world solution).
## Returns true when this play was the discovery.
func mark_codex_seen(card_id: String) -> bool:
	if codex_seen.has(card_id):
		return false
	codex_seen.append(card_id)
	save_state()
	return true


## Defeat lessons: scan the catalog for cards whose meta_unlock matches this
## outcome and grant the new ones. Returns the freshly unlocked card ids.
func record_run_outcome(outcome: StringName, catalog: Catalog) -> Array[String]:
	var fresh: Array[String] = []
	for card in catalog.cards:
		var meta: Dictionary = card.get("meta_unlock", {})
		if meta.is_empty():
			continue
		var id := String(card["id"])
		if String(meta.get("on", "")) == String(outcome) and not unlocked_cards.has(id):
			unlocked_cards.append(id)
			fresh.append(id)
	if not fresh.is_empty():
		save_state()
	return fresh


## Archetype availability: unlocked unless it names a knowledge-node gate the
## player has not bought yet.
func is_archetype_unlocked(arch: Dictionary) -> bool:
	if not arch.has("unlock"):
		return true
	return is_unlocked(String((arch["unlock"] as Dictionary).get("knowledge", "")))
