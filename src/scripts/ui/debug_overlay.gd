class_name DebugOverlay
extends PanelContainer
## F3 developer overlay (docs/Phase_3/05): run header, flags, world table,
## log tail, autoplay regression buttons. Updates on signals, never per frame.

signal restart_requested(seed_value: int)
signal autoplay_requested(strategy: StringName)
signal advance10_requested

var _text: RichTextLabel
var _sim: Sim


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.06, 0.93)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", style)
	anchor_left = 0.0
	anchor_right = 0.44
	anchor_top = 0.09
	anchor_bottom = 0.78
	visible = false

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = false
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 11)
	vbox.add_child(_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	vbox.add_child(row)
	_button(row, "Autoplay Safe", func() -> void: autoplay_requested.emit(&"safe"))
	_button(row, "Risky", func() -> void: autoplay_requested.emit(&"risky"))
	_button(row, "Mixed", func() -> void: autoplay_requested.emit(&"mixed"))
	_button(row, "+10 yrs (pass)", func() -> void: advance10_requested.emit())
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	vbox.add_child(row2)
	_button(row2, "Restart same seed", func() -> void: restart_requested.emit(_sim.current_seed))
	_button(row2, "Restart seed+1", func() -> void: restart_requested.emit(_sim.current_seed + 1))
	_button(row2, "Copy seed", func() -> void: DisplayServer.clipboard_set(str(_sim.current_seed)))


func _button(parent: Control, text: String, fn: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 11)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(fn)
	parent.add_child(b)


func bind(sim: Sim) -> void:
	_sim = sim


func refresh() -> void:
	if not visible or _sim == null or _sim.run_state == null:
		return
	var rs := _sim.run_state
	var lines: PackedStringArray = []
	var band_names := ["stable", "OVERSHOOT-I", "OVERSHOOT-II"]
	lines.append("seed %d   year %d   band %s   phase %s" % [rs.run_seed, rs.year,
		band_names[rs.warming_band()], RunState.Phase.keys()[rs.phase]])
	lines.append("T %.3f  E %.2f  A %.2f  N %+.2f   M %.0f  H %.1f  I %.1f  allies %d  R %.0f (adapt %.0f)" % [
		rs.temp, rs.gross_emissions(), rs.absorption, rs.net_emissions(),
		rs.money, rs.happiness, rs.influence, rs.allies, rs.resilience(), rs.adapt])
	lines.append("flags: media=%s window=%s fire_discount=%s flood_rebuild=%s  fires=%d  e_extra=%.1f" % [
		rs.media, rs.window, rs.fire_discount, rs.flood_rebuild, rs.fires, rs.e_extra])
	var crisis_strs: PackedStringArray = []
	for crisis in rs.pending_crises:
		crisis_strs.append("%s%s" % [crisis["id"], "(ok)" if crisis["answered"] else ""])
	lines.append("crises: [%s]  answered=%d  chain=%d (x%.1f)  combos=%d  kp_earned=%d" % [
		", ".join(crisis_strs), rs.crises_answered_total, rs.combo_chain,
		SocietyCalc.combo_mult(rs.combo_chain), rs.combos_total, rs.kp_earned])
	var proj_strs: PackedStringArray = []
	for ps in rs.active_projects:
		proj_strs.append("%s(%dy)" % [ps.id, ps.years_left])
	for pid in rs.project_history:
		proj_strs.append("%s:%s" % [pid, rs.project_history[pid]])
	lines.append("projects: [%s]  unlocked: %s" % [", ".join(proj_strs),
		", ".join(PackedStringArray(rs.unlocked_card_ids))])
	var fb_strs: PackedStringArray = []
	for ev in rs.catalog.feedback_events():
		var id := String(ev["id"])
		if rs.feedback_years.has(id):
			fb_strs.append("%s@%d" % [id, rs.feedback_years[id]])
		else:
			var trig: Dictionary = ev.get("trigger", {})
			if trig.has("temp_gte"):
				fb_strs.append("%s armed T>=%.2f" % [id, float(trig["temp_gte"])])
			else:
				fb_strs.append("%s armed fires %d of %d" % [id, rs.fires, int(trig["fires_gte"])])
	lines.append("feedbacks: " + " | ".join(fb_strs))
	var q_strs: PackedStringArray = []
	for entry in rs.reforest_queue:
		q_strs.append("+%.1fx%dyr" % [entry.per_year, entry.years_left])
	lines.append("reforest queue: [%s]" % ", ".join(q_strs))
	var sect_strs: PackedStringArray = []
	for sid in WorldEnums.SECTOR_ORDER:
		var ss := rs.sector(sid)
		sect_strs.append("%s %.0f%% (cap %.0f%s)" % [sid, ss.progress, ss.cap(),
			"" if ss.suff_played else ", no suff"])
	lines.append("sectors: " + " | ".join(sect_strs))
	lines.append("")
	lines.append("-- world --")
	for r in rs.world:
		var tags: PackedStringArray = []
		if r.coastal:
			tags.append("c")
		if r.arid:
			tags.append("a")
		if r.forested:
			tags.append("f")
		var ally: String = ["-", "ALLY", "HOME"][r.ally_state]
		lines.append("%s %-14s %-20s %s [%s] shares i%.2f t%.2f a%.2f s%.2f scars:%d" % [
			r.id, r.display_name, r.archetype, ally, ",".join(tags),
			r.ind_share, r.tra_share, r.agr_share, r.sink_share, r.scars.size()])
	lines.append("")
	lines.append("-- log tail --")
	if not rs.records.is_empty():
		var rec: TurnRecord = rs.records.back()
		var tail := rec.log_lines.slice(maxi(0, rec.log_lines.size() - 8))
		for l in tail:
			lines.append("  " + l)
	_text.text = "\n".join(lines)
