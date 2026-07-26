extends Node
## Main: boots the sim and views, routes input, owns the turn-flow modes.
## Views subscribe to sim signals and render state; all gameplay mutation goes
## through RunState (docs/Phase_3/03 architecture).

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

var _mode := Mode.PLAY
var _selected_region: StringName = &""
var _targeting_card: StringName = &""
var _pass_armed := false
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
	end_screen = RunEndScreen.new()
	modal_layer.add_child(end_screen)
	end_screen.new_timeline.connect(func() -> void: _start_run(_random_seed()))
	end_screen.retry_same_seed.connect(func() -> void: _start_run(sim.current_seed))
	end_screen.open_hub.connect(func() -> void:
		if not hub.visible:
			_toggle_hub())

	var debug_layer := CanvasLayer.new()
	debug_layer.name = "DebugLayer"
	debug_layer.layer = 4
	add_child(debug_layer)
	debug_overlay = DebugOverlay.new()
	debug_layer.add_child(debug_overlay)
	debug_overlay.restart_requested.connect(_start_run)
	debug_overlay.autoplay_requested.connect(_on_autoplay)
	debug_overlay.advance10_requested.connect(_on_advance10)

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


func _start_run(seed_value: int) -> void:
	sim.start_run(seed_value, Meta.unlocked.duplicate())
	Meta.last_seed = seed_value
	Meta.save_state()
	var rs := sim.run_state
	rs.card_played.connect(_on_card_played)
	rs.year_advanced.connect(_on_year_advanced)
	rs.event_struck.connect(_on_event_struck)
	rs.warming_band_changed.connect(_on_band_changed)
	rs.ally_changed.connect(_on_ally_changed)
	rs.run_ended.connect(_on_run_ended)

	board.bind_world(rs)
	tray.build(rs.catalog)
	tray.refresh(rs)
	top_bar.refresh(rs)
	dock.clear_log()
	dock.clear_region()
	banners.skip_all()
	vignette.set_band(rs.warming_band())
	end_screen.visible = false
	hub.visible = false
	debug_overlay.bind(sim)
	debug_overlay.refresh()
	_mode = Mode.PLAY
	_pass_armed = false
	_selected_region = &""
	_targeting_card = &""
	board.set_selection(&"")
	board.set_target_highlights([])
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
		if _mode != Mode.TARGETING:
			_toggle_hub()
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
	if sim.run_state == null or hub.visible:
		return
	match _mode:
		Mode.ENDED, Mode.TARGETING:
			return
		Mode.PLAY:
			banners.skip_all()  # double-Space skips the beat replay
			var rs := sim.run_state
			if not rs.action_taken and not _pass_armed:
				_pass_armed = true
				_update_prompt()
				return
			_pass_armed = false
			rs.resolve_year()
			_update_prompt()


func _on_card_chosen(card_id: StringName) -> void:
	if _mode != Mode.PLAY or hub.visible or sim.run_state == null:
		return
	var rs := sim.run_state
	var reason := rs.can_play_reason(card_id)
	if reason != &"ok":
		top_bar.set_prompt("Cannot enact: " + _reason_text(reason))
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
	if _mode != Mode.PLAY or hub.visible or sim.run_state == null:
		return
	if sim.run_state.action_taken:
		return
	banners.skip_all()
	sim.run_state.resolve_year()
	_pass_armed = false
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
		hub.open(sim.base_catalog)
		tutorial.notify(&"hub_opened")
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

func _on_card_played(card_id: StringName, accepted: bool) -> void:
	var rs := sim.run_state
	if accepted:
		_pass_armed = false
		top_bar.refresh(rs)
		tray.refresh(rs)
		board.refresh(rs)
		if _selected_region != &"":
			dock.show_region(rs, _selected_region)
		debug_overlay.refresh()
		tutorial.notify(&"card_played")
	else:
		top_bar.set_prompt("Cannot enact: " + _reason_text(rs.can_play_reason(card_id)))
		return
	_update_prompt()


func _on_year_advanced(rec: TurnRecord) -> void:
	var rs := sim.run_state
	top_bar.refresh(rs)
	tray.refresh(rs)
	board.refresh(rs)
	dock.append_log(rec.year, rec.log_lines)
	if _selected_region != &"":
		dock.show_region(rs, _selected_region)
	if not _suppress_banners:
		for ev in rec.events:
			var hit_line := rs._event_hit_line(ev)
			banners.push("damage", hit_line)
			if ev["opportunity"] != &"":
				banners.push("opportunity", LogFormatter.render("events", String(ev["id"]) + "_opp"))
		for fb in rec.feedbacks:
			banners.push("interstitial", LogFormatter.render("events", String(fb) + "_hit"))
	debug_overlay.refresh()
	tutorial.notify(&"year_advanced")
	_update_prompt()


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


func _on_run_ended(_outcome: StringName, kp: int) -> void:
	var rs := sim.run_state
	Meta.award_kp(kp)
	var rec: TurnRecord = rs.records.back()
	top_bar.refresh(rs)
	tray.refresh(rs)
	board.refresh(rs)
	dock.append_log(rec.year, rec.log_lines)
	banners.skip_all()
	tutorial.close_silent()  # not a dismissal: an unfinished tour may reopen
	end_screen.show_outcome(rs)
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


func _on_advance10() -> void:
	if _mode == Mode.ENDED:
		return
	_suppress_banners = true
	sim.advance_years_passing(10)
	_suppress_banners = false


# ----------------------------------------------------------------- helpers ---

func _reason_text(reason: StringName) -> String:
	match reason:
		&"no_money": return "not enough money"
		&"no_influence": return "not enough influence"
		&"locked_allies": return "needs more allies"
		&"capped": return "sector at its cap - play a sufficiency policy"
		&"media_active": return "already active"
		&"no_target": return "no neutral nation left"
		&"action_taken": return "one policy per year - Space to resolve"
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
			if _pass_armed:
				top_bar.set_prompt("Resolve without acting? Space again to confirm")
			elif sim.run_state.action_taken:
				top_bar.set_prompt("Space - resolve the year")
			else:
				top_bar.set_prompt("Pick one policy for %d, then Space  |  H knowledge  F3 debug" % sim.run_state.year)
