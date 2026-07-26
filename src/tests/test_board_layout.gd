extends TestBase
## Board layout data invariants (data/board_layout_notes.md): 12 unique slot
## ids, every panel rect inside board_area, no overlap at the 1.06x envelope.


func test_layout_invariants() -> void:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/board_layout.json"))
	check(doc is Dictionary and doc.has("slots"), "board_layout.json parses")
	var slots: Array = doc["slots"]
	eq(slots.size(), 12, "12 slots")
	var area: Dictionary = doc["board_area"]
	var psize: Dictionary = doc["panel_size"]
	var pw := float(psize["w"])
	var ph := float(psize["h"])
	var ids := {}
	var rects: Array[Rect2] = []
	for slot: Dictionary in slots:
		var id := String(slot["region_id"])
		check(not ids.has(id), "slot id %s unique" % id)
		ids[id] = true
		var pos: Dictionary = slot["pos"]
		var rect := Rect2(float(pos["x"]) - pw / 2.0, float(pos["y"]) - ph / 2.0, pw, ph)
		var board := Rect2(float(area["x"]), float(area["y"]), float(area["w"]), float(area["h"]))
		check(board.encloses(rect), "panel %s inside board_area" % id)
		rects.append(rect)
	for i in range(12):
		check(ids.has("region_%02d" % i), "region_%02d present" % i)
	# No overlap at the 1.06x hover envelope.
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			var a := rects[i].grow_individual(pw * 0.03, ph * 0.03, pw * 0.03, ph * 0.03)
			check(not a.intersects(rects[j].grow_individual(pw * 0.03, ph * 0.03, pw * 0.03, ph * 0.03)),
				"panels %d and %d clear at 1.06x envelope" % [i, j])
