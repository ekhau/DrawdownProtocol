extends Node
## Main: boots the sim and views, routes input, owns the turn-flow modes.
## Views subscribe to sim signals and render state; all gameplay mutation goes
## through RunState (docs/Phase_3/03 architecture). First boot opens the city
## picker; afterwards the selected archetype persists in Meta.

enum Mode { PLAY, TARGETING, ENDED }

var sim: Sim
var board: BoardView
var top_bar: HudTopBar
var tray: CardTray
var dock: RightDock
var banners: BannerLayer
var vignette: Vignette
var hub: KnowledgeHub
var end_screen: RunEndScreen
var debug_overlay: DebugOverlay
var tutorial: TutorialLayer
var archetype_select: ArchetypeSelect
var codex: CodexScreen

var _mode := Mode.PLAY
var _selected_region: StringName = &""
var _targeting_card: StringName = &""
var _pass_armed := false
var _abandon_armed: StringName = &""
var _suppress_banners := false


func _ready() -> void:
	# Fail-loud boot validation (docs/Phase_5/05 error handling policy).
	var v := DataValidator.load_and_validate()
	if not v.ok():
		_show_validation_failure(v)
		return
	for w in v.warnings:
		print("data warning: " + w)
	_build_scene()
	if Meta.selected_archetype.is_empty():
		# First contact: choose your city before the first timeline.
		archetype_select.open(sim.base_catalog)
	else:
		_start_run(_random_seed())


func _show_validation_failure(v: DataValidator) -> void:
	push_error("Content validation failed - run refused to start.")
	print(v.report())
	var label := Label.new()
	label.text = "CONTENT VALIDATION FAILED - the run refuses to start.\n\n" + v.report()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)


func _build_scene() -> void:
	sim = Sim.new()
	sim.name = "Sim"
	add_child(sim)

	board = BoardView.new()
	board.name = "BoardView"
	add_child(board)
	board.region_clicked.connect(_on_region_clicked)

	var vignette_layer := CanvasLayer.new()
	vignette_layer.name = "VignetteLayer"
	vignette_layer.layer = 1
	add_child(vignette_layer)
	vignette = Vignette.new()
	vignette_layer.add_child(vignette)

	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HUD"
	hud_layer.layer = 2
	add_child(hud_layer)
	top_bar = HudTopBar.new()
	hud_layer.add_child(top_bar)
	dock = RightDock.new()
	hud_layer.add_child(dock)
	tray = CardTray.new()
	hud_layer.add_child(tray)
	tray.card_chosen.connect(_on_card_chosen)
	tray.project_chosen.connect(_on_project_chosen)
	tray.pass_chosen.connect(_on_pass_chosen)
	banners = BannerLayer.new()
	hud_layer.add_child(banners)

	var modal_layer := CanvasLayer.new()
	modal_layer.name = "ModalLayer"
	modal_layer.layer = 3
	add_child(modal_layer)
	hub = KnowledgeHub.new()
	modal_layer.add_child(hub)
	hub.closed.connect(_toggle_hub)
	codex = CodexScreen.new()
	modal_layer.add_child(codex)
	codex.closed.connect(_toggle_codex)
	end_screen = RunEndScreen.new()
	modal_layer.add_child(end_screen)
	end_screen.new_timeline.connect(func() -> void: _start_run(_random_seed()))
	end_screen.retry_same_seed.connect(func() -> void: _start_run(sim.current_seed))
	end_screen.open_hub.connect(func() -> void:
		if not hub.visible:
			_toggle_hub())
	end_screen.change_city.connect(func() -> void:
		archetype_select.open(sim.base_catalog))
	archetype_select = ArchetypeSelect.new()
	modal_layer.add_child(archetype_select)
	archetype_select.chosen.connect(_on_archetype_chosen)

	var debug_layer := CanvasLayer.new()
	debug_layer.name = "DebugLayer"
	debug_layer.layer = 4
	add_child(debug_layer)
	debug_overlay = DebugOverlay.new()
	debug_layer.add_child(debug_overlay)
	debug_overlay.restart_requested.connect(_start_run)
	debug_overlay.autoplay_requested.connect(_on_autoplay)
	debug_overlay.advance10_requested.connect(_on_advance3)

	var tutorial_layer := CanvasLayer.new()
	tutorial_layer.name = "TutorialLayer"
	tutorial_layer.layer = 5
	add_child(tutorial_layer)
	tutorial = TutorialLayer.new()
	tutorial.anchor_resolver = _tutorial_anchor
	tutorial.dismissed.connect(_on_tutorial_dismissed)
	tutorial_layer.add_child(tutorial)
	top_bar.help_button.pressed.connect(_toggle_tutorial)


func _random_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(100000, 999999)


func _on_archetype_chosen(archetype_id: StringName) -> void:
	Meta.selected_archetype = String(archetype_id)
	Meta.save_state()
	archetype_select.visible = false
	_start_run(_random_seed())


func _start_run(seed_value: int) -> void:
	sim.start_run(seed_value, Meta.unlocked.duplicate(), false,
		StringName(Meta.selected_archetype), Meta.unlocked_cards.duplicate())
	Meta.last_seed = seed_value
	Meta.save_state()
	var rs := sim.run_state
	rs.year_started.connect(_on_year_started)
	rs.card_played.connect(_on_card_played)
	rs.year_advanced.connect(_on_year_advanced)
	rs.event_struck.connect(_on_event_struck)
	rs.crisis_answered.connect(_on_crisis_answered)
	rs.combo_triggered.connect(_on_combo_triggered)
	rs.card_unlocked.connect(_on_card_unlocked)
	rs.project_changed.connect(_on_project_changed)
	rs.warming_band_changed.connect(_on_band_changed)
	rs.ally_changed.connect(_on_ally_changed)
	rs.summit_resolved.connect(_on_summit_resolved)
	rs.risk_resolved.connect(_on_risk_resolved)
	rs.curve_bent.connect(_on_curve_bent)
	rs.run_ended.connect(_on_run_ended)

	board.bind_world(rs)
	tray.build(rs)
	tray.refresh(rs)
	top_bar.refresh(rs)
	dock.clear_log()
	dock.clear_region()
	dock.show_crises(rs)
	dock.show_world(rs)
	banners.skip_all()
	vignette.set_band(rs.warming_band())
	end_screen.visible = false
	hub.visible = false
	codex.visible = false
	archetype_select.visible = false
	debug_overlay.bind(sim)
	debug_overlay.refresh()
	_mode = Mode.PLAY
	_pass_armed = false
	_selected_region = &""
	_targeting_card = &""
	board.set_selection(&"")
	board.set_target_highlights([])
	if not rs.archetype.is_empty():
		banners.push("hope", "You lead the %s - %s" % [
			String(rs.archetype.get("name", "")), String(rs.archetype.get("tagline", ""))])
	if Meta.unlocked.size() > 0:
		var names: PackedStringArray = []
		for id in Meta.unlocked:
			var node: Dictionary = sim.base_catalog.knowledge_by_id.get(String(id), {})
			names.append(String(node.get("name", id)))
		banners.push("hope", "Knowledge carried into this timeline: " + ", ".join(names))
	# First contact: teach through play unless already completed or dismissed.
	if not Meta.tutorial_done and tutorial != null and not tutorial.active:
		tutorial.open()
	_update_prompt()


# ------------------------------------------------------------------ input ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("advance_year"):
		_on_advance_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_hub"):
		if _mode != Mode.TARGETING and not archetype_select.visible:
			_toggle_hub()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_codex"):
		if _mode != Mode.TARGETING and not archetype_select.visible:
			_toggle_codex()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_debug"):
		debug_overlay.visible = not debug_overlay.visible
		debug_overlay.refresh()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_tutorial"):
		if _mode != Mode.TARGETING:
			_toggle_tutorial()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("clear_selection"):
		if _mode == Mode.TARGETING:
			_cancel_targeting()
		elif _selected_region != &"":
			_selected_region = &""
			board.set_selection(&"")
			dock.clear_region()
		get_viewport().set_input_as_handled()


func _on_advance_pressed() -> void:
	if sim.run_state == null or hub.visible or codex.visible or archetype_select.visible:
		return
	match _mode:
		Mode.ENDED, Mode.TARGETING:
			return
		Mode.PLAY:
			banners.skip_all()  # double-Space skips the beat replay
			var rs := sim.run_state
			if rs.cards_played_this_turn() == 0 and not _pass_armed:
				_pass_armed = true
				_update_prompt()
				return
			_pass_armed = false
			rs.resolve_year()
			_update_prompt()


func _on_card_chosen(card_id: StringName) -> void:
	if _mode != Mode.PLAY or hub.visible or codex.visible or sim.run_state == null:
		return
	var rs := sim.run_state
	var reason := rs.can_play_reason(card_id)
	if reason != &"ok":
		top_bar.set_prompt("Cannot fund: " + _reason_text(reason))
		return
	# DIP1 targeting flow: the one modal in the interaction layer.
	var wants_ally := false
	for eff: Dictionary in rs.catalog.card(card_id).get("effects", []):
		if String(eff.get("op", "")) == "ally":
			wants_ally = true
	if wants_ally:
		_mode = Mode.TARGETING
		_targeting_card = card_id
		var ids: Array = []
		for r in rs.neutral_regions():
			ids.append(r.id)
		board.set_target_highlights(ids)
		top_bar.set_prompt("Choose a partner nation - click a highlighted region (Esc cancels, no cost)")
		return
	rs.play_card(card_id)


func _on_pass_chosen() -> void:
	if _mode != Mode.PLAY or hub.visible or codex.visible or sim.run_state == null:
		return
	banners.skip_all()
	sim.run_state.resolve_year()
	_pass_armed = false
	_update_prompt()


func _on_project_chosen(project_id: StringName) -> void:
	if _mode != Mode.PLAY or hub.visible or codex.visible or sim.run_state == null:
		return
	var rs := sim.run_state
	var is_active := false
	for ps in rs.active_projects:
		if ps.id == project_id:
			is_active = true
	if is_active:
		# Two-click abandon confirm (commitment must never break by accident).
		if _abandon_armed == project_id:
			_abandon_armed = &""
			rs.abandon_project(project_id)
		else:
			_abandon_armed = project_id
			top_bar.set_prompt("Abandon %s? Click it again to confirm (costs trust)"
				% rs.catalog.project(project_id).get("name", String(project_id)))
		return
	_abandon_armed = &""
	var reason := rs.can_start_project_reason(project_id)
	if reason != &"ok":
		top_bar.set_prompt("Cannot launch: " + _reason_text(reason))
		return
	rs.start_project(project_id)
	tray.refresh(rs)
	top_bar.refresh(rs)
	tutorial.notify(&"project_started")
	_update_prompt()


func _on_region_clicked(region_id: StringName) -> void:
	if sim.run_state == null:
		return
	if _mode == Mode.TARGETING:
		var region := sim.run_state.region_by_id(region_id)
		if region != null and region.ally_state == WorldEnums.AllyState.NEUTRAL:
			var card := _targeting_card
			_cancel_targeting()
			sim.run_state.play_card(card, region_id)
		return
	_selected_region = region_id
	board.set_selection(region_id)
	dock.show_region(sim.run_state, region_id)
	tutorial.notify(&"region_selected")


func _cancel_targeting() -> void:
	_mode = Mode.PLAY
	_targeting_card = &""
	board.set_target_highlights([])
	_update_prompt()


func _toggle_hub() -> void:
	if hub.visible:
		hub.visible = false
	else:
		codex.visible = false
		hub.open(sim.base_catalog)
		tutorial.notify(&"hub_opened")
	_update_prompt()


func _toggle_codex() -> void:
	if codex.visible:
		codex.visible = false
	else:
		hub.visible = false
		codex.open(sim.base_catalog)
	_update_prompt()


func _toggle_tutorial() -> void:
	if tutorial.active:
		tutorial.dismiss(false)
	else:
		tutorial.open()


func _on_tutorial_dismissed(_completed: bool) -> void:
	# Completed or dismissed: never auto-reshow (re-open via "?" or F1).
	Meta.tutorial_done = true
	Meta.save_state()


## Resolves tutorial spotlight anchors to global rects (view geometry only).
func _tutorial_anchor(target: StringName) -> Rect2:
	match target:
		&"top_bar":
			return top_bar.get_global_rect()
		&"warming_gauge":
			return top_bar.gauge.get_global_rect()
		&"carbon_label":
			return top_bar.carbon_label.get_global_rect()
		&"card_tray":
			return tray.get_global_rect()
		&"crisis_bar":
			return dock.crisis_rect()
		&"project_column":
			return tray.project_column_rect()
		&"log_dock":
			return dock.get_global_rect()
		&"prompt":
			return top_bar.prompt_label.get_global_rect().grow(12.0)
		&"help_button":
			return top_bar.help_button.get_global_rect()
		&"board":
			return board.board_rect()
		&"region_home":
			if sim.run_state != null:
				for r in sim.run_state.world:
					if r.is_player_home and board.panels.has(r.id):
						return board.panels[r.id].get_global_rect()
	return Rect2()


# -------------------------------------------------------------- sim events ---

func _on_year_started(_year: int) -> void:
	# A new turn: fresh market, fresh events, the world has drifted.
	var rs := sim.run_state
	tray.build(rs)
	tray.refresh(rs)
	top_bar.refresh(rs)
	dock.show_crises(rs)
	dock.show_world(rs)
	if not _suppress_banners:
		for cid in rs.market_bonus:
			banners.push("opportunity", LogFormatter.render("system", "bonus_card", {
				"name": rs.catalog.card(cid).get("name", String(cid)),
			}))
		var summit := rs.catalog.summit_for_turn(rs.turn_index())
		if not summit.is_empty():
			var goal: Dictionary = summit.get("goal", {})
			banners.push("interstitial", "SUMMIT THIS TURN - %s: end the turn with net <= %.0f or the world loses faith." % [
				String(summit["name"]), float(goal.get("lte", 0))])


func _on_card_played(card_id: StringName, accepted: bool) -> void:
	var rs := sim.run_state
	if accepted:
		_pass_armed = false
		if Meta.mark_codex_seen(String(card_id)) and not _suppress_banners:
			var codex_entry: Dictionary = rs.catalog.card(card_id).get("codex", {})
			if not codex_entry.is_empty():
				banners.push("hope", "CODEX - %s (press C to read the real-world solution)"
					% String(codex_entry.get("title", "")))
		top_bar.refresh(rs)
		tray.refresh(rs)
		board.refresh(rs)
		dock.show_crises(rs)
		dock.show_world(rs)
		if _selected_region != &"":
			dock.show_region(rs, _selected_region)
		debug_overlay.refresh()
		tutorial.notify(&"card_played")
	else:
		top_bar.set_prompt("Cannot fund: " + _reason_text(rs.can_play_reason(card_id)))
		return
	_update_prompt()


func _on_year_advanced(rec: TurnRecord) -> void:
	var rs := sim.run_state
	top_bar.refresh(rs)
	tray.refresh(rs)
	board.refresh(rs)
	dock.append_log(rec.year, rec.log_lines)
	dock.show_crises(rs)
	dock.show_world(rs)
	if _selected_region != &"":
		dock.show_region(rs, _selected_region)
	if not _suppress_banners:
		for crisis in rec.crises:
			if crisis["answered"] or crisis["kind"] == "opportunity":
				continue  # answered beats already played at answer time
			banners.push("damage", rs._crisis_hit_line(crisis))
			if crisis.get("opportunity", &"") != &"":
				banners.push("opportunity", LogFormatter.render("events", String(crisis["id"]) + "_opp"))
		if not rec.summit.is_empty():
			var key := "summit_met" if bool(rec.summit["met"]) else "summit_missed"
			banners.push("hope" if bool(rec.summit["met"]) else "damage",
				LogFormatter.render("system", key, {
					"name": rec.summit["name"], "value": "%+.0f" % float(rec.summit["value"]),
					"target": float(rec.summit["target"]),
					"gains": "", "penalty_note": "",
				}))
		for fb in rec.feedbacks:
			banners.push("interstitial", LogFormatter.render("events", String(fb) + "_hit"))
	debug_overlay.refresh()
	tutorial.notify(&"year_advanced")
	_update_prompt()


func _on_crisis_answered(crisis_id: StringName, _card_id: StringName) -> void:
	var rs := sim.run_state
	dock.show_crises(rs)
	if not _suppress_banners:
		banners.push("opportunity", rs.crisis_answered_line(crisis_id))


func _on_combo_triggered(_combo_id: StringName, _chain: int, _mult: float) -> void:
	var rs := sim.run_state
	if _suppress_banners or rs.turn_combos().is_empty():
		return
	banners.push("combo", rs.combo_line(rs.turn_combos().back()))
	# The engine turn: multiple combos cascading the same turn get their beat.
	if rs.turn_combos().size() >= 2:
		banners.push("combo", "CASCADE x%d - the engine is running! Chain x%d multiplies every payout." % [
			rs.turn_combos().size(), rs.combo_chain])
		top_bar.gauge.flash_plunge()


func _on_summit_resolved(_summit_id: StringName, met: bool) -> void:
	if met:
		top_bar.gauge.flash_plunge()


func _on_risk_resolved(card_id: StringName, success: bool) -> void:
	if _suppress_banners:
		return
	var rs := sim.run_state
	var card := rs.catalog.card(card_id)
	var chance := roundi(float(card.get("risk", {}).get("chance", 0)) * 100.0)
	if success:
		banners.push("hope", LogFormatter.render("system", "risk_success", {
			"name": card.get("name", String(card_id)), "chance": chance, "gains": "",
		}))
	else:
		banners.push("damage", LogFormatter.render("system", "risk_failure", {
			"name": card.get("name", String(card_id)), "chance": chance,
		}))


func _on_curve_bent(_year: int) -> void:
	top_bar.gauge.flash_plunge()
	if not _suppress_banners:
		banners.push("hope", LogFormatter.render("system", "curve_bent"))


func _on_card_unlocked(card_id: StringName) -> void:
	var rs := sim.run_state
	tray.refresh(rs)
	if not _suppress_banners:
		banners.push("hope", LogFormatter.render("system", "card_unlocked", {
			"name": rs.catalog.card(card_id).get("name", String(card_id)),
		}))


func _on_project_changed(project_id: StringName, status: StringName) -> void:
	var rs := sim.run_state
	tray.refresh(rs)
	top_bar.refresh(rs)
	if _suppress_banners:
		return
	var pname: String = rs.catalog.project(project_id).get("name", String(project_id))
	match status:
		&"completed":
			banners.push("hope", "PROJECT COMPLETE: %s - its promise is now permanent." % pname)
		&"failed":
			banners.push("damage", "Project collapses unpaid: %s. Partners remember." % pname)
		&"abandoned":
			banners.push("damage", "Project abandoned: %s. Trust is spent." % pname)


func _on_event_struck(_event_id: StringName, region_id: StringName, opportunity: StringName) -> void:
	if region_id != &"" and not _suppress_banners:
		board.flash_event(region_id, opportunity)


func _on_band_changed(band: int) -> void:
	vignette.set_band(band)
	if _suppress_banners:
		return
	# The signal fires mid-resolve, before the record is appended, so the last
	# stored record still carries the previous band.
	var prev := 0
	if not sim.run_state.records.is_empty():
		prev = sim.run_state.records.back().band
	if band > prev:
		banners.push("interstitial", LogFormatter.render("system", "band_up_%d" % band))
	else:
		banners.push("hope", LogFormatter.render("system", "band_down_%d" % band))


func _on_ally_changed(_region_id: StringName, _is_ally: bool) -> void:
	board.refresh(sim.run_state)
	tray.refresh(sim.run_state)
	dock.show_world(sim.run_state)


func _on_run_ended(outcome: StringName, kp: int) -> void:
	var rs := sim.run_state
	Meta.award_kp(kp)
	# Defeat lessons: some cards exist only because a run was lost this way.
	var fresh := Meta.record_run_outcome(outcome, sim.base_catalog)
	var fresh_names: Array[String] = []
	for id in fresh:
		fresh_names.append(String(sim.base_catalog.card(StringName(id)).get("name", id)))
	var rec: TurnRecord = rs.records.back()
	top_bar.refresh(rs)
	tray.refresh(rs)
	board.refresh(rs)
	dock.append_log(rec.year, rec.log_lines)
	banners.skip_all()
	if outcome == &"WIN_NEUTRAL":
		top_bar.gauge.flash_plunge()
	tutorial.close_silent()  # not a dismissal: an unfinished tour may reopen
	end_screen.show_outcome(rs, fresh_names)
	debug_overlay.refresh()
	_mode = Mode.ENDED
	_update_prompt()


# ------------------------------------------------------------ debug hooks ---

func _on_autoplay(strategy: StringName) -> void:
	if _mode == Mode.ENDED:
		return
	_suppress_banners = true
	sim.autoplay_to_end(strategy)
	_suppress_banners = false


func _on_advance3() -> void:
	if _mode == Mode.ENDED:
		return
	_suppress_banners = true
	sim.advance_turns_passing(3)
	_suppress_banners = false


# ----------------------------------------------------------------- helpers ---

func _reason_text(reason: StringName) -> String:
	match reason:
		&"no_money": return "not enough money"
		&"no_influence": return "not enough influence"
		&"no_happiness": return "the public cannot bear another sacrifice"
		&"locked_allies": return "needs more allies"
		&"capped": return "sector at its cap - play a sufficiency policy"
		&"media_active": return "already active"
		&"no_target": return "no target left to move"
		&"not_in_market": return "not offered this turn"
		&"turn_limit": return "five cards a turn is the limit - Space to resolve"
		&"max_active": return "two projects at once is the limit"
		&"already_active": return "already under way"
		&"already_done": return "concluded this run"
		&"resolving": return "the turn is resolving"
		&"ended": return "the run is over"
	return String(reason)


func _update_prompt() -> void:
	if sim.run_state == null:
		return
	match _mode:
		Mode.ENDED:
			top_bar.set_prompt("The run has ended - choose your next timeline")
		Mode.TARGETING:
			top_bar.set_prompt("Choose a partner nation - click a highlighted region (Esc cancels)")
		Mode.PLAY:
			var rs := sim.run_state
			if _pass_armed:
				top_bar.set_prompt("Resolve without acting? Space again to confirm")
			else:
				var open_count := rs.unanswered_crises().size()
				top_bar.set_prompt("Turn %d/%d (%d) - %d/%d cards, %d crises open  |  Space resolves  H knowledge  C codex  F3 debug" % [
					rs.turn_index(), RunState.total_turns(), rs.year,
					rs.cards_played_this_turn(), int(Tuning.s("MAX_CARDS_PER_TURN")), open_count])
