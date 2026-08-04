extends Control
## The whole MVP interface, built in code (placeholder art = styleboxes and text).
## RULE: this script contains zero game logic. It calls the five Game verbs and
## repaints from signals. If you find yourself computing a rule here — stop.

var thermometer: ProgressBar
var thermo_markers: Control         # overlay: needle, band ticks, ◆ projection
var thermo_caption: Label
var neutrality := {}                # cached Game.neutrality_projection() for draw
var tipping_hotspots := {}          # tipping id -> invisible tooltip Control over its ▲ marker
var thermo_label: Label
var year_label: Label
var act_label: Label
var money_label: Label
var income_label: Label
var popularity_label: Label
var popularity_bar: ProgressBar
var pop_markers: Control         # overlay: collapse / social-unrest / card-gate thresholds
var gate_marks: Array = []       # distinct requires_popularity values in the catalog
var net_label: Label
var sector_panels := {}          # sector_id -> {panel, style, title, stats}
var market_box: HBoxContainer
var reroll_btn: Button
var end_turn_btn: Button
var log_lines: VBoxContainer
var log_scroll: ScrollContainer
var modal: Control
var modal_panel: PanelContainer
var modal_style: StyleBoxFlat
var modal_title: Label
var modal_flavor: Label
var modal_buttons: VBoxContainer
var banner: Label
var overlay: Control             # post-mortem / help
var overlay_text: RichTextLabel
var overlay_btn: Button
var era_modal: Control           # act interstitial — topmost, covers even the crisis modal
var era_style: StyleBoxFlat
var era_title: Label
var era_body: RichTextLabel
var risk_modal: Control          # gamble confirm: odds, outcomes, campaign boosts
var risk_title: Label
var risk_odds: Label
var risk_success: Label
var risk_fail: Label
var risk_boost_btn: Button
var risk_attempt_btn: Button
var risk_card_id := ""
var risk_boosts := 0
var intro_shown := false         # the launch intro plays once per session, not per run


func _ready() -> void:
	_build_layout()
	Game.run_started.connect(_on_run_started)
	Game.resources_changed.connect(_refresh_stats)
	Game.sector_changed.connect(func(_id):
		_refresh_sectors()
		_refresh_stats())
	Game.temperature_changed.connect(func(_t): _refresh_stats())
	Game.phase_changed.connect(_on_phase_changed)
	Game.market_changed.connect(_refresh_market)
	Game.combo_discovered.connect(_on_combo)
	Game.risk_resolved.connect(_on_risk_resolved)
	Game.tipping_point_crossed.connect(_on_tipping_point)
	Game.era_started.connect(_on_era)
	Game.log_line.connect(_on_log)
	Game.run_ended.connect(_on_run_ended)
	Game.new_run()


# --- layout -------------------------------------------------------------------

func _build_layout() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	# Top bar
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	root.add_child(top)
	var year_box := VBoxContainer.new()
	top.add_child(year_box)
	year_label = _label(year_box, "2030", 26)
	_tip(year_label, "The current year. One turn = one year.")
	act_label = _label(year_box, "", 13)
	act_label.modulate.a = 0.8
	_tip(act_label, "The current act. New acts (2038, 2044) unlock deeper technology\nand lower the hard-to-abate floors.")
	var thermo_box := VBoxContainer.new()
	thermo_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(thermo_box)
	var thermo_tip := "Global climate — clock and engine in one bar. Each year the planet warms by net emissions × 0.002°;\nat +2.0° the timeline fails. Pink lines: crisis cost bands.\nDark red ▲: tipping points — cross one and the planet scars permanently (hover each for details).\nFrom the white needle, next year's gross jump is sketched: the orange segment ends exactly where\nthe needle lands when the year ends; green = the push your absorption cancels. No orange left = net zero.\n◆: where warming stops if you keep your recent pace of cuts."
	var thermo_head := HBoxContainer.new()
	thermo_head.alignment = BoxContainer.ALIGNMENT_CENTER
	thermo_head.add_theme_constant_override("separation", 24)
	thermo_box.add_child(thermo_head)
	thermo_label = _label(thermo_head, "+1.50°", 30)
	_tip(thermo_label, thermo_tip)
	net_label = _label(thermo_head, "Net 20", 30)
	_tip(net_label, "Net emissions = gross − absorption. This number heats the planet each year.\nReach net ≤ 0 (without one-year windfalls) to win.")
	thermometer = ProgressBar.new()
	thermometer.min_value = 1.5
	thermometer.max_value = 2.0
	thermometer.step = 0.001
	thermometer.show_percentage = false
	thermometer.custom_minimum_size = Vector2(0, 22)
	thermo_box.add_child(thermometer)
	thermo_markers = Control.new()
	thermo_markers.set_anchors_preset(Control.PRESET_FULL_RECT)
	thermo_markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thermo_markers.draw.connect(_draw_thermo_markers)
	thermo_markers.resized.connect(thermo_markers.queue_redraw)
	_tip(thermometer, thermo_tip)
	thermometer.add_child(thermo_markers)
	# One invisible hotspot per tipping point carries its tooltip — the marker
	# overlay ignores the mouse, so hover zones live as thin thermometer children.
	for tp in Game.tipping_points():
		var hot := Control.new()
		hot.mouse_filter = Control.MOUSE_FILTER_PASS
		thermometer.add_child(hot)
		tipping_hotspots[tp.id] = hot
	thermometer.resized.connect(_refresh_tipping_markers)
	thermo_caption = _label(thermo_box, "", 13)
	thermo_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip(thermo_caption, "The carbon arithmetic feeding the bar, and the ◆ verdict: where the mercury lands\nif the current pace of cuts holds (absorption frozen at today's value, era floors respected).")
	money_label = _label(top, "M$10", 26)
	_tip(money_label, "Money funds cards and crisis responses.\nIncome arrives at each year's end — dirty sectors pay more, for now.")
	income_label = _label(top, "+0M$/yr", 18)
	income_label.add_theme_color_override("font_color", Color("#5ec962"))
	_tip(income_label, "Income you'll collect when this year ends: all sector incomes plus bonuses.")
	var cfg: Dictionary = Game.catalog.config
	var pop_tip := "The government's approval rating — your licence to govern.\nSpent by bold cards and crisis choices; drifts %d%%/yr back toward %d%%.\nBelow %d%% the streets take over: social crises replace the year's crisis.\nBelow %d%% the government falls — though your own purchases can never take you there.\nThe most radical cards demand a popular government (green marks)." % [
		int(cfg.popularity_drift), int(cfg.popularity_baseline),
		int(cfg.social_crisis_threshold), int(cfg.popularity_collapse)]
	var pop_box := VBoxContainer.new()
	top.add_child(pop_box)
	popularity_label = _label(pop_box, "Popularity 50%", 26)
	_tip(popularity_label, pop_tip)
	popularity_bar = ProgressBar.new()
	popularity_bar.min_value = 0
	popularity_bar.max_value = 100
	popularity_bar.show_percentage = false
	popularity_bar.custom_minimum_size = Vector2(0, 10)
	pop_box.add_child(popularity_bar)
	pop_markers = Control.new()
	pop_markers.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop_markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_markers.draw.connect(_draw_popularity_markers)
	pop_markers.resized.connect(pop_markers.queue_redraw)
	popularity_bar.add_child(pop_markers)
	_tip(popularity_bar, pop_tip)
	for card in Game.catalog.cards:
		var req := int(card.get("requires_popularity", 0))
		if req > 0 and not gate_marks.has(req):
			gate_marks.append(req)
	gate_marks.sort()
	var help_btn := Button.new()
	help_btn.text = "?"
	help_btn.tooltip_text = "Rules"
	help_btn.pressed.connect(_show_help)
	top.add_child(help_btn)

	# Center: sector panels
	var center := HBoxContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 8)
	root.add_child(center)
	for s in Game.catalog.config.sectors:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2)
		style.set_corner_radius_all(8)
		panel.add_theme_stylebox_override("panel", style)
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(v)
		var title := _label(v, s.name, 22)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var stats := _label(v, "", 17)
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		center.add_child(panel)
		sector_panels[s.id] = {"panel": panel, "style": style, "title": title, "stats": stats}

	# Turn log (collapsible)
	var log_toggle := Button.new()
	log_toggle.tooltip_text = "Every change and its cause, year by year."
	log_toggle.text = "Turn log ▾"
	log_toggle.toggle_mode = true
	log_toggle.button_pressed = true
	root.add_child(log_toggle)
	log_scroll = ScrollContainer.new()
	log_scroll.custom_minimum_size = Vector2(0, 130)
	root.add_child(log_scroll)
	log_lines = VBoxContainer.new()
	log_lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_scroll.add_child(log_lines)
	log_toggle.toggled.connect(func(on):
		log_scroll.visible = on
		log_toggle.text = "Turn log ▾" if on else "Turn log ▸")

	# Bottom: market + actions
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	root.add_child(bottom)
	market_box = HBoxContainer.new()
	market_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_box.add_theme_constant_override("separation", 8)
	bottom.add_child(market_box)
	reroll_btn = Button.new()
	reroll_btn.pressed.connect(Game.reroll)
	bottom.add_child(reroll_btn)
	end_turn_btn = Button.new()
	end_turn_btn.tooltip_text = "Collect income, then the planet warms by net emissions × 0.002°."
	end_turn_btn.text = "End Year ▶"
	end_turn_btn.custom_minimum_size = Vector2(140, 60)
	end_turn_btn.pressed.connect(Game.end_turn)
	bottom.add_child(end_turn_btn)

	# Era banner (hidden until an era fires)
	banner = _label(self, "", 34)
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.position.y = 120
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.modulate.a = 0.0

	# Crisis modal
	modal = _full_overlay()
	var modal_center := CenterContainer.new()
	modal_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(modal_center)
	modal_panel = PanelContainer.new()
	modal_panel.custom_minimum_size = Vector2(560, 0)
	modal_style = StyleBoxFlat.new()
	modal_style.bg_color = Color(0.12, 0.12, 0.14)
	modal_style.set_corner_radius_all(10)
	modal_style.set_border_width_all(3)
	modal_panel.add_theme_stylebox_override("panel", modal_style)
	modal_center.add_child(modal_panel)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 10)
	modal_panel.add_child(mv)
	modal_title = _label(mv, "", 28)
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_flavor = _label(mv, "", 17)
	modal_flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_buttons = VBoxContainer.new()
	modal_buttons.add_theme_constant_override("separation", 8)
	mv.add_child(modal_buttons)

	# Post-mortem / help overlay
	overlay = _full_overlay()
	var oc := CenterContainer.new()
	oc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(oc)
	var op := PanelContainer.new()
	op.custom_minimum_size = Vector2(640, 0)
	var op_style := StyleBoxFlat.new()
	op_style.bg_color = Color(0.1, 0.11, 0.12)
	op_style.set_corner_radius_all(10)
	op_style.set_border_width_all(2)
	op_style.border_color = Color(0.4, 0.44, 0.45)
	op_style.set_content_margin_all(18)
	op.add_theme_stylebox_override("panel", op_style)
	oc.add_child(op)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 10)
	op.add_child(ov)
	overlay_text = RichTextLabel.new()
	overlay_text.bbcode_enabled = true
	overlay_text.fit_content = true
	overlay_text.custom_minimum_size = Vector2(600, 0)
	ov.add_child(overlay_text)
	overlay_btn = Button.new()
	ov.add_child(overlay_btn)

	# Gamble confirm dialog — the game's only two-step purchase: a risk card
	# shows its odds and both outcomes, and lets the player buy campaign boosts
	# before committing to the roll.
	risk_modal = _full_overlay()
	var rcenter := CenterContainer.new()
	rcenter.set_anchors_preset(Control.PRESET_FULL_RECT)
	risk_modal.add_child(rcenter)
	var rpanel := PanelContainer.new()
	rpanel.custom_minimum_size = Vector2(520, 0)
	var rstyle := StyleBoxFlat.new()
	rstyle.bg_color = Color(0.12, 0.12, 0.14)
	rstyle.set_corner_radius_all(10)
	rstyle.set_border_width_all(3)
	rstyle.border_color = Color("#e8c34a")
	rstyle.set_content_margin_all(16)
	rpanel.add_theme_stylebox_override("panel", rstyle)
	rcenter.add_child(rpanel)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 10)
	rpanel.add_child(rv)
	risk_title = _label(rv, "", 26)
	risk_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	risk_odds = _label(rv, "", 40)
	risk_odds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip(risk_odds, "The chance the reform passes: your popularity plus the card's own bias,\nplus campaign spending. Capped — certainty is not for sale.")
	risk_success = _label(rv, "", 16)
	risk_success.add_theme_color_override("font_color", Color("#5ec962"))
	risk_fail = _label(rv, "", 16)
	risk_fail.add_theme_color_override("font_color", Color("#fc8961"))
	risk_boost_btn = Button.new()
	risk_boost_btn.custom_minimum_size = Vector2(0, 40)
	risk_boost_btn.pressed.connect(func():
		risk_boosts += 1
		_refresh_risk_dialog())
	rv.add_child(risk_boost_btn)
	var risk_row := HBoxContainer.new()
	risk_row.add_theme_constant_override("separation", 8)
	rv.add_child(risk_row)
	risk_attempt_btn = Button.new()
	risk_attempt_btn.custom_minimum_size = Vector2(0, 48)
	risk_attempt_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	risk_attempt_btn.pressed.connect(_attempt_risk)
	risk_row.add_child(risk_attempt_btn)
	var risk_cancel := Button.new()
	risk_cancel.text = "Not now"
	risk_cancel.custom_minimum_size = Vector2(120, 48)
	risk_cancel.pressed.connect(func(): risk_modal.visible = false)
	risk_row.add_child(risk_cancel)

	# Act interstitial — added last so it stacks above the crisis modal: on an
	# era turn the act card is read (and dismissed) before the year's crisis.
	era_modal = _full_overlay()
	var ec := CenterContainer.new()
	ec.set_anchors_preset(Control.PRESET_FULL_RECT)
	era_modal.add_child(ec)
	var ep := PanelContainer.new()
	ep.custom_minimum_size = Vector2(640, 0)
	era_style = StyleBoxFlat.new()
	era_style.bg_color = Color(0.1, 0.11, 0.12)
	era_style.set_corner_radius_all(10)
	era_style.set_border_width_all(3)
	ep.add_theme_stylebox_override("panel", era_style)
	ec.add_child(ep)
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 12)
	ep.add_child(ev)
	era_title = _label(ev, "", 32)
	era_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	era_body = RichTextLabel.new()
	era_body.bbcode_enabled = true
	era_body.fit_content = true
	era_body.custom_minimum_size = Vector2(600, 0)
	ev.add_child(era_body)
	var era_btn := Button.new()
	era_btn.text = "Onward ▶"
	era_btn.custom_minimum_size = Vector2(0, 48)
	era_btn.pressed.connect(func(): era_modal.visible = false)
	ev.add_child(era_btn)


func _full_overlay() -> Control:
	var o := Control.new()
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(dim)
	add_child(o)
	return o


func _label(parent: Node, text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l


func _tip(c: Control, text: String) -> void:
	c.tooltip_text = text
	# Labels ignore the mouse by default, which also swallows their tooltip.
	if c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		c.mouse_filter = Control.MOUSE_FILTER_PASS


# --- repaint from signals -----------------------------------------------------

func _on_run_started() -> void:
	for child in log_lines.get_children():
		child.queue_free()
	overlay.visible = false
	_refresh_stats()
	_refresh_sectors()
	_refresh_market()
	# The sim's first phase_changed fires before Game connects our signals —
	# repaint from the current phase so a turn-1 crisis modal isn't lost.
	_on_phase_changed(Game.state().phase)
	# First launch: intro (theme + rules), then the Act I card. Replays skip
	# straight to the act card — restart friction stays low.
	if intro_shown:
		_show_era_screen(Game.state().era_for_year(Game.state().year).id)
	else:
		intro_shown = true
		_show_intro()


func _refresh_stats() -> void:
	var s: RunState = Game.state()
	if s == null:
		return
	year_label.text = str(s.year)
	act_label.text = s.era_for_year(s.year).name
	thermo_label.text = "+%.2f°" % s.temp
	var tween := create_tween()
	tween.tween_property(thermometer, "value", s.temp, 0.4)
	var heat := clampf((s.temp - 1.5) / 0.5, 0.0, 1.0)
	# self_modulate: heat-tint the mercury only — the overlay's orange/green
	# jump segments carry meaning and must keep their true colors.
	thermometer.self_modulate = Color(1.0, 1.0 - heat * 0.7, 1.0 - heat)
	neutrality = Game.neutrality_projection()
	var gross := s.gross_emissions()
	var net := s.net_emissions()
	var green := Color("#5ec962")
	var orange := Color("#fc8961")
	net_label.text = "Net %d" % net
	net_label.add_theme_color_override("font_color", green if s.structural_net() <= 0 else Color.WHITE)
	# Honest arithmetic: sector panels no longer sum to gross once the planet
	# emits on its own — the caption carries the planetary share.
	var gross_text := "gross %d" % gross
	if s.world_emissions > 0:
		gross_text = "gross %d (incl. %d planetary)" % [gross, s.world_emissions]
	if s.structural_net() <= 0:
		thermo_caption.text = "all %d emissions absorbed — carbon neutral · end the year ▶" % gross
		thermo_caption.add_theme_color_override("font_color", green)
	elif neutrality.reachable:
		thermo_caption.text = "%s − absorbed %d = net %d · ◆ net zero ≈ %d, at +%.2f°" % [
			gross_text, s.absorption, net, neutrality.year, neutrality.temp]
		thermo_caption.add_theme_color_override("font_color", green)
	else:
		thermo_caption.text = "%s − absorbed %d = net %d · ◆ +%.1f° first at this pace — cut faster" % [
			gross_text, s.absorption, net, thermometer.max_value]
		thermo_caption.add_theme_color_override("font_color", orange)
	thermo_markers.queue_redraw()
	_refresh_tipping_markers()
	money_label.text = "M$%d" % s.money
	income_label.text = "+%dM$/yr" % s.total_income()
	var cfg: Dictionary = Game.catalog.config
	popularity_label.text = "Popularity %d%%" % s.popularity
	var pop_color := Color.WHITE
	if s.popularity < int(cfg.social_crisis_threshold):
		pop_color = Color("#fc8961")
	elif not gate_marks.is_empty() and s.popularity >= int(gate_marks[0]):
		pop_color = Color("#5ec962")
	popularity_label.add_theme_color_override("font_color", pop_color)
	popularity_bar.value = s.popularity
	popularity_bar.self_modulate = pop_color
	pop_markers.queue_redraw()
	_refresh_market()


func _draw_thermo_markers() -> void:
	var s: RunState = Game.state()
	if s == null or neutrality.is_empty():
		return
	var w := thermo_markers.size.x
	var h := thermo_markers.size.y
	var tx := clampf(_thermo_x(s.temp, w), 1.0, w - 1.0)
	# Scale ticks every 0.1°
	var v := thermometer.min_value + 0.1
	while v < thermometer.max_value - 0.001:
		var x := _thermo_x(v, w)
		thermo_markers.draw_line(Vector2(x, 0), Vector2(x, h), Color(1, 1, 1, 0.2), 1.0)
		v += 0.1
	# Next year's gross jump, anchored at the needle and projected into degrees
	# (× warming_per_net_emission). Edges are destinations: orange [needle →
	# landing] is the net push — its right edge is exactly where the needle
	# stands when the year ends. Green [landing → gross end] is the slice of
	# the jump absorption cancels. Green swallowing it all = net zero.
	var per_unit := float(Game.catalog.config.warming_per_net_emission)
	var net_x := _thermo_x(s.temp + maxi(s.net_emissions(), 0) * per_unit, w)
	var gross_x := _thermo_x(s.temp + s.gross_emissions() * per_unit, w)
	thermo_markers.draw_rect(Rect2(tx, 3, net_x - tx, h - 6), Color("#fc8961", 0.45))
	thermo_markers.draw_rect(Rect2(net_x, 3, gross_x - net_x, h - 6), Color("#5ec962", 0.45))
	if net_x > tx:
		# Landing line: crisp edge on where the needle stands next year.
		thermo_markers.draw_line(Vector2(net_x, 3), Vector2(net_x, h - 3), Color("#fc8961"), 2.0)
	# Band boundaries — crisis costs bump past these
	for band in Game.catalog.config.bands:
		if float(band.min_temp) > thermometer.min_value:
			var bx := _thermo_x(float(band.min_temp), w)
			thermo_markers.draw_line(Vector2(bx, 0), Vector2(bx, h), Color("#b73779", 0.8), 2.0)
	# Tipping points — dark red ▲ rising from the bar's base: cross one and the
	# planet scars permanently. Crossed points dim — that damage is done.
	for tp in Game.tipping_points():
		var px := _thermo_x(float(tp.temp), w)
		var tcolor := Color("#a4161a", 0.35 if tp.crossed else 1.0)
		thermo_markers.draw_colored_polygon(PackedVector2Array([
			Vector2(px - 6, h), Vector2(px + 6, h), Vector2(px, h - 9)]), tcolor)
	# ◆ where the mercury stops if the current pace holds
	var nx := clampf(_thermo_x(float(neutrality.temp), w), 7.0, w - 7.0)
	var ncolor := Color("#5ec962") if neutrality.reachable else Color("#fc8961")
	var cy := h / 2.0
	thermo_markers.draw_colored_polygon(PackedVector2Array([
		Vector2(nx, cy - 7), Vector2(nx + 7, cy), Vector2(nx, cy + 7), Vector2(nx - 7, cy)]), ncolor)
	# Needle: current warming
	thermo_markers.draw_line(Vector2(tx, 0), Vector2(tx, h), Color.WHITE, 2.0)
	thermo_markers.draw_colored_polygon(PackedVector2Array([
		Vector2(clampf(tx - 5, 0, w), 0), Vector2(clampf(tx + 5, 0, w), 0), Vector2(tx, 6)]), Color.WHITE)


func _draw_popularity_markers() -> void:
	# The three zones the player reasons about, drawn where they sit on 0-100:
	# red = the collapse floor, orange = social unrest, green = card gates.
	var cfg: Dictionary = Game.catalog.config
	var w := pop_markers.size.x
	var h := pop_markers.size.y
	var collapse_x := w * int(cfg.popularity_collapse) / 100.0
	var social_x := w * int(cfg.social_crisis_threshold) / 100.0
	pop_markers.draw_line(Vector2(collapse_x, 0), Vector2(collapse_x, h), Color("#ff5c5c"), 2.0)
	pop_markers.draw_line(Vector2(social_x, 0), Vector2(social_x, h), Color("#fc8961"), 2.0)
	for req in gate_marks:
		var gx := w * int(req) / 100.0
		pop_markers.draw_line(Vector2(gx, 0), Vector2(gx, h), Color("#5ec962"), 2.0)


func _refresh_tipping_markers() -> void:
	# Position each tipping point's tooltip hotspot over its ▲ and keep the
	# tooltip text tracking crossed status. Drawing lives in _draw_thermo_markers.
	var w := thermometer.size.x
	for tp in Game.tipping_points():
		var hot: Control = tipping_hotspots.get(tp.id)
		if hot == null:
			continue
		hot.position = Vector2(_thermo_x(float(tp.temp), w) - 8.0, 0)
		hot.size = Vector2(16, thermometer.size.y)
		hot.tooltip_text = "%s — tipping point at +%.2f°\n%s\nIf crossed: %s\n%s" % [
			tp.name, float(tp.temp), tp.flavor,
			Effects.describe(tp.effects, Game.catalog),
			"☠ CROSSED — the scar is permanent" if tp.crossed else "Not yet crossed — keep the mercury below it."]


func _thermo_x(value: float, width: float) -> float:
	var t := (value - thermometer.min_value) / (thermometer.max_value - thermometer.min_value)
	return clampf(t, 0.0, 1.0) * width


func _refresh_sectors() -> void:
	var s: RunState = Game.state()
	if s == null:
		return
	var palette := Game.era_palette()
	for id in sector_panels:
		var p: Dictionary = sector_panels[id]
		var sector: Dictionary = s.sectors[id]
		p.style.bg_color = palette.sample(s.decarbonization(id)).darkened(0.25)
		var floor_value: int = s.sector_floor(id)
		var floor_note := "  (era floor %d)" % floor_value if sector.emissions <= floor_value and floor_value > 0 else ""
		p.stats.text = "Emissions %d%s\nIncome %dM$/turn" % [sector.emissions, floor_note, sector.income]
		p.panel.tooltip_text = "%s: emits %d/yr and pays %dM$/yr.\nThis act can't cut it below %d — deeper cuts need later tech.\nPanel color tracks decarbonization: dark → the act's palette." % [
			sector.name, sector.emissions, sector.income, floor_value]
	_refresh_stats()


func _refresh_market() -> void:
	var s: RunState = Game.state()
	if s == null:
		return
	# remove_child before queue_free: this repaints several times per frame
	# (mid-buy signals), and pending-deletion buttons would stack in the HBox.
	for child in market_box.get_children():
		market_box.remove_child(child)
		child.queue_free()
	for card_id in Game.sim.market.offer:
		market_box.add_child(_card_button(card_id, s))
	if Game.sim.market.offer.size() < int(Game.catalog.config.market_size):
		var pool_left: int = Game.sim.market.pool.size()
		var note := _label(market_box, "every card is in play" if pool_left == 0
			else "%d more cards unlock in later eras" % pool_left, 14)
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.modulate.a = 0.55
	var reroll_cost := int(Game.catalog.config.reroll_cost)
	if Game.sim.market.rerolled_this_turn:
		reroll_btn.text = "Rerolled ✓"
		reroll_btn.tooltip_text = "One reroll per year — back next year."
	else:
		reroll_btn.text = "Reroll (%dM$)" % reroll_cost
		reroll_btn.tooltip_text = ("Need %dM$ to reroll." % reroll_cost) if s.money < reroll_cost \
			else "Pay %dM$ to deal a fresh market. Once per year." % reroll_cost
	reroll_btn.disabled = s.phase != RunState.Phase.ACTION or not Game.sim.market.can_reroll()
	end_turn_btn.disabled = s.phase != RunState.Phase.ACTION


func _card_button(card_id: String, s: RunState) -> Button:
	var card: Dictionary = Game.catalog.cards_by_id[card_id]
	var blockers: Dictionary = Game.sim.market.blockers(card_id)
	var is_risk := card.has("risk")
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 96 if is_risk else 84)
	b.disabled = s.phase != RunState.Phase.ACTION or not Game.sim.market.can_buy(card_id)
	if is_risk:
		b.pressed.connect(_show_risk_dialog.bind(card_id))
		b.tooltip_text = "A gamble: opens a confirm dialog with the odds and both outcomes.\nOne attempt per run — the card is consumed win or lose."
	else:
		b.pressed.connect(Game.buy_card.bind(card_id))
		b.tooltip_text = "Effects are immediate and permanent.\nBought cards leave the pool for the rest of the run."
	var cost := "%dM$" % int(card.cost_money)
	if blockers.has("money"):
		cost = "[color=#ff5c5c]%s[/color]" % cost
	if int(card.cost_popularity) > 0:
		var pop := "%d%% popularity" % int(card.cost_popularity)
		if blockers.has("popularity") or blockers.has("popularity_floor"):
			pop = "[color=#ff5c5c]%s[/color]" % pop
		cost += " + " + pop
	var gate := int(card.get("requires_popularity", 0))
	if gate > 0:
		var req := "req ≥%d%%" % gate
		if blockers.has("popularity_gate"):
			req = "[color=#ff5c5c]%s[/color]" % req
		cost += " · " + req
	var text: String
	if is_risk:
		text = "[center]%s  (%s · odds %d%%)\n✓ %s\n[color=#fc8961]✘ %s[/color]" % [
			card.name, cost, Game.sim.market.success_chance(card_id),
			Effects.describe(card.effects, Game.catalog),
			Effects.describe(card.risk.on_fail, Game.catalog)]
	else:
		text = "[center]%s  (%s)\n%s" % [card.name, cost, Effects.describe(card.effects, Game.catalog)]
	if s.phase == RunState.Phase.ACTION and not blockers.is_empty():
		var why: PackedStringArray = []
		if blockers.has("money"):
			why.append("need %dM$ more" % int(blockers.money))
		if blockers.has("popularity_gate"):
			why.append("too unpopular — needs ≥%d%%" % int(blockers.popularity_gate))
		if blockers.has("popularity"):
			why.append("need %d%% more popularity" % int(blockers.popularity))
		if blockers.has("popularity_floor"):
			why.append("would collapse the government (<%d%%)" % int(Game.catalog.config.popularity_collapse))
		if blockers.has("risk_floor"):
			why.append("too risky — failure could collapse the government")
		text += "\n[color=#fc8961]✗ %s[/color]" % ", ".join(why)
	text += "[/center]"
	# Buttons can't render bbcode — a click-transparent RichTextLabel carries
	# the text so the missing resource can glow red inside the cost.
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.set_anchors_preset(Control.PRESET_FULL_RECT)
	rt.offset_left = 6
	rt.offset_right = -6
	rt.offset_top = 4
	rt.add_theme_font_size_override("normal_font_size", 15)
	rt.text = text
	if b.disabled:
		rt.modulate.a = 0.7
	b.add_child(rt)
	return b


func _on_phase_changed(phase: int) -> void:
	if phase == RunState.Phase.CRISIS:
		_show_crisis()
	else:
		modal.visible = false
	_refresh_market()


func _show_crisis() -> void:
	var current: Dictionary = Game.sim.crisis_deck.current
	if current.is_empty():
		return
	var crisis: Dictionary = current.crisis
	var is_windfall: bool = crisis.kind == "windfall"
	var is_social: bool = bool(crisis.get("social", false))
	# Windfalls get the hopeful green accent — relief before reading a word.
	# Social crises burn red: the streets, not the climate, are at the door.
	modal_style.border_color = Color("#5ec962") if is_windfall \
		else (Color("#ff5c5c") if is_social else Color("#b73779"))
	modal_title.text = ("☀ " if is_windfall else ("✊ " if is_social else "⚠ ")) + crisis.name
	modal_flavor.text = crisis.flavor + ("" if is_windfall else "   [band %s]" % current.band)
	for child in modal_buttons.get_children():
		child.queue_free()
	for i in current.responses.size():
		var r: Dictionary = current.responses[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 48)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var perm := "  ⚠ perm" if Effects.is_permanent(r.effects) else ""
		b.text = "%s — %s%s" % [r.name, Effects.describe(r.effects, Game.catalog), perm]
		b.pressed.connect(Game.choose_response.bind(i))
		modal_buttons.add_child(b)
	modal.visible = true


func _on_era(era_id: String) -> void:
	_refresh_sectors()  # palette crossfade: repaint under the new era's colormap
	_show_era_screen(era_id)


func _show_era_screen(era_id: String) -> void:
	var brief: Dictionary = Game.catalog.era_brief(era_id)
	var era: Dictionary = brief.era
	era_style.border_color = Game.palette_gradient(era.palette).sample(0.75)
	era_title.text = era.name
	var lines: PackedStringArray = ["[center][i]%s[/i][/center]" % era.banner, ""]
	if not brief.new_cards.is_empty():
		var names: PackedStringArray = []
		for card in brief.new_cards:
			names.append(card.name)
		lines.append("[b]%d technologies reach the market:[/b] %s." % [brief.new_cards.size(), ", ".join(names)])
	if brief.floor_drops.is_empty():
		var floors: PackedStringArray = []
		for s in Game.catalog.config.sectors:
			floors.append("%s %d" % [s.name, int(era.min_sector_emissions[s.id])])
		lines.append("\n[b]Hard-to-abate floors:[/b] this act's tech can't cut emissions below %s — deeper cuts need later acts." % ", ".join(floors))
	else:
		var drops: PackedStringArray = []
		for d in brief.floor_drops:
			drops.append("%s %d → %d" % [d.name, int(d.was), int(d.now)])
		lines.append("\n[b]Deeper cuts unlock:[/b] the hard-to-abate floors fall — %s." % ", ".join(drops))
	era_body.text = "\n".join(lines)
	era_modal.visible = true


func _show_risk_dialog(card_id: String) -> void:
	risk_card_id = card_id
	risk_boosts = 0
	_refresh_risk_dialog()
	risk_modal.visible = true


func _refresh_risk_dialog() -> void:
	var card: Dictionary = Game.catalog.cards_by_id[risk_card_id]
	var risk: Dictionary = card.risk
	var s: RunState = Game.state()
	var chance: int = Game.sim.market.success_chance(risk_card_id, risk_boosts)
	var total_cost: int = int(card.cost_money) + risk_boosts * int(risk.boost_cost)
	risk_title.text = card.name
	risk_odds.text = "%d%%" % chance
	risk_odds.add_theme_color_override("font_color",
		Color("#5ec962") if chance >= 70 else (Color("#fc8961") if chance < 40 else Color.WHITE))
	risk_success.text = "✓ Passes: %s" % Effects.describe(card.effects, Game.catalog)
	risk_fail.text = "✘ Fails: %s" % Effects.describe(risk.on_fail, Game.catalog)
	risk_boost_btn.text = "Campaign +%d%% (%dM$)  —  %d/%d used" % [
		int(risk.boost_amount), int(risk.boost_cost), risk_boosts, int(risk.boost_max)]
	risk_boost_btn.disabled = risk_boosts >= int(risk.boost_max) or chance >= int(risk.cap) \
		or s.money < total_cost + int(risk.boost_cost)
	risk_attempt_btn.text = "Attempt (%dM$) ▶" % total_cost
	risk_attempt_btn.disabled = s.money < total_cost


func _attempt_risk() -> void:
	risk_modal.visible = false
	Game.buy_card(risk_card_id, risk_boosts)


func _on_risk_resolved(card_id: String, success: bool) -> void:
	var card: Dictionary = Game.catalog.cards_by_id[card_id]
	_flash_banner(("✓ %s PASSES" % card.name) if success else ("✘ %s FAILS — backlash" % card.name))


func _on_combo(combo_id: String) -> void:
	for combo in Game.catalog.combos:
		if combo.id == combo_id:
			_flash_banner("COMBO DISCOVERED — %s" % combo.name)


func _on_tipping_point(tipping_id: String) -> void:
	for tp in Game.tipping_points():
		if tp.id == tipping_id:
			_flash_banner("☠ TIPPING POINT — %s\n%s\n%s" % [
				tp.name, tp.flavor, Effects.describe(tp.effects, Game.catalog)], Color("#ff5c5c"))
	_refresh_tipping_markers()
	thermo_markers.queue_redraw()


func _flash_banner(text: String, color: Color = Color.WHITE) -> void:
	banner.add_theme_color_override("font_color", color)
	banner.text = text
	banner.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(banner, "modulate:a", 0.0, 0.8)


func _on_log(text: String) -> void:
	var s: RunState = Game.state()
	var l := Label.new()
	l.text = "%d  %s" % [s.year if s else 0, text]
	l.add_theme_font_size_override("font_size", 14)
	log_lines.add_child(l)
	await get_tree().process_frame
	log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)


func _on_run_ended(result: Dictionary) -> void:
	modal.visible = false
	era_modal.visible = false
	var verdict := "[b][color=#5ec962]CARBON NEUTRAL[/color][/b]" if result.won \
		else "[b][color=#fc8961]TIMELINE FAILED[/color][/b]"
	var curve := ""
	for snap in result.timeline:
		curve += "%d  +%.2f°  net %d\n" % [snap.year, snap.temp, snap.net]
	var tipping_names: PackedStringArray = []
	for tp in Game.tipping_points():
		if result.tipping_points.has(tp.id):
			tipping_names.append(tp.name)
	overlay_text.text = "%s\n\n[b]Timeline #%d[/b] — %d, +%.2f°\n%s\n\nCombos: %s\nTipping points crossed: %s\n\n[code]%s[/code]" % [
		verdict, result.seed % 1000, result.year, result.temp, result.cause,
		", ".join(result.combos) if result.combos.size() > 0 else "none discovered",
		", ".join(tipping_names) if tipping_names.size() > 0 else "none — the thresholds held",
		curve]
	overlay_btn.text = "Run the next timeline ▶"
	_reset_overlay_button(func(): Game.new_run())
	overlay.visible = true


func _rules_text() -> String:
	return """One turn = one year. Reach [b]net emissions ≤ 0[/b] before the thermometer hits [b]+2.0°[/b].
[b]Popularity[/b] is your licence to govern: below [b]10%[/b] the government falls.

Each year: face a [b]crisis[/b] (every answer costs something — money, popularity, or a permanent scar; costs rise with the thermometer), then [b]buy cards[/b] from the market, then collect [b]income[/b], then the [b]climate[/b] advances by net emissions × 0.002°.

Approval is rented, never owned: popularity drifts 3% a year back toward 50%. Below [b]30%[/b] the streets take over — strikes, riots and no-confidence motions replace the year's crisis until you win the public back (every social crisis has a way out, at a price). The boldest policies (carbon tax, car-free centers…) [b]require[/b] a popular government — the green marks on the popularity bar — and your own purchases can never drop you into collapse; only crises can.

Some cards are [b]gambles[/b] (gold dialog): the chance a reform passes equals your [b]popularity[/b] plus the card's own bias, and campaign money can raise it — capped, certainty is not for sale. One attempt per run: success applies the card, failure triggers the printed backlash. A gamble you can't survive failing is blocked, like any other suicide purchase.

Three [b]tipping points[/b] wait on the climate bar (dark red ▲): cross a threshold and the planet scars [b]permanently[/b] — thawing permafrost adds planetary emissions no card can cut, forest dieback destroys absorption, ice-sheet collapse drains income and approval. Scars never heal; the only defense is never crossing.

On the climate bar: the [b]white needle[/b] is today's warming, pink ticks are the crisis cost bands. From the needle, next year's gross jump is sketched in degrees: the [b]orange segment[/b] ends exactly where the needle stands when the year ends (net × 0.002°), and the [b]green segment[/b] beyond it is the push your absorption cancels. Cut gross or grow absorption until no orange is left — the needle stops: net zero. The [b]◆[/b] marks where the mercury settles if you keep your recent pace of cuts (absorption frozen at today's value) — green means net zero is in reach, orange means +2.0° arrives first.

Dirty income pays now and emits forever. New eras (2038, 2044) unlock deeper cards. Some cards form hidden combos."""


func _show_intro() -> void:
	overlay_text.text = """[center][b]THE DRAWDOWN PROTOCOL[/b][/center]

2030. After a decade of broken pledges, the world's governments hand the climate file to one office with real power: the [b]Drawdown Institute[/b]. You run it.

Your mandate: steer the whole economy — industry, transport, food, housing — to [b]net zero[/b] before the thermometer passes [b]+2.0°[/b]. Every year brings a crisis. Every fix costs money, popularity, or a permanent scar. The public's patience is finite; the warming is not.

[b]How to play[/b]

One turn = one year. Reach [b]net emissions ≤ 0[/b] before the thermometer hits [b]+2.0°[/b]. [b]Popularity[/b] is your licence to govern: below [b]30%[/b] social unrest replaces the year's crisis; below [b]10%[/b] the government falls. It drifts back toward 50% each year, and the boldest policies require a popular government.

Each year: face a [b]crisis[/b] (every answer costs something, and costs rise as the planet warms), then [b]buy cards[/b] from the market, then collect [b]income[/b], then the climate advances by net emissions × 0.002°.

Dirty income pays now and emits forever. New acts (2038, 2044) unlock deeper cards. Some cards form hidden combos.

[i]Hover anything on screen for a description — full rules any time under the [b]?[/b] button.[/i] Good luck, Director."""
	overlay_btn.text = "Take office ▶"
	_reset_overlay_button(func():
		overlay.visible = false
		_show_era_screen(Game.state().era_for_year(Game.state().year).id))
	overlay.visible = true


func _show_help() -> void:
	overlay_text.text = "[b]The Drawdown Protocol — rules[/b]\n\n" + _rules_text()
	overlay_btn.text = "Back"
	_reset_overlay_button(func(): overlay.visible = false)
	overlay.visible = true


func _reset_overlay_button(action: Callable) -> void:
	for conn in overlay_btn.pressed.get_connections():
		overlay_btn.pressed.disconnect(conn.callable)
	overlay_btn.pressed.connect(action)
