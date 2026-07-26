extends SceneTree
## Headless UI smoke: boots the real main scene and drives the full player
## flow through the same handlers the mouse/keyboard use. Scratch tool,
## removed from the suite list (kept for manual verification).


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
	meta.tutorial_done = false
	meta.save_state()
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready  # _ready is deferred to the first frame under --script

	if main.sim == null or main.sim.run_state == null:
		print("FAIL: run did not start")
		quit(1)
		return
	var rs: RunState = main.sim.run_state
	print("boot ok: seed %d, year %d, %d panels, %d chips, %d crises" % [
		rs.run_seed, rs.year, main.board.panels.size(), main.tray._chips.size(),
		rs.pending_crises.size()])
	if rs.pending_crises.size() != 3:
		print("FAIL: expected 3 pending crises at year start")
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
	if not FileAccess.get_file_as_string("user://knowledge_save.json").contains("\"tutorial_done\":true"):
		print("FAIL: tutorial_done not persisted to user://")
		errors += 1
	print("tutorial part 1 ok: auto-open, advance, real-action step, mid-way close persisted")

	# 1. Multi-play: several cards through the tray handler, same year.
	main._on_card_chosen(&"SOC1")
	if not rs.media:
		print("FAIL: SOC1 not applied")
		errors += 1
	main._on_card_chosen(&"RSP1")
	if rs.cards_played_this_turn() != 2:
		print("FAIL: second card of the year was not accepted (multi-play)")
		errors += 1
	# 2. Space resolves the year.
	main._on_advance_pressed()
	if rs.year != 2031:
		print("FAIL: year did not advance (year=%d)" % rs.year)
		errors += 1
	# 3. Pass flow needs the explicit double-Space confirm.
	main._on_advance_pressed()
	if rs.year != 2031 or not main._pass_armed:
		print("FAIL: pass confirm not armed")
		errors += 1
	main._on_advance_pressed()
	if rs.year != 2032:
		print("FAIL: pass did not resolve after confirm")
		errors += 1
	# 4. DIP1 targeting flow: highlight, click a neutral region, ally formed.
	rs.money = 500.0
	rs.influence = 50.0
	main.tray.refresh(rs)
	main._on_card_chosen(&"DIP1")
	if main._mode != main.Mode.TARGETING:
		print("FAIL: DIP1 did not open targeting")
		errors += 1
	var target: RegionData = rs.neutral_regions()[2]
	main._on_region_clicked(target.id)
	if rs.allies != 1 or target.ally_state != WorldEnums.AllyState.ALLY:
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
	# 7. Hub toggles.
	main._toggle_hub()
	if not main.hub.visible:
		print("FAIL: hub did not open")
		errors += 1
	main._toggle_hub()
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
	# 9. New timeline from the end screen.
	var old_seed: int = main.sim.current_seed
	main.end_screen.new_timeline.emit()
	rs = main.sim.run_state
	if rs.phase == RunState.Phase.ENDED or rs.year != 2030:
		print("FAIL: new timeline did not restart")
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
					main._on_region_clicked(rs.world[1].id)
				&"card_played":
					main._on_card_chosen(&"SOC1")
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
