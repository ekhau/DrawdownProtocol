class_name RightDock
extends PanelContainer
## Right dock: Region Inspector (top) + turn log (bottom). Reserved space so
## selection never occludes the board (data/board_layout_notes.md).

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

	var insp_header := Label.new()
	insp_header.text = "REGION INSPECTOR"
	insp_header.add_theme_font_size_override("font_size", 11)
	insp_header.add_theme_color_override("font_color", Color("9aa694"))
	vbox.add_child(insp_header)
	_inspector = RichTextLabel.new()
	_inspector.bbcode_enabled = true
	_inspector.fit_content = false
	_inspector.custom_minimum_size = Vector2(0, 170)
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
				or line.contains("Permafrost") or line.contains("Ocean sink"):
			color = "e0a080"
		elif line.contains("Rebuild better") or line.contains("window for change") \
				or line.contains("dips back") or line.contains("Relief"):
			color = "a0d890"
		_log.append_text("[color=#%s]%s[/color]\n" % [color, line.replace("[", "[lb]")])


func clear_log() -> void:
	_log.clear()
