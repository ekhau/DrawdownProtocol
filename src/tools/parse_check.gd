extends SceneTree
## Loads every .gd file in the project so parse errors surface in CI:
##   godot --headless --path src --script res://tools/parse_check.gd

const ROOTS: Array[String] = ["res://scripts", "res://tools", "res://tests"]


func _initialize() -> void:
	var bad := 0
	var total := 0
	for root in ROOTS:
		for path in _walk(root):
			total += 1
			var script: GDScript = load(path)
			if script == null or not script.can_instantiate():
				# Tool/SceneTree scripts can't instantiate but still parse; check reload.
				if script == null or script.reload() != OK:
					print("PARSE FAIL: %s" % path)
					bad += 1
	print("parse_check: %d scripts, %d failures" % [total, bad])
	quit(1 if bad > 0 else 0)


func _walk(root: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var path := root.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				out.append_array(_walk(path))
		elif entry.ends_with(".gd"):
			out.append(path)
		entry = dir.get_next()
	dir.list_dir_end()
	return out
