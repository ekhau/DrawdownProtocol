class_name RunEndScreen
extends PanelContainer
## End screen: a rendering of the terminal TurnRecord plus the POST-MORTEM -
## the pivotal turn that sealed the run's fate (PostMortem heuristic over the
## records, never a second simulation). Ends every run with a reason to
## retry: the mistake named, the knowledge banked, the next city one click
## away (docs/Phase_4/05, 06).

signal new_timeline
signal retry_same_seed
signal open_hub
signal change_city

var _headline: Label
var _subtext: RichTextLabel


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1a1e18", 0.97)
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = Color("d9a441")
	style.content_margin_left = 34.0
	style.content_margin_right = 34.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 22.0
	add_theme_stylebox_override("panel", style)
	anchor_left = 0.26
	anchor_right = 0.74
	anchor_top = 0.16
	anchor_bottom = 0.84
	visible = false

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	_headline = Label.new()
	_headline.add_theme_font_size_override("font_size", 21)
	_headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_headline)
	_subtext = RichTextLabel.new()
	_subtext.bbcode_enabled = true
	_subtext.fit_content = false
	_subtext.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_subtext.add_theme_font_size_override("normal_font_size", 13)
	vbox.add_child(_subtext)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	vbox.add_child(buttons)
	var b1 := Button.new()
	b1.text = "New timeline"
	b1.focus_mode = Control.FOCUS_NONE
	b1.pressed.connect(func() -> void: new_timeline.emit())
	buttons.add_child(b1)
	var b2 := Button.new()
	b2.text = "Retry this world"
	b2.focus_mode = Control.FOCUS_NONE
	b2.pressed.connect(func() -> void: retry_same_seed.emit())
	buttons.add_child(b2)
	var b3 := Button.new()
	b3.text = "Knowledge tree (H)"
	b3.focus_mode = Control.FOCUS_NONE
	b3.pressed.connect(func() -> void: open_hub.emit())
	buttons.add_child(b3)
	var b4 := Button.new()
	b4.text = "Change city"
	b4.focus_mode = Control.FOCUS_NONE
	b4.pressed.connect(func() -> void: change_city.emit())
	buttons.add_child(b4)


func show_outcome(rs: RunState, fresh_meta_cards: Array = []) -> void:
	var rec: TurnRecord = rs.records.back()
	_headline.text = LogFormatter.render("endings", String(rec.end_status))
	match rec.end_status:
		&"WIN_NEUTRAL":
			_headline.add_theme_color_override("font_color", Color("cfe8b8"))
		_:
			_headline.add_theme_color_override("font_color", Color("e0a080"))
	var peak_t := 0.0
	for r in rs.records:
		peak_t = maxf(peak_t, r.temp)
	var lines: PackedStringArray = []
	lines.append("Turn %d (%d) - net %+.1f Gt (city %.0f + world %.0f vs A %.0f) - clock peaked at %.0f%%" % [
		rec.turn, rec.year, rec.net, rec.emissions_city, rec.emissions_world,
		rec.absorption, ClimateCalc.clock_pct(peak_t)])
	lines.append("Allies: %d - Sectors: industry %d%%, transport %d%%, agro %d%%" % [
		rec.allies, roundi(rs.sector(&"ind").progress),
		roundi(rs.sector(&"tra").progress), roundi(rs.sector(&"agr").progress)])
	var summit_notes: PackedStringArray = []
	for sid in rs.summit_results:
		summit_notes.append("%s %s" % [String(sid).replace("_", " "), rs.summit_results[sid]])
	if summit_notes.size() > 0:
		lines.append("Summits: " + ", ".join(summit_notes))
	if rs.feedback_years.size() > 0:
		var fb_strs: PackedStringArray = []
		for id in rs.feedback_years:
			fb_strs.append("%s (%d)" % [String(id).replace("_", " "), rs.feedback_years[id]])
		lines.append("Feedback loops triggered: " + ", ".join(fb_strs))
	# --- The post-mortem: name the turn, name the mistake. ---
	var pm := PostMortem.analyze(rs.records, rs.catalog)
	if not pm.is_empty():
		lines.append("")
		lines.append("[color=#f2c894][b]POST-MORTEM - %s[/b][/color]" % String(pm["headline"]))
		for line in pm["lines"]:
			lines.append("[color=#d8d8d0]- %s[/color]" % String(line))
	for card_id in fresh_meta_cards:
		lines.append("")
		lines.append("[color=#b8e8b0]LESSON LEARNED: %s is now in every future deck.[/color]" % String(card_id))
	lines.append("")
	lines.append("[color=#e8d48a]Knowledge gained: %d points[/color] (total: %d)" % [rec.kp_awarded, Meta.kp_total])
	lines.append("[color=#9aa694]Even a failed timeline teaches us something permanent. Spend it in the Knowledge tree - the next run starts smarter.[/color]")
	_subtext.text = "\n".join(lines)
	visible = true
