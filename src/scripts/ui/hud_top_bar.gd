class_name HudTopBar
extends PanelContainer
## Three-pillar HUD: Money, Carbon balance (E vs A), Happiness, plus the
## warming gauge, Influence/Allies, year and the turn prompt.
## Max ~6 numbers on the default HUD (pillar 1); details live in tooltips.

var year_label: Label
var money_label: Label
var carbon_label: Label
var happiness_label: Label
var influence_label: Label
var prompt_label: Label
var gauge: WarmingGauge
var seed_label: Label


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20241e")
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	add_theme_stylebox_override("panel", style)
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	custom_minimum_size = Vector2(0, 96)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	add_child(row)

	year_label = _big_label(row, "2030", Color("f2f7e8"))
	money_label = _big_label(row, "", Color("e8d48a"))
	money_label.tooltip_text = "Money: funds every transformation.\nIncome 100/yr +20 per ally; penalties below 40 and 25 happiness."
	carbon_label = _big_label(row, "", Color("a8c68a"))
	carbon_label.tooltip_text = "Carbon balance: emissions vs absorption.\nNeutrality (win condition) = net <= 0 by 2100."
	happiness_label = _big_label(row, "", Color("8ac6c6"))
	happiness_label.tooltip_text = "Happiness: wellbeing and social acceptance.\nBelow 40: income x0.75 and social crises. Below 25: income x0.5."
	influence_label = _big_label(row, "", Color("c6a8e0"))
	influence_label.tooltip_text = "Influence and allies. Allies add +20 money and +1 influence yearly.\nSpent on alliances (25) and joint projects (15)."

	gauge = WarmingGauge.new()
	row.add_child(gauge)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right)
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


func _big_label(parent: Control, text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(l)
	return l


func refresh(rs: RunState) -> void:
	year_label.text = str(rs.year)
	money_label.text = "Money %d" % roundi(rs.money)
	var e := rs.gross_emissions()
	var n := rs.net_emissions()
	carbon_label.text = "E %.1f | A %.1f | net %+.1f" % [e, rs.absorption, n]
	happiness_label.text = "Happiness %d" % roundi(rs.happiness)
	influence_label.text = "Influence %d | Allies %d" % [roundi(rs.influence), rs.allies]
	gauge.set_temp(rs.temp, rs.warming_band())
	seed_label.text = "seed %d" % rs.run_seed


func set_prompt(text: String) -> void:
	prompt_label.text = text
