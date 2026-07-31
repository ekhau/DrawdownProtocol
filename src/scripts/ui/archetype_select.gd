class_name ArchetypeSelect
extends PanelContainer
## Starting-city picker (the run's "character select"). Shown on first boot
## and reachable from the end screen; the choice persists in Meta and applies
## to every new timeline. Locked archetypes state their Knowledge gate -
## unlocking happens in the Knowledge tree, never here.

signal chosen(archetype_id: StringName)

var _rows: VBoxContainer
var _catalog: Catalog


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1a1e18", 0.97)
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = Color("5fb3b3")
	style.content_margin_left = 30.0
	style.content_margin_right = 30.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	add_theme_stylebox_override("panel", style)
	anchor_left = 0.26
	anchor_right = 0.74
	anchor_top = 0.16
	anchor_bottom = 0.84
	visible = false

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	var title := Label.new()
	title.text = "CHOOSE YOUR CITY  -  every start forces a different road"
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("cfe8b8"))
	vbox.add_child(title)
	var note := Label.new()
	note.text = "The choice applies to this and future timelines (change it from any run-end screen)."
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color("9aa694"))
	vbox.add_child(note)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
	_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_rows)


func open(catalog: Catalog) -> void:
	_catalog = catalog
	_rebuild()
	visible = true


func _rebuild() -> void:
	for child in _rows.get_children():
		child.queue_free()
	for arch: Dictionary in _catalog.archetypes:
		var id := StringName(String(arch["id"]))
		var unlocked: bool = Meta.is_archetype_unlocked(arch)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_rows.add_child(row)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(170, 0)
		btn.focus_mode = Control.FOCUS_NONE
		if unlocked:
			btn.text = "Lead %s" % String(arch["name"])
			if String(arch["id"]) == Meta.selected_archetype:
				btn.text += " (current)"
			btn.pressed.connect(func() -> void: chosen.emit(id))
		else:
			var node_id := String((arch.get("unlock", {}) as Dictionary).get("knowledge", ""))
			var node: Dictionary = _catalog.knowledge_by_id.get(node_id, {})
			btn.text = "LOCKED - %s (%s KP)" % [String(node.get("name", node_id)),
				str(node.get("kp_cost", "?"))]
			btn.disabled = true
			btn.tooltip_text = "Unlock in the Knowledge tree (H)"
		row.add_child(btn)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var name_label := Label.new()
		name_label.text = "%s - \"%s\"" % [String(arch["name"]), String(arch.get("tagline", ""))]
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color",
			Color("f2f7e8") if unlocked else Color("6e746a"))
		text.add_child(name_label)
		var hint := Label.new()
		hint.text = "%s\n%s" % [String(arch.get("strategy_hint", "")), _stat_line(arch)]
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", Color("9aa694"))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(hint)


func _stat_line(arch: Dictionary) -> String:
	var parts: PackedStringArray = []
	var mm := float(arch.get("money_mult", 1.0))
	if not is_equal_approx(mm, 1.0):
		parts.append("money x%.1f" % mm)
	var im := float(arch.get("income_mult", 1.0))
	if not is_equal_approx(im, 1.0):
		parts.append("income x%.2f" % im)
	var ib := float(arch.get("influence_bonus", 0))
	if ib != 0.0:
		parts.append("influence %+d" % int(ib))
	var smult: Dictionary = arch.get("sector_mult", {})
	for key in ["ind", "tra", "agr"]:
		var v := float(smult.get(key, 1.0))
		if not is_equal_approx(v, 1.0):
			parts.append("%s emissions x%.1f" % [key, v])
	if int(arch.get("start_allies", 0)) > 0:
		parts.append("starts with %d ally" % int(arch["start_allies"]))
	var weights: Dictionary = arch.get("market_weights", {})
	if not weights.is_empty():
		var tags: PackedStringArray = []
		for key in weights:
			tags.append(String(key))
		parts.append("market leans: " + ", ".join(tags))
	return " | ".join(parts)
