extends Control
## The whole MVP interface, built in code (placeholder art = styleboxes and text).
## RULE: this script contains zero game logic. It calls the five Game verbs and
## repaints from signals. If you find yourself computing a rule here — stop.

var thermometer: ProgressBar
var thermo_markers: Control         # overlay: needle, band ticks, ◆ projection
var thermo_caption: Label
var neutrality := {}                # cached Game.neutrality_projection() for draw
var thermo_label: Label
var year_label: Label
var act_label: Label
var money_label: Label
var support_label: Label
var net_label: Label
var emis_bar: Control            # gross-emissions gauge: green absorbed zone, needle, 2.0° line
var emis_caption: Label
var breakeven := 0               # cached Game.breakeven_gross() for draw
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
var intro_shown := false         # the launch intro plays once per session, not per run


func _ready() -> void:
	_build_layout()
	Game.run_started.connect(_on_run_started)
	Game.resources_changed.connect(_refresh_stats)
	Game.sector_changed.connect(func(_id): _refresh_sectors())
	Game.temperature_changed.connect(func(_t): _refresh_stats())
	Game.phase_changed.connect(_on_phase_changed)
	Game.market_changed.connect(_refresh_market)
	Game.combo_discovered.connect(_on_combo)
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
	var thermo_tip := "Global warming — the clock. Each year the planet warms by net emissions × 0.002°;\nat +2.0° the timeline fails. Pink lines: crisis cost bands.\n◆: where warming stops if you keep your recent pace of cuts."
	thermo_label = _label(thermo_box, "+1.50°", 30)
	thermo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip(thermo_label, thermo_tip)
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
	thermo_caption = _label(thermo_box, "", 13)
	thermo_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip(thermo_caption, "Where the mercury lands if the current pace of cuts holds\n(absorption frozen at today's value, era floors respected).")
	var emis_box := VBoxContainer.new()
	emis_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(emis_box)
	var emis_tip := "Global carbon — the engine. White needle: gross emissions.\nGreen zone: what your absorption soaks up — pull the needle inside it to win.\nPink 2.0° line: the highest emissions your current pace can walk back in time."
	net_label = _label(emis_box, "Net 20", 30)
	net_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip(net_label, "Net emissions = gross − absorption. This number heats the planet each year.\nReach net ≤ 0 (without one-year windfalls) to win.")
	emis_bar = Control.new()
	emis_bar.custom_minimum_size = Vector2(0, 22)
	emis_bar.draw.connect(_draw_emis_bar)
	emis_bar.resized.connect(emis_bar.queue_redraw)
	emis_box.add_child(emis_bar)
	_tip(emis_bar, emis_tip)
	emis_caption = _label(emis_box, "", 13)
	emis_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip(emis_caption, emis_tip)
	money_label = _label(top, "$10", 26)
	_tip(money_label, "Money funds cards and crisis responses.\nIncome arrives at each year's end — dirty sectors pay more, for now.")
	support_label = _label(top, "Support 10", 26)
	_tip(support_label, "Public support is your HP: at 0 the Institute is voted out.\nSpent by some cards and crisis choices — and it can never drop to 0 by your own purchase.")
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
	thermometer.modulate = Color(1.0, 1.0 - heat * 0.7, 1.0 - heat)
	neutrality = Game.neutrality_projection()
	if s.structural_net() <= 0:
		thermo_caption.text = "◆ net zero reached — end the year ▶"
		thermo_caption.add_theme_color_override("font_color", Color("#5ec962"))
	elif neutrality.reachable:
		thermo_caption.text = "◆ at this pace: net zero ≈ %d, at +%.2f°" % [neutrality.year, neutrality.temp]
		thermo_caption.add_theme_color_override("font_color", Color("#5ec962"))
	else:
		thermo_caption.text = "◆ at this pace the mercury hits +%.1f° first — cut faster" % thermometer.max_value
		thermo_caption.add_theme_color_override("font_color", Color("#fc8961"))
	thermo_markers.queue_redraw()
	money_label.text = "$%d" % s.money
	support_label.text = "Support %d/%d" % [s.support, int(Game.catalog.config.support_cap)]
	_refresh_emissions_gauge(s)
	_refresh_market()


func _refresh_emissions_gauge(s: RunState) -> void:
	breakeven = Game.breakeven_gross()
	var gross := s.gross_emissions()
	var net := s.net_emissions()
	net_label.text = "Net %d" % net
	var green := Color("#5ec962")
	var orange := Color("#fc8961")
	if s.structural_net() <= 0:
		net_label.add_theme_color_override("font_color", green)
		emis_caption.text = "all %d emissions absorbed — carbon neutral" % gross
		emis_caption.add_theme_color_override("font_color", green)
	elif gross <= breakeven:
		net_label.add_theme_color_override("font_color", Color.WHITE)
		emis_caption.text = "gross %d − absorbed %d = net %d · inside the 2.0° line" % [gross, s.absorption, net]
		emis_caption.add_theme_color_override("font_color", green)
	else:
		net_label.add_theme_color_override("font_color", Color.WHITE)
		emis_caption.text = "gross %d − absorbed %d = net %d · over the 2.0° line — cut faster" % [gross, s.absorption, net]
		emis_caption.add_theme_color_override("font_color", orange)
	emis_bar.queue_redraw()


func _draw_thermo_markers() -> void:
	var s: RunState = Game.state()
	if s == null or neutrality.is_empty():
		return
	var w := thermo_markers.size.x
	var h := thermo_markers.size.y
	# Scale ticks every 0.1°
	var v := thermometer.min_value + 0.1
	while v < thermometer.max_value - 0.001:
		var x := _thermo_x(v, w)
		thermo_markers.draw_line(Vector2(x, 0), Vector2(x, h), Color(1, 1, 1, 0.2), 1.0)
		v += 0.1
	# Band boundaries — crisis costs bump past these
	for band in Game.catalog.config.bands:
		if float(band.min_temp) > thermometer.min_value:
			var bx := _thermo_x(float(band.min_temp), w)
			thermo_markers.draw_line(Vector2(bx, 0), Vector2(bx, h), Color("#b73779", 0.8), 2.0)
	# ◆ where the mercury stops if the current pace holds
	var nx := clampf(_thermo_x(float(neutrality.temp), w), 7.0, w - 7.0)
	var ncolor := Color("#5ec962") if neutrality.reachable else Color("#fc8961")
	var cy := h / 2.0
	thermo_markers.draw_colored_polygon(PackedVector2Array([
		Vector2(nx, cy - 7), Vector2(nx + 7, cy), Vector2(nx, cy + 7), Vector2(nx - 7, cy)]), ncolor)
	# Needle: current warming
	var tx := clampf(_thermo_x(s.temp, w), 1.0, w - 1.0)
	thermo_markers.draw_line(Vector2(tx, 0), Vector2(tx, h), Color.WHITE, 2.0)
	thermo_markers.draw_colored_polygon(PackedVector2Array([
		Vector2(clampf(tx - 5, 0, w), 0), Vector2(clampf(tx + 5, 0, w), 0), Vector2(tx, 6)]), Color.WHITE)


func _draw_emis_bar() -> void:
	var s: RunState = Game.state()
	if s == null:
		return
	var w := emis_bar.size.x
	var h := emis_bar.size.y
	var gross := s.gross_emissions()
	var start_gross := 0
	for id in s.sectors:
		start_gross += int(s.sectors[id].start_emissions)
	# Stable scale: anchored to the run's starting gross so the bar doesn't
	# rescale under the player; widens only if something outgrows it.
	var scale_max := maxi(maxi(start_gross, gross), maxi(s.absorption, breakeven)) + 1
	emis_bar.draw_rect(Rect2(0, 0, w, h), Color(0.15, 0.15, 0.17))
	# Green zone: emissions the current absorption soaks up. Its right edge is
	# the win line — pull the needle inside to reach net zero.
	var ax := w * s.absorption / float(scale_max)
	emis_bar.draw_rect(Rect2(0, 0, ax, h), Color("#5ec962", 0.35))
	emis_bar.draw_line(Vector2(ax, 0), Vector2(ax, h), Color("#5ec962"), 2.0)
	# Scale ticks every 5 units
	var v := 5
	while v < scale_max:
		var x := w * v / float(scale_max)
		emis_bar.draw_line(Vector2(x, 0), Vector2(x, h), Color(1, 1, 1, 0.2), 1.0)
		v += 5
	# 2.0° line — same pink as the thermometer's band boundaries: emissions
	# above it can't be walked back before the mercury hits +2.0° at this pace.
	var bx := clampf(w * breakeven / float(scale_max), 2.0, w - 2.0)
	emis_bar.draw_line(Vector2(bx, 0), Vector2(bx, h), Color("#b73779"), 3.0)
	# Needle: current gross emissions (same visual language as the thermometer)
	var gx := clampf(w * gross / float(scale_max), 1.0, w - 1.0)
	emis_bar.draw_line(Vector2(gx, 0), Vector2(gx, h), Color.WHITE, 2.0)
	emis_bar.draw_colored_polygon(PackedVector2Array([
		Vector2(clampf(gx - 5, 0, w), 0), Vector2(clampf(gx + 5, 0, w), 0), Vector2(gx, 6)]), Color.WHITE)


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
		p.stats.text = "Emissions %d%s\nIncome %d$/turn" % [sector.emissions, floor_note, sector.income]
		p.panel.tooltip_text = "%s: emits %d/yr and pays %d$/yr.\nThis act can't cut it below %d — deeper cuts need later tech.\nPanel color tracks decarbonization: dark → the act's palette." % [
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
		reroll_btn.text = "Reroll (%d$)" % reroll_cost
		reroll_btn.tooltip_text = ("Need %d$ to reroll." % reroll_cost) if s.money < reroll_cost \
			else "Pay %d$ to deal a fresh market. Once per year." % reroll_cost
	reroll_btn.disabled = s.phase != RunState.Phase.ACTION or not Game.sim.market.can_reroll()
	end_turn_btn.disabled = s.phase != RunState.Phase.ACTION


func _card_button(card_id: String, s: RunState) -> Button:
	var card: Dictionary = Game.catalog.cards_by_id[card_id]
	var blockers: Dictionary = Game.sim.market.blockers(card_id)
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 84)
	b.disabled = s.phase != RunState.Phase.ACTION or not Game.sim.market.can_buy(card_id)
	b.pressed.connect(Game.buy_card.bind(card_id))
	b.tooltip_text = "Effects are immediate and permanent.\nBought cards leave the pool for the rest of the run."
	var cost := "%d$" % int(card.cost_money)
	if blockers.has("money"):
		cost = "[color=#ff5c5c]%s[/color]" % cost
	if int(card.cost_support) > 0:
		var sup := "%d support" % int(card.cost_support)
		if blockers.has("support") or blockers.has("support_floor"):
			sup = "[color=#ff5c5c]%s[/color]" % sup
		cost += " + " + sup
	var text := "[center]%s  (%s)\n%s" % [card.name, cost, Effects.describe(card.effects, Game.catalog)]
	if s.phase == RunState.Phase.ACTION and not blockers.is_empty():
		var why: PackedStringArray = []
		if blockers.has("money"):
			why.append("need %d$ more" % int(blockers.money))
		if blockers.has("support"):
			why.append("need %d more support" % int(blockers.support))
		if blockers.has("support_floor"):
			why.append("would drop support to 0")
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
	# Windfalls get the hopeful green accent — relief before reading a word.
	modal_style.border_color = Color("#5ec962") if is_windfall else Color("#b73779")
	modal_title.text = ("☀ " if is_windfall else "⚠ ") + crisis.name
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


func _on_combo(combo_id: String) -> void:
	for combo in Game.catalog.combos:
		if combo.id == combo_id:
			banner.text = "COMBO DISCOVERED — %s" % combo.name
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
	overlay_text.text = "%s\n\n[b]Timeline #%d[/b] — %d, +%.2f°\n%s\n\nCombos: %s\n\n[code]%s[/code]" % [
		verdict, result.seed % 1000, result.year, result.temp, result.cause,
		", ".join(result.combos) if result.combos.size() > 0 else "none discovered",
		curve]
	overlay_btn.text = "Run the next timeline ▶"
	_reset_overlay_button(func(): Game.new_run())
	overlay.visible = true


func _rules_text() -> String:
	return """One turn = one year. Reach [b]net emissions ≤ 0[/b] before the thermometer hits [b]+2.0°[/b].
Support is your HP: at 0 the Institute is voted out.

Each year: face a [b]crisis[/b] (every answer costs something — money, support, or a permanent scar; costs rise with the thermometer), then [b]buy cards[/b] from the market, then collect [b]income[/b], then the [b]climate[/b] advances by net emissions × 0.002°.

On the thermometer: the [b]white needle[/b] is today's warming, pink ticks are the crisis cost bands. The [b]◆[/b] projects where the mercury stops if you keep your recent pace of cuts (absorption frozen at today's value) — green means net zero is in reach, orange means +2.0° arrives first.

On the emissions gauge: the [b]green zone[/b] is what your absorption soaks up — pull the white needle (gross emissions) inside it to reach net zero. The [b]pink 2.0° line[/b] is the highest emissions your current pace of cuts can still walk back before the mercury hits +2.0°: needle left of it = winning course, right of it = cut faster. No cuts underway pins the line to the green edge.

Dirty income pays now and emits forever. New eras (2038, 2044) unlock deeper cards. Some cards form hidden combos."""


func _show_intro() -> void:
	overlay_text.text = """[center][b]THE DRAWDOWN PROTOCOL[/b][/center]

2030. After a decade of broken pledges, the world's governments hand the climate file to one office with real power: the [b]Drawdown Institute[/b]. You run it.

Your mandate: steer the whole economy — industry, transport, food, housing — to [b]net zero[/b] before the thermometer passes [b]+2.0°[/b]. Every year brings a crisis. Every fix costs money, public support, or a permanent scar. The public's patience is finite; the warming is not.

[b]How to play[/b]

One turn = one year. Reach [b]net emissions ≤ 0[/b] before the thermometer hits [b]+2.0°[/b]. Support is your HP: at 0 the Institute is voted out.

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
