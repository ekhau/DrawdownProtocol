class_name CardTray
extends PanelContainer
## The Policy Board: the full 15-card catalog every year, grouped by category,
## plus the explicit "Bank funds" pass chip. Cards are NEVER hidden; every
## blocked state shows its reason (docs/Phase_5/03 state matrix).

signal card_chosen(card_id: StringName)
signal pass_chosen

const CATEGORY_ORDER := ["ind", "tra", "agr", "sink", "society", "diplomacy"]
const CATEGORY_LABELS := {
	"ind": "Industry", "tra": "Transport", "agr": "Agro-economy",
	"sink": "Sinks", "society": "Society", "diplomacy": "Diplomacy",
}

var _chips: Dictionary = {}  # StringName -> Button
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


func build(catalog: Catalog) -> void:
	for child in get_children():
		child.queue_free()
	_chips.clear()
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 10)
	add_child(columns)
	for cat in CATEGORY_ORDER:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 3)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns.add_child(col)
		var header := Label.new()
		header.text = CATEGORY_LABELS[cat]
		header.add_theme_font_size_override("font_size", 12)
		header.add_theme_color_override("font_color", Color("9aa694"))
		col.add_child(header)
		for card in catalog.cards:
			if String(card["category"]) != cat:
				continue
			var chip := Button.new()
			chip.alignment = HORIZONTAL_ALIGNMENT_LEFT
			chip.add_theme_font_size_override("font_size", 12)
			chip.custom_minimum_size = Vector2(0, 40)
			chip.focus_mode = Control.FOCUS_NONE  # Space must always mean "advance year"
			var id := StringName(String(card["id"]))
			chip.pressed.connect(func() -> void: card_chosen.emit(id))
			col.add_child(chip)
			_chips[id] = chip
	# The explicit pass chip at the board's end.
	var pass_col := VBoxContainer.new()
	pass_col.add_theme_constant_override("separation", 3)
	columns.add_child(pass_col)
	var pass_header := Label.new()
	pass_header.text = "Or"
	pass_header.add_theme_font_size_override("font_size", 12)
	pass_header.add_theme_color_override("font_color", Color("9aa694"))
	pass_col.add_child(pass_header)
	_pass_chip = Button.new()
	_pass_chip.text = "Bank funds\n(pass this year)"
	_pass_chip.add_theme_font_size_override("font_size", 12)
	_pass_chip.custom_minimum_size = Vector2(120, 40)
	_pass_chip.focus_mode = Control.FOCUS_NONE
	_pass_chip.pressed.connect(func() -> void: pass_chosen.emit())
	pass_col.add_child(_pass_chip)


func refresh(rs: RunState) -> void:
	_rs = rs
	for id in _chips:
		var chip: Button = _chips[id]
		var card := rs.catalog.card(id)
		var reason := rs.can_play_reason(id)
		var cost := "%dM" % roundi(rs.effective_cost_money(id))
		if float(card.get("cost_influence", 0)) > 0:
			cost += " %dI" % int(card.get("cost_influence", 0))
		if rs.fire_discount and card.get("tags", []).has("restoration"):
			cost += " (half price!)"
		var line2 := _state_line(reason, card, rs)
		chip.text = "%s  [%s]%s" % [card["name"], cost, ("\n" + line2) if not line2.is_empty() else "\n" + _effect_summary(card, rs)]
		chip.modulate = Color.WHITE if reason == &"ok" else Color(1, 1, 1, 0.45)
		chip.tooltip_text = _build_tooltip(card, rs, reason)
	if _pass_chip != null:
		_pass_chip.modulate = Color.WHITE if not rs.action_taken and rs.phase == RunState.Phase.AWAIT_ACTION else Color(1, 1, 1, 0.45)


## Card state matrix: every state visible, every reason stated (doc 03).
func _state_line(reason: StringName, card: Dictionary, rs: RunState) -> String:
	match reason:
		&"ok":
			return ""
		&"no_money":
			return "Need %d money (have %d)" % [roundi(rs.effective_cost_money(card["id"])), roundi(rs.money)]
		&"no_influence":
			return "Need %d influence (have %d)" % [int(card.get("cost_influence", 0)), roundi(rs.influence)]
		&"locked_allies":
			return "Needs %d allies (have %d)" % [int(card.get("requires", {}).get("allies_min", 0)), rs.allies]
		&"capped":
			var sector_name := ""
			for eff in card.get("effects", []):
				if String(eff.get("op", "")) == "sector_progress":
					sector_name = WorldEnums.SECTOR_NAMES[StringName(String(eff["sector"]))]
			return "%s at 70%% cap - play a sufficiency policy" % sector_name
		&"media_active":
			return "Active since it was funded"
		&"no_target":
			return "Every nation is with you" if rs.allies >= 6 else "No neutral nation left"
		&"action_taken":
			return "Enacted this year" if rs.records.size() >= 0 and _was_played_this_year(card, rs) else "Year resolved - Space to advance"
		&"ended":
			return "The run is over"
	return String(reason)


func _was_played_this_year(card: Dictionary, rs: RunState) -> bool:
	return rs._pending_action.get("action", &"") == StringName(String(card["id"]))


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
				parts.append("+%.1f absorb/yr x %d yrs" % [float(eff["per_year"]), int(eff["years"])])
			"adapt":
				parts.append("Adaptation +%d" % int(eff["amount"]))
			"media":
				parts.append("Media: waives sufficiency costs")
			"ally":
				parts.append("+1 ally (+20M +1I yearly)")
	return ", ".join(parts)


func _build_tooltip(card: Dictionary, rs: RunState, reason: StringName) -> String:
	var lines: PackedStringArray = []
	lines.append("%s [%s]" % [card["name"], card["id"]])
	if card.get("tags", []).has("sufficiency"):
		lines.append("SUFFICIENCY - lifts this sector's ceiling from 70% to 100%")
	lines.append("Cost: %d money%s" % [roundi(rs.effective_cost_money(card["id"])),
		(", %d influence" % int(card.get("cost_influence", 0))) if float(card.get("cost_influence", 0)) > 0 else ""])
	lines.append(_effect_summary(card, rs))
	# Projected post-play values for sector cards (forecast, pillar 1).
	for eff: Dictionary in card.get("effects", []):
		if String(eff.get("op", "")) == "sector_progress":
			var ss := rs.sector(StringName(String(eff["sector"])))
			var cap := 100.0 if (ss.suff_played or bool(eff.get("lifts_cap", false))) else ss.cap()
			var after := minf(cap, ss.progress + float(eff["amount"]))
			lines.append("%s: %d%% -> %d%%" % [WorldEnums.SECTOR_NAMES[StringName(String(eff["sector"]))], roundi(ss.progress), roundi(after)])
	if not String(card.get("flavor", "")).is_empty():
		lines.append("\"%s\"" % card["flavor"])
	if reason != &"ok":
		lines.append("[%s]" % _state_line(reason, card, rs))
	return "\n".join(lines)
