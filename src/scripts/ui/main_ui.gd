extends Control
## The whole MVP interface, built in code (placeholder art = styleboxes and text).
## RULE: this script contains zero game logic. It calls the five Game verbs and
## repaints from signals. If you find yourself computing a rule here — stop.

var thermometer: ProgressBar
var thermo_label: Label
var year_label: Label
var money_label: Label
var support_label: Label
var absorption_label: Label
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


func _ready() -> void:
	_build_layout()
	Game.run_started.connect(_on_run_started)
	Game.resources_changed.connect(_refresh_stats)
	Game.sector_changed.connect(func(_id): _refresh_sectors())
	Game.temperature_changed.connect(func(_t): _refresh_stats())
	Game.phase_changed.connect(_on_phase_changed)
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
	year_label = _label(top, "2030", 26)
	var thermo_box := VBoxContainer.new()
	thermo_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(thermo_box)
	thermo_label = _label(thermo_box, "+1.50°", 30)
	thermo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thermometer = ProgressBar.new()
	thermometer.min_value = 1.5
	thermometer.max_value = 2.0
	thermometer.step = 0.001
	thermometer.show_percentage = false
	thermometer.custom_minimum_size = Vector2(0, 22)
	thermo_box.add_child(thermometer)
	money_label = _label(top, "$10", 26)
	support_label = _label(top, "Support 10", 26)
	absorption_label = _label(top, "Absorb 3", 26)
	net_label = _label(top, "Net 20", 26)
	var help_btn := Button.new()
	help_btn.text = "?"
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


func _refresh_stats() -> void:
	var s: RunState = Game.state()
	if s == null:
		return
	year_label.text = str(s.year)
	thermo_label.text = "+%.2f°" % s.temp
	var tween := create_tween()
	tween.tween_property(thermometer, "value", s.temp, 0.4)
	var heat := clampf((s.temp - 1.5) / 0.5, 0.0, 1.0)
	thermometer.modulate = Color(1.0, 1.0 - heat * 0.7, 1.0 - heat)
	money_label.text = "$%d" % s.money
	support_label.text = "Support %d/%d" % [s.support, int(Game.catalog.config.support_cap)]
	absorption_label.text = "Absorb %d" % s.absorption
	net_label.text = "Net %d" % s.net_emissions()
	_refresh_market()


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
	_refresh_stats()


func _refresh_market() -> void:
	var s: RunState = Game.state()
	if s == null:
		return
	for child in market_box.get_children():
		child.queue_free()
	for card_id in Game.sim.market.offer:
		var card: Dictionary = Game.catalog.cards_by_id[card_id]
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 60)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var cost := "%d$" % int(card.cost_money)
		if int(card.cost_support) > 0:
			cost += " + %d support" % int(card.cost_support)
		b.text = "%s  (%s)\n%s" % [card.name, cost, Effects.describe(card.effects, Game.catalog)]
		b.disabled = s.phase != RunState.Phase.ACTION or not Game.sim.market.can_buy(card_id)
		b.pressed.connect(Game.buy_card.bind(card_id))
		market_box.add_child(b)
	reroll_btn.text = "Reroll (%d$)" % int(Game.catalog.config.reroll_cost)
	reroll_btn.disabled = s.phase != RunState.Phase.ACTION or not Game.sim.market.can_reroll()
	end_turn_btn.disabled = s.phase != RunState.Phase.ACTION


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
	var era: Dictionary = Game.state().era_for_year(Game.state().year)
	banner.text = "%s\n%s" % [era.name, era.banner]
	banner.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.5)
	tween.tween_interval(2.5)
	tween.tween_property(banner, "modulate:a", 0.0, 1.0)
	_refresh_sectors()  # palette crossfade: repaint under the new era's colormap


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


func _show_help() -> void:
	overlay_text.text = """[b]The Drawdown Protocol — rules[/b]

One turn = one year. Reach [b]net emissions ≤ 0[/b] before the thermometer hits [b]+2.0°[/b].
Support is your HP: at 0 the Institute is voted out.

Each year: face a [b]crisis[/b] (every answer costs something — money, support, or a permanent scar; costs rise with the thermometer), then [b]buy cards[/b] from the market, then collect [b]income[/b], then the [b]climate[/b] advances by net emissions × 0.002°.

Dirty income pays now and emits forever. New eras (2038, 2044) unlock deeper cards. Some cards form hidden combos."""
	overlay_btn.text = "Back"
	_reset_overlay_button(func(): overlay.visible = false)
	overlay.visible = true


func _reset_overlay_button(action: Callable) -> void:
	for conn in overlay_btn.pressed.get_connections():
		overlay_btn.pressed.disconnect(conn.callable)
	overlay_btn.pressed.connect(action)
