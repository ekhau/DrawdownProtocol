extends Node
## Autoload "Meta": rogue-lite meta-progression that persists across runs.
## Knowledge Points + unlocked Knowledge nodes, saved to user://.
## Spec: docs/Phase_0/04 (meta section), docs/Phase_4/05 (KP award).

const SAVE_PATH := "user://knowledge_save.json"

var kp_total: int = 0
var unlocked: Array = []  # Array[String] of knowledge node ids
var last_seed: int = 0


func _ready() -> void:
	load_state()


func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		kp_total = int(parsed.get("kp_total", 0))
		unlocked = parsed.get("unlocked", [])
		last_seed = int(parsed.get("last_seed", 0))


func save_state() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not save meta state to %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify({
		"kp_total": kp_total,
		"unlocked": unlocked,
		"last_seed": last_seed,
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
