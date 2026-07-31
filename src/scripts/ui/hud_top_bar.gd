class_name HudTopBar
extends PanelContainer
## Three-pillar HUD: Money, the global carbon ledger (city + world vs A),
## Happiness, plus the CLIMATE CLOCK (the adversary gauge), Influence/Allies,
## the turn counter, the next summit, and the turn prompt.
## Max ~6 numbers on the default HUD (pillar 1); details live in tooltips.

var year_label: Label
var money_label: Label
var carbon_label: Label
var happiness_label: Label
var influence_label: Label
var chain_label: Label
var summit_label: Label
var prompt_label: Label
var gauge: WarmingGauge
var seed_label: Label
var help_button: Button


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20241e")
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	add_theme_stylebox_override("panel", style)
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	custom_minimum_size = Vector2(0, 96)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	add_child(row)

	year_label = _big_label(row, "2030", Color("f2f7e8"))
	year_label.tooltip_text = "One turn = 5 years. 15 turns from 2030 to 2100.\nReach net <= 0 before the clock hits 100% and you win - any turn."
	money_label = _big_label(row, "", Color("e8d48a"))
	money_label.tooltip_text = "Money: funds every market card.\nIncome 250/turn +40 per ally; penalties below 40 and 25 happiness."
	carbon_label = _big_label(row, "", Color("a8c68a"))
	carbon_label.tooltip_text = "The global ledger: your sphere's emissions + the world's blocs vs absorption.\nNet <= 0 at any turn = victory. The world's share only falls through diplomacy."
	happiness_label = _big_label(row, "", Color("8ac6c6"))
	happiness_label.tooltip_text = "Happiness: wellbeing and social acceptance.\nBelow 40: income x0.75 and social crises. Below 25: income x0.5.\nAT ZERO THE CITY REVOLTS - the run is lost."
	influence_label = _big_label(row, "", Color("c6a8e0"))
	influence_label.tooltip_text = "Influence and allies. Allies add +40 money, +2 influence per turn\nand damp the world's emission drift. Spent on alliances and treaties."
	chain_label = _big_label(row, "", Color("e8d48a"))
	chain_label.tooltip_text = "Combo chain: every combo grows it, a comboless turn shrinks it.\nEach chain step adds +10% to combo rewards (up to +100%)."

	gauge = WarmingGauge.new()
	row.add_child(gauge)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right)
	summit_label = Label.new()
	summit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	summit_label.add_theme_font_size_override("font_size", 11)
	summit_label.add_theme_color_override("font_color", Color("e8d48a"))
	right.add_child(summit_label)
	prompt_label = Label.new()
	prompt_label.text = ""
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", Color("f2f7e8"))
	right.add_child(prompt_label)
	seed_label = Label.new()
	seed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	seed_label.add_theme_font_size_override("font_size", 10)
	seed_label.add_theme_color_override("font_color", Color("6e746a"))
	right.add_child(seed_label)

	help_button = Button.new()
	help_button.text = "?"
	help_button.tooltip_text = "Tutorial (F1)"
	help_button.focus_mode = Control.FOCUS_NONE
	help_button.custom_minimum_size = Vector2(36, 36)
	help_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(help_button)


func _big_label(parent: Control, text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(l)
	return l


func refresh(rs: RunState) -> void:
	year_label.text = "%d\nTurn %d/%d" % [rs.year, rs.turn_index(), RunState.total_turns()]
	money_label.text = "Money %d" % roundi(rs.money)
	var n := rs.net_emissions()
	carbon_label.text = "City %.0f + World %.0f | A %.0f | net %+.1f" % [
		rs.gross_emissions(), rs.world_emissions(), rs.absorption, n]
	happiness_label.text = "Happiness %d" % roundi(rs.happiness)
	influence_label.text = "Influence %d | Allies %d" % [roundi(rs.influence), rs.allies]
	chain_label.text = "Chain x%d (+%d%%)" % [rs.combo_chain,
		roundi((SocietyCalc.combo_mult(rs.combo_chain) - 1.0) * 100.0)]
	gauge.set_state(rs)
	var next_summit := rs.catalog.next_summit(rs.turn_index())
	if next_summit.is_empty():
		summit_label.text = ""
	else:
		var goal: Dictionary = next_summit.get("goal", {})
		summit_label.text = "SUMMIT turn %d - %s: net <= %.0f (now %+.0f)" % [
			int(next_summit["turn"]), String(next_summit["name"]),
			float(goal.get("lte", 0)), n]
		summit_label.tooltip_text = String(next_summit.get("blurb", "")) \
			+ "\nMeet the target on that turn for a reward; miss it and the world loses faith."
	var arch_note := ""
	if not rs.archetype.is_empty():
		arch_note = "  |  %s" % String(rs.archetype.get("name", ""))
	seed_label.text = "seed %d%s" % [rs.run_seed, arch_note]


func set_prompt(text: String) -> void:
	prompt_label.text = text
