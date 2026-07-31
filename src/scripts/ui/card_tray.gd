class_name CardTray
extends PanelContainer
## The Project Market: this turn's 3-5 offers (cards to fund), the long-term
## Projects column, and the explicit "End the turn" chip. Every offer states
## its full price, effects, tags and - for research bets - its printed odds;
## blocked offers state their reason (docs/Phase_5/03 state matrix). Bonus
## offers injected by events are visually marked: a crisis opened that door.

signal card_chosen(card_id: StringName)
signal project_chosen(project_id: StringName)
signal pass_chosen

var _chips: Dictionary = {}          # StringName -> Button (market offers)
var _project_chips: Dictionary = {}  # StringName -> Button
var _market_row: HBoxContainer
var _project_col: VBoxContainer
var _pass_chip: Button
var _rs: RunState


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("262b24")
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	add_theme_stylebox_override("panel", style)
	anchor_top = 1.0
	anchor_bottom = 1.0
	anchor_right = 1.0
	offset_top = -216
	offset_left = 0
	offset_right = 0
	offset_bottom = 0


## Rebuild for the CURRENT market; called at every turn start and unlock.
func build(rs: RunState) -> void:
	_rs = rs
	for child in get_children():
		child.queue_free()
	_chips.clear()
	_project_chips.clear()
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	add_child(columns)

	# The market: this turn's offers, in deal order.
	var market_col := VBoxContainer.new()
	market_col.add_theme_constant_override("separation", 3)
	market_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_col.size_flags_stretch_ratio = 3.0
	columns.add_child(market_col)
	var header := Label.new()
	header.text = "PROJECT MARKET - this turn's offers (funding one consumes it)"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color("9aa694"))
	market_col.add_child(header)
	_market_row = HBoxContainer.new()
	_market_row.add_theme_constant_override("separation", 8)
	market_col.add_child(_market_row)
	for id in rs.market:
		var card := rs.catalog.card(id)
		if card.is_empty():
			continue
		var chip := Button.new()
		chip.alignment = HORIZONTAL_ALIGNMENT_LEFT
		chip.add_theme_font_size_override("font_size", 11)
		chip.custom_minimum_size = Vector2(150, 150)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		chip.clip_text = true
		chip.focus_mode = Control.FOCUS_NONE  # Space must always mean "resolve"
		var cid := StringName(String(card["id"]))
		chip.pressed.connect(func() -> void: card_chosen.emit(cid))
		_market_row.add_child(chip)
		_chips[cid] = chip

	# Projects column: multi-turn commitments with per-turn upkeep.
	_project_col = VBoxContainer.new()
	_project_col.add_theme_constant_override("separation", 3)
	_project_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(_project_col)
	var proj_header := Label.new()
	proj_header.text = "Projects (3 turns)"
	proj_header.add_theme_font_size_override("font_size", 12)
	proj_header.add_theme_color_override("font_color", Color("e8d48a"))
	_project_col.add_child(proj_header)
	for project in rs.catalog.projects:
		var chip := Button.new()
		chip.alignment = HORIZONTAL_ALIGNMENT_LEFT
		chip.add_theme_font_size_override("font_size", 11)
		chip.custom_minimum_size = Vector2(0, 34)
		chip.focus_mode = Control.FOCUS_NONE
		var pid := StringName(String(project["id"]))
		chip.pressed.connect(func() -> void: project_chosen.emit(pid))
		_project_col.add_child(chip)
		_project_chips[pid] = chip

	# The explicit end-of-turn chip.
	var pass_col := VBoxContainer.new()
	pass_col.add_theme_constant_override("separation", 3)
	columns.add_child(pass_col)
	var pass_header := Label.new()
	pass_header.text = "Or"
	pass_header.add_theme_font_size_override("font_size", 12)
	pass_header.add_theme_color_override("font_color", Color("9aa694"))
	pass_col.add_child(pass_header)
	_pass_chip = Button.new()
	_pass_chip.text = "End the turn\n(bank funds)"
	_pass_chip.add_theme_font_size_override("font_size", 12)
	_pass_chip.custom_minimum_size = Vector2(110, 40)
	_pass_chip.focus_mode = Control.FOCUS_NONE
	_pass_chip.pressed.connect(func() -> void: pass_chosen.emit())
	pass_col.add_child(_pass_chip)


## Tutorial spotlight anchor for the Projects column.
func project_column_rect() -> Rect2:
	if _project_col == null:
		return Rect2()
	return _project_col.get_global_rect()


func refresh(rs: RunState) -> void:
	_rs = rs
	# Offers leave the market when funded: rebuild when the sets diverge.
	var stale := false
	for id in _chips:
		if not rs.market.has(id):
			stale = true
	if stale or _chips.size() != rs.market.size():
		build(rs)
	for id in _chips:
		var chip: Button = _chips[id]
		var card := rs.catalog.card(id)
		var reason := rs.can_play_reason(id)
		var cost := "%dM" % roundi(rs.effective_cost_money(id))
		if float(card.get("cost_influence", 0)) > 0:
			cost += " %dI" % int(card.get("cost_influence", 0))
		if float(card.get("cost_happiness", 0)) > 0:
			cost += " %dH" % int(card.get("cost_happiness", 0))
		if rs.fire_discount and card.get("tags", []).has("restoration"):
			cost += " (half price!)"
		var marks := ""
		if rs.market_bonus.has(id):
			marks += " [CRISIS WINDOW]"
		if card.has("risk"):
			marks += " [%d%% ODDS]" % roundi(float(card["risk"]["chance"]) * 100.0)
		var line2 := _state_line(reason, card, rs)
		if line2.is_empty():
			line2 = _effect_summary(card, rs)
		chip.text = "%s%s\n[%s]\n%s" % [card["name"], marks, cost, line2]
		chip.modulate = Color.WHITE if reason == &"ok" else Color(1, 1, 1, 0.45)
		chip.tooltip_text = _build_tooltip(card, rs, reason)
	for pid in _project_chips:
		_refresh_project_chip(pid, rs)
	if _pass_chip != null:
		_pass_chip.modulate = Color.WHITE if rs.phase == RunState.Phase.AWAIT_ACTION else Color(1, 1, 1, 0.45)


func _refresh_project_chip(pid: StringName, rs: RunState) -> void:
	var chip: Button = _project_chips[pid]
	var p := rs.catalog.project(pid)
	var upkeep := "%dM" % roundi(float(p.get("upkeep_money", 0)))
	if float(p.get("upkeep_influence", 0)) > 0:
		upkeep += " %dI" % int(p.get("upkeep_influence", 0))
	var status := String(rs.project_history.get(String(pid), ""))
	var active_turns := -1
	for ps in rs.active_projects:
		if ps.id == pid:
			active_turns = ps.turns_left
	if active_turns >= 0:
		chip.text = "%s\nACTIVE - %d turns left (click to abandon)" % [p["name"], active_turns]
		chip.modulate = Color.WHITE
	elif status == "completed":
		chip.text = "%s\nCOMPLETED" % p["name"]
		chip.modulate = Color(1, 1, 1, 0.45)
	elif not status.is_empty():
		chip.text = "%s\n%s" % [p["name"], status.to_upper()]
		chip.modulate = Color(1, 1, 1, 0.45)
	else:
		var reason := rs.can_start_project_reason(pid)
		chip.text = "%s  [%s/turn x%d]\n%s" % [p["name"], upkeep, int(p.get("turns", 3)),
			_project_state_line(reason, p)]
		chip.modulate = Color.WHITE if reason == &"ok" else Color(1, 1, 1, 0.45)
	chip.tooltip_text = _project_tooltip(p, rs)


func _project_state_line(reason: StringName, p: Dictionary) -> String:
	match reason:
		&"ok": return "Launch (pays first turn now)"
		&"no_money": return "Need %d money" % roundi(float(p.get("upkeep_money", 0)))
		&"no_influence": return "Need %d influence" % roundi(float(p.get("upkeep_influence", 0)))
		&"max_active": return "Two projects at once is the limit"
		&"already_done": return "Concluded this run"
		&"ended": return "The run is over"
	return String(reason)


func _project_tooltip(p: Dictionary, _rs: RunState) -> String:
	var lines: PackedStringArray = []
	lines.append("%s - a %d-turn (15-year) commitment" % [p["name"], int(p.get("turns", 3))])
	lines.append("Upkeep every turn: %d money%s" % [roundi(float(p.get("upkeep_money", 0))),
		(", %d influence" % int(p.get("upkeep_influence", 0))) if float(p.get("upkeep_influence", 0)) > 0 else ""])
	var completion: Dictionary = p.get("completion", {})
	for eff: Dictionary in completion.get("effects", []):
		lines.append("On completion: %s" % String(eff.get("op", "")).replace("_", " "))
	for key in completion.get("passive", {}):
		lines.append("Permanent: %s +%s" % [String(key).replace("_", " "),
			LogFormatter.fmt(completion["passive"][key])])
	var penalty: Dictionary = p.get("abandon_penalty", {})
	lines.append("Abandon or fail to pay: -%s happiness, -%s influence" % [
		LogFormatter.fmt(penalty.get("happiness", 0)), LogFormatter.fmt(penalty.get("influence", 0))])
	if not String(p.get("flavor", "")).is_empty():
		lines.append("\"%s\"" % p["flavor"])
	return "\n".join(lines)


## Offer state matrix: every state visible, every reason stated (doc 03).
func _state_line(reason: StringName, card: Dictionary, rs: RunState) -> String:
	match reason:
		&"ok":
			return ""
		&"no_money":
			return "Need %d money (have %d)" % [roundi(rs.effective_cost_money(card["id"])), roundi(rs.money)]
		&"no_influence":
			return "Need %d influence (have %d)" % [int(card.get("cost_influence", 0)), roundi(rs.influence)]
		&"no_happiness":
			return "Costs %d happiness (have %d) - the public cannot bear it" % [int(card.get("cost_happiness", 0)), roundi(rs.happiness)]
		&"locked_allies":
			return "Needs %d allies (have %d)" % [int(card.get("requires", {}).get("allies_min", 0)), rs.allies]
		&"turn_limit":
			return "Five cards a turn is the limit - Space to resolve"
		&"not_in_market":
			return "Not offered this turn"
		&"capped":
			var sector_name := ""
			for eff in card.get("effects", []):
				if String(eff.get("op", "")) == "sector_progress":
					sector_name = WorldEnums.SECTOR_NAMES[StringName(String(eff["sector"]))]
			return "%s at 70%% cap - play a sufficiency policy" % sector_name
		&"media_active":
			return "Active since it was funded"
		&"no_target":
			return "No bloc left to move" if String(card.get("category", "")) == "diplomacy" else "No target available"
		&"resolving":
			return "Resolving..."
		&"ended":
			return "The run is over"
	return String(reason)


func _effect_summary(card: Dictionary, rs: RunState) -> String:
	var parts: PackedStringArray = []
	for eff: Dictionary in card.get("effects", []):
		match String(eff.get("op", "")):
			"sector_progress":
				var s := "%s +%d%%" % [WorldEnums.SECTOR_NAMES[StringName(String(eff["sector"]))], int(eff["amount"])]
				if bool(eff.get("lifts_cap", false)):
					s += " (lifts cap)"
				parts.append(s)
			"joint_progress":
				parts.append("All sectors +%d%%" % int(eff["amount"]))
			"happiness", "wellbeing":
				var amount := float(eff["amount"])
				var note := ""
				if amount < 0.0 and bool(eff.get("waivable", false)) and (rs.media or rs.window):
					note = " (waived: %s)" % ("media" if rs.media else "window")
				parts.append("Happiness %+d%s" % [int(amount), note])
			"sink_now":
				parts.append("Absorption +%.1f" % float(eff["amount"]))
			"reforest":
				parts.append("+%.1f absorb/turn x %d turns" % [float(eff["per_turn"]), int(eff["turns"])])
			"adapt":
				parts.append("Adaptation +%d" % int(eff["amount"]))
			"media":
				parts.append("Media: waives sufficiency costs")
			"ally":
				parts.append("+1 ally (+40M +2I per turn, damps world drift)")
			"actor_fund":
				parts.append("Biggest bloc: -%.0f Gt, drift -%.1f" % [
					float(eff.get("cut", 0)), float(eff.get("trend_cut", 0))])
			"actor_treaty":
				parts.append("Steepest bloc: drift -%.1f/turn" % float(eff.get("trend_cut", 0)))
	var risk: Dictionary = card.get("risk", {})
	if not risk.is_empty():
		parts.append("%d%% odds - big upside, real downside" % roundi(float(risk["chance"]) * 100.0))
	var rewards: Dictionary = card.get("rewards", {})
	if not rewards.is_empty():
		var gains: PackedStringArray = []
		for key in ["money", "influence", "happiness", "knowledge"]:
			if float(rewards.get(key, 0)) > 0:
				gains.append("+%s%s" % [LogFormatter.fmt(rewards[key]),
					{"money": "M", "influence": "I", "happiness": "H", "knowledge": "K"}[key]])
		parts.append("-> " + " ".join(gains))
	var combo_tags: PackedStringArray = []
	for tag in card.get("tags", []):
		if DataValidator.COMBO_TAGS.has(String(tag)):
			combo_tags.append(String(tag))
	if combo_tags.size() > 0:
		parts.append("[%s]" % "/".join(combo_tags))
	return ", ".join(parts)


func _build_tooltip(card: Dictionary, rs: RunState, reason: StringName) -> String:
	var lines: PackedStringArray = []
	lines.append("%s [%s]" % [card["name"], card["id"]])
	if rs.market_bonus.has(StringName(String(card["id"]))):
		lines.append("CRISIS WINDOW - this turn's events put this offer on the table")
	if card.get("tags", []).has("sufficiency"):
		lines.append("SUFFICIENCY - lifts this sector's ceiling from 70% to 100%")
	var cost_line := "Cost: %d money" % roundi(rs.effective_cost_money(card["id"]))
	if float(card.get("cost_influence", 0)) > 0:
		cost_line += ", %d influence" % int(card.get("cost_influence", 0))
	if float(card.get("cost_happiness", 0)) > 0:
		cost_line += ", %d happiness" % int(card.get("cost_happiness", 0))
	lines.append(cost_line)
	lines.append(_effect_summary(card, rs))
	var risk: Dictionary = card.get("risk", {})
	if not risk.is_empty():
		lines.append("PUSH YOUR LUCK - %d%% success:" % roundi(float(risk["chance"]) * 100.0))
		for eff: Dictionary in risk.get("on_success", {}).get("effects", []):
			lines.append("  on success: %s" % String(eff.get("op", "")).replace("_", " "))
		for eff: Dictionary in risk.get("on_failure", {}).get("effects", []):
			lines.append("  on failure: %s %s" % [String(eff.get("op", "")).replace("_", " "),
				LogFormatter.fmt(eff.get("amount", ""))])
	var combo_tags: PackedStringArray = []
	for tag in card.get("tags", []):
		if DataValidator.COMBO_TAGS.has(String(tag)):
			combo_tags.append(String(tag))
	if combo_tags.size() > 0:
		lines.append("Tags (answer crises, build combos): " + ", ".join(combo_tags))
	# Projected post-play values for sector cards (forecast, pillar 1).
	for eff: Dictionary in card.get("effects", []):
		if String(eff.get("op", "")) == "sector_progress":
			var ss := rs.sector(StringName(String(eff["sector"])))
			var cap := 100.0 if (ss.suff_played or bool(eff.get("lifts_cap", false))) else ss.cap()
			var after := minf(cap, ss.progress + float(eff["amount"]))
			lines.append("%s: %d%% -> %d%%" % [WorldEnums.SECTOR_NAMES[StringName(String(eff["sector"]))], roundi(ss.progress), roundi(after)])
	var codex: Dictionary = card.get("codex", {})
	if not codex.is_empty():
		var seen: bool = Meta.codex_seen.has(String(card["id"]))
		lines.append("Codex: %s%s" % [String(codex.get("title", "")),
			"" if seen else " (fund it once to unlock the entry - C opens the codex)"])
	if not String(card.get("flavor", "")).is_empty():
		lines.append("\"%s\"" % card["flavor"])
	if reason != &"ok":
		lines.append("[%s]" % _state_line(reason, card, rs))
	return "\n".join(lines)
