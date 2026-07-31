class_name RegionPanel
extends PanelContainer
## One Tier A dashboard panel: renders a region's derived state, never owns it.
## Spec: docs/Phase_3/03_Board_Rendering_Spec.md (Tier A table).

signal panel_clicked(region_id: StringName)
signal panel_hovered(region_id: StringName)

const COLOR_E := Color("9c3b24")       # emissions (dark rust)
const COLOR_A := Color("79a94a")       # absorption (light leaf)
const COLOR_TRACK := Color("2e332c")
const COLOR_ALLY := Color("d9a441")    # gold ring
const COLOR_HOME := Color("5fb3b3")
const COLOR_NEUTRAL := Color("55594f")
const FACE_GREY := Color("8f8f87")
const FACE_MID := Color("d8d8d0")
const FACE_GREEN := Color("cfe8b8")

var region: RegionData
var selected := false
var highlighted := false  # DIP1 target prompt pulse

var _name_label: Label
var _arch_label: Label
var _bar_e: ColorRect
var _bar_e_track: ColorRect
var _bar_a: ColorRect
var _bar_a_track: ColorRect
var _ledger_label: Label
var _scar_label: Label
var _style: StyleBoxFlat
var _face_progress := 0.0

const BAR_MAX_W := 120.0


func _ready() -> void:
	custom_minimum_size = Vector2(208, 128)
	_style = StyleBoxFlat.new()
	_style.bg_color = FACE_MID
	_style.set_corner_radius_all(6)
	_style.set_border_width_all(2)
	_style.border_color = COLOR_NEUTRAL
	_style.content_margin_left = 8.0
	_style.content_margin_right = 8.0
	_style.content_margin_top = 5.0
	_style.content_margin_bottom = 5.0
	add_theme_stylebox_override("panel", _style)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_color_override("font_color", Color("20241e"))
	vbox.add_child(_name_label)
	_arch_label = Label.new()
	_arch_label.add_theme_font_size_override("font_size", 11)
	_arch_label.add_theme_color_override("font_color", Color("4a4f45"))
	vbox.add_child(_arch_label)
	_bar_e_track = _make_bar_row(vbox, "E", COLOR_E)
	_bar_e = _bar_e_track.get_child(0)
	_bar_a_track = _make_bar_row(vbox, "A", COLOR_A)
	_bar_a = _bar_a_track.get_child(0)
	_ledger_label = Label.new()
	_ledger_label.add_theme_font_size_override("font_size", 11)
	_ledger_label.add_theme_color_override("font_color", Color("20241e"))
	vbox.add_child(_ledger_label)
	_scar_label = Label.new()
	_scar_label.add_theme_font_size_override("font_size", 11)
	_scar_label.add_theme_color_override("font_color", Color("6b3226"))
	vbox.add_child(_scar_label)

	gui_input.connect(_on_gui_input)
	mouse_entered.connect(func() -> void:
		if region != null:
			panel_hovered.emit(region.id)
		_update_border())
	mouse_exited.connect(_update_border)


func _make_bar_row(parent: Control, label_text: String, color: Color) -> ColorRect:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("20241e"))
	lbl.custom_minimum_size = Vector2(12, 0)
	row.add_child(lbl)
	var track := ColorRect.new()
	track.color = COLOR_TRACK
	track.custom_minimum_size = Vector2(BAR_MAX_W, 10)
	track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(track)
	var fill := ColorRect.new()
	fill.color = color
	fill.position = Vector2(1, 1)
	fill.size = Vector2(0, 8)
	track.add_child(fill)
	return track


func bind_region(r: RegionData) -> void:
	region = r
	refresh(null)


## Refresh from sim state (rs may be null before the first run starts).
func refresh(rs: RunState) -> void:
	if region == null:
		return
	var badge := ""
	match region.ally_state:
		WorldEnums.AllyState.PLAYER_HOME: badge = "  [HOME]"
		WorldEnums.AllyState.ALLY: badge = "  [ALLY]"
	_name_label.text = region.display_name + badge
	_arch_label.text = _archetype_pretty() + "  " + _tags_pretty()
	if rs != null:
		var e := rs.region_emissions(region)
		var a := rs.region_absorption(region)
		# Bars scaled against a fixed 12 Gt window so panel bars are comparable.
		_bar_e.size.x = clampf(e / 12.0, 0.0, 1.0) * (BAR_MAX_W - 2.0)
		_bar_a.size.x = clampf(a / 12.0, 0.0, 1.0) * (BAR_MAX_W - 2.0)
		_ledger_label.text = "E %.1f  A %.1f  net %+.1f" % [e, a, e - a]
		_face_progress = rs.avg_progress() / 100.0
	var scars := ""
	for s in region.scars.slice(maxi(0, region.scars.size() - 3)):
		scars += ("^" if String(s).begins_with("burned") else "~") + " "
	_scar_label.text = ("scars: " + scars) if not scars.is_empty() else ""
	_style.bg_color = _face_color()
	_update_border()
	tooltip_text = _build_tooltip(rs)


func _archetype_pretty() -> String:
	return String(region.archetype).capitalize()


func _tags_pretty() -> String:
	var tags: PackedStringArray = []
	if region.coastal:
		tags.append("coastal")
	if region.arid:
		tags.append("arid")
	if region.forested:
		tags.append("forested")
	return ("(" + ", ".join(tags) + ")") if tags.size() > 0 else ""


func _face_color() -> Color:
	# Grey -> mid -> green as the world transitions (the era arc, per panel).
	if _face_progress < 0.5:
		return FACE_GREY.lerp(FACE_MID, _face_progress * 2.0)
	return FACE_MID.lerp(FACE_GREEN, (_face_progress - 0.5) * 2.0)


func _update_border() -> void:
	var hovering := get_global_rect().has_point(get_global_mouse_position())
	if highlighted:
		_style.border_color = Color("f2e28a")
		_style.set_border_width_all(4)
	elif selected:
		_style.border_color = Color("f2f7e8")
		_style.set_border_width_all(3)
	elif region != null and region.ally_state == WorldEnums.AllyState.ALLY:
		_style.border_color = COLOR_ALLY
		_style.set_border_width_all(3 if hovering else 2)
	elif region != null and region.ally_state == WorldEnums.AllyState.PLAYER_HOME:
		_style.border_color = COLOR_HOME
		_style.set_border_width_all(3 if hovering else 2)
	else:
		_style.border_color = COLOR_NEUTRAL.lightened(0.35) if hovering else COLOR_NEUTRAL
		_style.set_border_width_all(3 if hovering else 2)


func set_selected(v: bool) -> void:
	selected = v
	_update_border()


func set_highlighted(v: bool) -> void:
	highlighted = v
	_update_border()


func flash(color: Color) -> void:
	var tween := create_tween()
	modulate = color
	tween.tween_property(self, "modulate", Color.WHITE, 0.6)


func _build_tooltip(rs: RunState) -> String:
	var lines: PackedStringArray = []
	lines.append("%s - %s %s" % [region.display_name, _archetype_pretty(), _tags_pretty()])
	if rs != null:
		lines.append("Emissions %.1f Gt/yr  Absorption %.1f Gt/yr" % [rs.region_emissions(region), rs.region_absorption(region)])
		lines.append("Shares: ind %d%%  tra %d%%  agr %d%%  sink %d%%" % [
			roundi(region.ind_share * 100), roundi(region.tra_share * 100),
			roundi(region.agr_share * 100), roundi(region.sink_share * 100)])
	match region.ally_state:
		WorldEnums.AllyState.PLAYER_HOME:
			lines.append("The coalition's home.")
		WorldEnums.AllyState.ALLY:
			lines.append("Ally: +40 money and +2 influence per turn.")
		_:
			lines.append("Neutral. Form Alliance: 50 money + 25 influence.")
	for s in region.scars:
		var parts := String(s).split("_")
		lines.append("Scar: %s in %s" % [parts[0], parts[1] if parts.size() > 1 else "?"])
	return "\n".join(lines)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if region != null:
			panel_clicked.emit(region.id)
		accept_event()
