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
	print("boot ok: seed %d, year %d, %d panels, %d chips" % [
		rs.run_seed, rs.year, main.board.panels.size(), main.tray._chips.size()])

	# 1. Enact a card through the tray handler.
	main._on_card_chosen(&"SOC1")
	if not rs.media:
		print("FAIL: SOC1 not applied")
		errors += 1
	# 2. Second card must be refused (one-policy lock, UI trusts model verdict).
	main._on_card_chosen(&"IND1")
	if rs._pending_action.get("action", &"") != &"SOC1":
		print("FAIL: second card was not rejected")
		errors += 1
	# 3. Space resolves the year.
	main._on_advance_pressed()
	if rs.year != 2031:
		print("FAIL: year did not advance (year=%d)" % rs.year)
		errors += 1
	# 4. Pass flow needs the explicit double-Space confirm.
	main._on_advance_pressed()
	if rs.year != 2031 or not main._pass_armed:
		print("FAIL: pass confirm not armed")
		errors += 1
	main._on_advance_pressed()
	if rs.year != 2032:
		print("FAIL: pass did not resolve after confirm")
		errors += 1
	# 5. DIP1 targeting flow: highlight, click a neutral region, ally formed.
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

	if errors == 0:
		print("UI SMOKE PASSED")
	quit(1 if errors > 0 else 0)
