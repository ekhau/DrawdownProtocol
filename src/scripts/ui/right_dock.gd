class_name RightDock
extends PanelContainer
## Right dock: the year's three crises (top), Region Inspector (middle) and
## turn log (bottom). Reserved space so selection never occludes the board
## (data/board_layout_notes.md).

const CRISIS_OPEN := Color("e0a080")
const CRISIS_ANSWERED := Color("a0d890")
const OPPORTUNITY_OPEN := Color("e8d48a")

var crisis_box: VBoxContainer
var _crisis_header: Label
var _inspector: RichTextLabel
var _log: RichTextLabel


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20241e")
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", style)
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = -400
	offset_top = 96
	offset_bottom = -216

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	_crisis_header = Label.new()
	_crisis_header.text = "CRISES THIS YEAR"
	_crisis_header.add_theme_font_size_override("font_size", 11)
	_crisis_header.add_theme_color_override("font_color", Color("9aa694"))
	vbox.add_child(_crisis_header)
	crisis_box = VBoxContainer.new()
	crisis_box.add_theme_constant_override("separation", 4)
	vbox.add_child(crisis_box)

	var insp_header := Label.new()
	insp_header.text = "REGION INSPECTOR"
	insp_header.add_theme_font_size_override("font_size", 11)
	insp_header.add_theme_color_override("font_color", Color("9aa694"))
	vbox.add_child(insp_header)
	_inspector = RichTextLabel.new()
	_inspector.bbcode_enabled = true
	_inspector.fit_content = false
	_inspector.custom_minimum_size = Vector2(0, 140)
	_inspector.add_theme_font_size_override("normal_font_size", 12)
	_inspector.text = "Select a region on the board."
	vbox.add_child(_inspector)

	var log_header := Label.new()
	log_header.text = "TURN LOG"
	log_header.add_theme_font_size_override("font_size", 11)
	log_header.add_theme_color_override("font_color", Color("9aa694"))
	vbox.add_child(log_header)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 12)
	vbox.add_child(_log)


## Tutorial spotlight anchor for the crisis section.
func crisis_rect() -> Rect2:
	var top := _crisis_header.get_global_rect()
	var bottom := crisis_box.get_global_rect()
	return top.merge(bottom)


## One panel per pending crisis: threat, answer tags, live answered state.
func show_crises(rs: RunState) -> void:
	for child in crisis_box.get_children():
		child.queue_free()
	for crisis in rs.pending_crises:
		var ev := rs.crisis_def(crisis["id"])
		var is_opp: bool = crisis["kind"] == "opportunity"
		var answered: bool = crisis["answered"]
		var region := rs.region_by_id(crisis["region_id"])
		var color := CRISIS_ANSWERED if answered else (OPPORTUNITY_OPEN if is_opp else CRISIS_OPEN)

		var chip := PanelContainer.new()
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color("262b24")
		cs.set_border_width_all(1)
		cs.border_color = color
		cs.set_corner_radius_all(4)
		cs.content_margin_left = 8.0
		cs.content_margin_right = 8.0
		cs.content_margin_top = 4.0
		cs.content_margin_bottom = 4.0
		chip.add_theme_stylebox_override("panel", cs)
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		crisis_box.add_child(chip)
		var text := RichTextLabel.new()
		text.bbcode_enabled = true
		text.fit_content = true
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.add_theme_font_size_override("normal_font_size", 11)
		chip.add_child(text)

		var title := String(ev.get("name", crisis["id"]))
		if region != null:
			title += " - " + region.display_name
		var state_note := ""
		var detail := ""
		if answered:
			state_note = "SEIZED" if is_opp else "ANSWERED"
			var card := rs.catalog.card(crisis["answered_by"])
			detail = "by %s" % card.get("name", String(crisis["answered_by"]))
		else:
			state_note = "OPEN"
			detail = _threat_line(ev, is_opp)
		var tags: Array = ev.get("response", {}).get("tags_any", [])
		var tag_note := "/".join(PackedStringArray(tags))
		text.text = "[color=#%s][b]%s[/b]  %s[/color]\n%s  [color=#9aa694]answers: %s[/color]" % [
			color.to_html(false), title, state_note, detail, tag_note]
		chip.tooltip_text = _crisis_tooltip(ev, is_opp, tags)


func _threat_line(ev: Dictionary, is_opp: bool) -> String:
	if is_opp:
		return "if seized: " + _rewards_note(ev.get("response", {}).get("rewards", {}))
	var damages: Dictionary = ev.get("damages", {})
	var parts: PackedStringArray = []
	if damages.has("money"):
		parts.append("-%s funds" % LogFormatter.fmt(damages["money"]))
	if damages.has("happiness"):
		parts.append("-%s happiness" % LogFormatter.fmt(damages["happiness"]))
	if damages.has("absorption"):
		parts.append("-%s absorption" % LogFormatter.fmt(damages["absorption"]))
	if damages.has("influence"):
		parts.append("-%s influence" % LogFormatter.fmt(damages["influence"]))
	if damages.has("ally_lost"):
		parts.append("ally at risk")
	return "if ignored: " + ", ".join(parts)


func _rewards_note(rewards: Dictionary) -> String:
	var parts: PackedStringArray = []
	for key in ["money", "influence", "happiness", "knowledge"]:
		if float(rewards.get(key, 0)) > 0:
			parts.append("+%s %s" % [LogFormatter.fmt(rewards[key]),
				"funds" if key == "money" else key])
	return ", ".join(parts)


func _crisis_tooltip(ev: Dictionary, is_opp: bool, tags: Array) -> String:
	var lines: PackedStringArray = []
	lines.append(String(ev.get("name", "?")))
	if is_opp:
		lines.append("Opportunity - costs nothing if missed.")
	else:
		lines.append(_threat_line(ev, false))
		if bool(ev.get("scaled_by_resilience", false)):
			lines.append("Damage scaled by resilience.")
	lines.append("Answer with any card tagged: " + ", ".join(PackedStringArray(tags)))
	var rewards: Dictionary = ev.get("response", {}).get("rewards", {})
	if not rewards.is_empty():
		lines.append("Answer reward: " + _rewards_note(rewards))
	return "\n".join(lines)


func show_region(rs: RunState, region_id: StringName) -> void:
	var r := rs.region_by_id(region_id)
	if r == null:
		_inspector.text = "Select a region on the board."
		return
	var lines: PackedStringArray = []
	lines.append("[b]%s[/b] - %s" % [r.display_name, String(r.archetype).capitalize()])
	var tags: PackedStringArray = []
	if r.coastal:
		tags.append("coastal")
	if r.arid:
		tags.append("arid")
	if r.forested:
		tags.append("forested")
	if tags.size() > 0:
		lines.append("Vulnerabilities: " + ", ".join(tags))
	lines.append("Emissions %.1f | Absorption %.1f Gt/yr" % [rs.region_emissions(r), rs.region_absorption(r)])
	lines.append("Shares: ind %d%% tra %d%% agr %d%% sink %d%%" % [
		roundi(r.ind_share * 100), roundi(r.tra_share * 100),
		roundi(r.agr_share * 100), roundi(r.sink_share * 100)])
	match r.ally_state:
		WorldEnums.AllyState.PLAYER_HOME:
			lines.append("[color=#5fb3b3]The coalition's home.[/color]")
		WorldEnums.AllyState.ALLY:
			lines.append("[color=#d9a441]Ally: +20 money, +1 influence yearly.[/color]")
		_:
			lines.append("Neutral - Form Alliance: 50 money + 25 influence")
	if r.scars.size() > 0:
		var scar_strs: PackedStringArray = []
		for s in r.scars:
			scar_strs.append(String(s).replace("_", " "))
		lines.append("Scars: " + ", ".join(scar_strs))
	# "What can I do here?" - informational only, cards stay global.
	var dominant := "ind"
	var best := r.ind_share
	if r.tra_share > best:
		dominant = "tra"
		best = r.tra_share
	if r.agr_share > best:
		dominant = "agr"
	lines.append("Relevant policies: %s cards%s" % [WorldEnums.SECTOR_NAMES[StringName(dominant)],
		", restoration" if r.forested else ""])
	_inspector.text = "\n".join(lines)


func clear_region() -> void:
	_inspector.text = "Select a region on the board."


func append_log(year: int, lines: PackedStringArray) -> void:
	_log.append_text("[color=#9aa694][b]-- %d --[/b][/color]\n" % year)
	for line in lines:
		var color := "d8d8d0"
		if line.begins_with("OVERSHOOT") or line.contains("crisis") or line.contains("strikes") \
				or line.contains("fire") or line.contains("devastates") or line.contains("dieback") \
				or line.contains("Drought") or line.contains("fail") or line.contains("crunch") \
				or line.contains("collapses") or line.contains("Permafrost") or line.contains("Ocean sink"):
			color = "e0a080"
		elif line.begins_with("COMBO") or line.contains("PROJECT COMPLETE") \
				or line.contains("New policy available"):
			color = "e8d48a"
		elif line.contains("Rebuild better") or line.contains("window for change") \
				or line.contains("answered") or line.contains("seized") or line.contains("hold") \
				or line.contains("dips back") or line.contains("Relief"):
			color = "a0d890"
		_log.append_text("[color=#%s]%s[/color]\n" % [color, line.replace("[", "[lb]")])


func clear_log() -> void:
	_log.clear()
