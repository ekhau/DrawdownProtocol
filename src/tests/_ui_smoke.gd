extends SceneTree
## Headless UI smoke: boots the real main scene and drives the full player
## flow through the same handlers the mouse/keyboard use. Scratch tool,
## removed from the suite list (kept for manual verification):
##   godot --headless --path src --script res://tests/_ui_smoke.gd


func _first_playable(main: Node) -> StringName:
	var rs: RunState = main.sim.run_state
	for id in rs.market:
		if rs.can_play_reason(id) == &"ok":
			var wants_ally := false
			for eff: Dictionary in rs.catalog.card(id).get("effects", []):
				if String(eff.get("op", "")) == "ally":
					wants_ally = true
			if not wants_ally:
				return id
	return &""


func _initialize() -> void:
	var errors := 0
	# The Meta autoload identifier is not compile-resolvable inside a MainLoop
	# script; fetch the node instead.
	var meta: Node = root.get_node_or_null("Meta")
	if meta == null:
		print("FAIL: Meta autoload missing")
		quit(1)
		return
	# Reset persisted meta so the smoke is repeatable.
	meta.kp_total = 0
	meta.unlocked = []
	meta.unlocked_cards = []
	meta.codex_seen = []
	meta.selected_archetype = ""
	meta.tutorial_done = false
	meta.save_state()
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready  # _ready is deferred to the first frame under --script

	# --- First boot: the city picker gates the first run. ---
	if main.sim.run_state != null:
		print("FAIL: run started before an archetype was chosen")
		errors += 1
	if not main.archetype_select.visible:
		print("FAIL: archetype picker not shown on a fresh profile")
		errors += 1
	main._on_archetype_chosen(&"port_city")
	if main.sim == null or main.sim.run_state == null:
		print("FAIL: run did not start after choosing a city")
		quit(1)
		return
	if meta.selected_archetype != "port_city":
		print("FAIL: archetype choice not persisted")
		errors += 1
	var rs: RunState = main.sim.run_state
	if rs.allies != 1:
		print("FAIL: Port City should start with one ally")
		errors += 1
	print("boot ok: seed %d, year %d, %d panels, %d market offers, %d crises" % [
		rs.run_seed, rs.year, main.board.panels.size(), rs.market.size(),
		rs.pending_crises.size()])
	if rs.pending_crises.size() != 3:
		print("FAIL: expected 3 pending crises at turn start")
		errors += 1
	if main.tray._chips.size() != rs.market.size():
		print("FAIL: tray chips do not mirror the market")
		errors += 1
	if main.tray._project_chips.size() != rs.catalog.projects.size():
		print("FAIL: project chips missing from the tray")
		errors += 1

	# --- Tutorial, part 1: auto-open, advance, close mid-way, flag persisted.
	if not main.tutorial.active:
		print("FAIL: tutorial did not auto-open on a fresh profile")
		errors += 1
	if main.tutorial.current_step_id() != &"welcome":
		print("FAIL: tutorial did not start at the first step")
		errors += 1
	for i in 4:  # welcome/pillars/warming/crises are informational Next steps
		main.tutorial.advance()
	if main.tutorial.current_step_id() != &"inspect":
		print("FAIL: expected the inspect step, got %s" % main.tutorial.current_step_id())
		errors += 1
	main._on_region_clicked(rs.world[4].id)  # the real action advances the step
	if main.tutorial.current_step_id() != &"cards":
		print("FAIL: region click did not advance the tutorial")
		errors += 1
	main._toggle_tutorial()  # close mid-way
	if main.tutorial.active:
		print("FAIL: tutorial did not close")
		errors += 1
	if not meta.tutorial_done:
		print("FAIL: dismissal flag not set")
		errors += 1
	print("tutorial part 1 ok: auto-open, advance, real-action step, mid-way close persisted")

	# 1. Fund market offers through the tray handler, same turn.
	rs.money = 800.0
	var first := _first_playable(main)
	if first == &"":
		print("FAIL: no playable market offer")
		errors += 1
	else:
		main._on_card_chosen(first)
		if rs.cards_played_this_turn() != 1:
			print("FAIL: market offer was not funded")
			errors += 1
		if rs.market.has(first):
			print("FAIL: funded offer still in the market")
			errors += 1
		if not meta.codex_seen.has(String(first)):
			print("FAIL: first play did not unlock the codex entry")
			errors += 1
	var second := _first_playable(main)
	if second != &"":
		main._on_card_chosen(second)
		if rs.cards_played_this_turn() != 2:
			print("FAIL: second offer of the turn was not accepted (multi-play)")
			errors += 1
	# 2. Space resolves the turn (5 years).
	main._on_advance_pressed()
	if rs.year != 2035:
		print("FAIL: turn did not advance to 2035 (year=%d)" % rs.year)
		errors += 1
	# 3. Pass flow needs the explicit double-Space confirm.
	main._on_advance_pressed()
	if rs.year != 2035 or not main._pass_armed:
		print("FAIL: pass confirm not armed")
		errors += 1
	main._on_advance_pressed()
	if rs.year != 2040:
		print("FAIL: pass did not resolve after confirm")
		errors += 1
	# 4. DIP1 targeting flow: force the offer, click a neutral region.
	rs.money = 500.0
	rs.influence = 50.0
	rs.force_market(["DIP1"])
	main.tray.build(rs)
	main.tray.refresh(rs)
	main._on_card_chosen(&"DIP1")
	if main._mode != main.Mode.TARGETING:
		print("FAIL: DIP1 did not open targeting")
		errors += 1
	var target: RegionData = rs.neutral_regions()[2]
	main._on_region_clicked(target.id)
	if rs.allies != 2 or target.ally_state != WorldEnums.AllyState.ALLY:
		print("FAIL: targeting click did not form the alliance")
		errors += 1
	if main._mode != main.Mode.PLAY:
		print("FAIL: targeting mode not exited")
		errors += 1
	# 5. Project launch through the tray handler.
	main._on_project_chosen(&"global_sink_trust")
	if rs.active_projects.size() != 1:
		print("FAIL: project did not launch")
		errors += 1
	# 6. Region selection fills the inspector.
	main._on_region_clicked(rs.world[0].id)
	if main._selected_region != rs.world[0].id:
		print("FAIL: region selection")
		errors += 1
	# 7. Hub and codex toggle (mutually exclusive modals).
	main._toggle_hub()
	if not main.hub.visible:
		print("FAIL: hub did not open")
		errors += 1
	main._toggle_codex()
	if main.hub.visible or not main.codex.visible:
		print("FAIL: codex did not replace the hub")
		errors += 1
	main._toggle_codex()
	# 8. Autoplay to the end through the debug hook; end screen must show.
	main._on_autoplay(&"safe")
	if rs.phase != RunState.Phase.ENDED:
		print("FAIL: autoplay did not finish the run")
		errors += 1
	if not main.end_screen.visible:
		print("FAIL: end screen not shown")
		errors += 1
	var last: TurnRecord = rs.records.back()
	print("run end: %s in %d, %d KP (meta total %d)" % [last.end_status, last.year, last.kp_awarded, meta.kp_total])
	if meta.kp_total <= 0:
		print("FAIL: KP not awarded to meta state")
		errors += 1
	var pm: Dictionary = PostMortem.analyze(rs.records, rs.catalog)
	if pm.is_empty() or String(pm.get("headline", "")).is_empty():
		print("FAIL: post-mortem missing at run end")
		errors += 1
	else:
		print("post-mortem: " + String(pm["headline"]))
	# 9. New timeline from the end screen.
	var old_seed: int = main.sim.current_seed
	main.end_screen.new_timeline.emit()
	rs = main.sim.run_state
	if rs.phase == RunState.Phase.ENDED or rs.year != 2030:
		print("FAIL: new timeline did not restart")
		errors += 1
	if String(rs.archetype.get("id", "")) != "port_city":
		print("FAIL: archetype not carried into the new timeline")
		errors += 1
	print("restarted: old seed %d -> new seed %d" % [old_seed, main.sim.current_seed])
	# 10. Knowledge unlock via hub applies to the NEXT run.
	meta.kp_total = 20
	var node: Dictionary = main.sim.base_catalog.knowledge_by_id["affordable_evs"]
	if not meta.unlock(node):
		print("FAIL: could not unlock knowledge node")
		errors += 1
	main._start_run(12345)
	if float(main.sim.run_state.catalog.card(&"TRA2")["cost_money"]) != 84.0:
		print("FAIL: knowledge patch not applied to new run")
		errors += 1

	# --- Tutorial, part 2: no auto-reshow, re-open via toggle, complete fully.
	rs = main.sim.run_state
	rs.money = 2000.0
	if main.tutorial.active:
		print("FAIL: tutorial auto-reshown despite the persisted flag")
		errors += 1
	main._toggle_tutorial()  # the "?" button and F1 route here
	if not main.tutorial.active:
		print("FAIL: tutorial did not re-open")
		errors += 1
	# Regression guard for the 0-size layer bug: the overlay must span the view.
	if main.tutorial.size.x < 100.0 or main.tutorial.size.y < 100.0:
		print("FAIL: tutorial layer has no size (%s) - anchor layout broken" % main.tutorial.size)
		errors += 1
	var visited := 0
	var guard := 40
	while main.tutorial.active and guard > 0:
		guard -= 1
		visited += 1
		# Let _place_panel's awaited layout frame resolve, then assert the
		# explainer panel is fully inside the viewport at EVERY step.
		await process_frame
		await process_frame
		var prect := Rect2(main.tutorial._panel.position, main.tutorial._panel.size)
		var vrect := Rect2(Vector2.ZERO, main.tutorial.size)
		if not vrect.encloses(prect):
			print("FAIL: step %s panel %s outside viewport %s" % [
				main.tutorial.current_step_id(), prect, vrect])
			errors += 1
		var step: Dictionary = main.tutorial.steps[main.tutorial.index]
		var advance: Dictionary = step.get("advance", {})
		if String(advance.get("type", "")) == "next":
			main.tutorial.advance()
		else:
			match StringName(String(advance.get("signal", ""))):
				&"region_selected":
					main._on_region_clicked(main.sim.run_state.world[1].id)
				&"card_played":
					var pick := _first_playable(main)
					if pick == &"":
						main.sim.run_state.force_market(["RSP4"])
						main.tray.build(main.sim.run_state)
						pick = &"RSP4"
					main._on_card_chosen(pick)
				&"project_started":
					main._on_project_chosen(&"global_sink_trust")
				&"year_advanced":
					main._on_advance_pressed()
				&"hub_opened":
					main._toggle_hub()
				_:
					print("FAIL: smoke cannot drive signal %s" % advance.get("signal", "?"))
					errors += 1
					break
	if main.tutorial.active:
		print("FAIL: tutorial did not complete (visited %d steps)" % visited)
		errors += 1
	if visited != main.tutorial.steps.size():
		print("FAIL: visited %d of %d steps" % [visited, main.tutorial.steps.size()])
		errors += 1
	if not meta.tutorial_done:
		print("FAIL: completion flag lost")
		errors += 1
	if main.hub.visible:
		main._toggle_hub()  # tidy up after the hub step
	print("tutorial part 2 ok: no auto-reshow, re-opened, completed all %d steps" % visited)

	if errors == 0:
		print("UI SMOKE PASSED")
	quit(1 if errors > 0 else 0)
