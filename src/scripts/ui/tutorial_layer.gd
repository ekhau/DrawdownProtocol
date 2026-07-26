class_name TutorialLayer
extends Control
## Step-by-step tutorial overlay (GoldenRules #7: teach through play).
## Dims the screen with a spotlight cutout over the step's target control and
## explains one concept at a time. The dim is purely visual (mouse_filter
## IGNORE) so the player always performs the REAL action; action steps advance
## on the real sim signal (via notify()), informational steps on Next.
## Step content is data (data/tutorial.json, validated by DataValidator);
## this layer computes no gameplay values.

signal dismissed(completed: bool)

const TUTORIAL_PATH := "res://data/tutorial.json"
const DIM := Color(0.0, 0.0, 0.0, 0.55)
const SPOT_MARGIN := 8.0
const OUTLINE := Color("f2e28a")
const PANEL_MARGIN := 12.0  # minimum clearance to every viewport edge
const PANEL_GAP := 24.0     # clearance between the panel and the spotlight

var steps: Array = []
var index: int = -1
## Set by Main: resolves a target anchor name (StringName) to a global Rect2;
## an empty Rect2 means "no spotlight, dim everything".
var anchor_resolver: Callable

var _panel: PanelContainer
var _title: Label
var _body: Label
var _counter: Label
var _next_btn: Button
var _hint: Label
var _target_rect := Rect2()
var _has_target := false

var active: bool:
	get: return visible and index >= 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # never block the real controls
	visible = false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TUTORIAL_PATH))
	if parsed is Dictionary:
		steps = parsed.get("steps", [])

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1a1e18", 0.97)
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = OUTLINE
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size = Vector2(560, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 16)
	_title.add_theme_color_override("font_color", Color("f2e28a"))
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_counter = Label.new()
	_counter.add_theme_font_size_override("font_size", 11)
	_counter.add_theme_color_override("font_color", Color("9aa694"))
	header.add_child(_counter)
	_body = Label.new()
	_body.add_theme_font_size_override("font_size", 13)
	_body.add_theme_color_override("font_color", Color("d8d8d0"))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(524, 0)
	vbox.add_child(_body)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	vbox.add_child(buttons)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.add_theme_color_override("font_color", Color("a0d890"))
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(_hint)
	_next_btn = Button.new()
	_next_btn.text = "Next"
	_next_btn.focus_mode = Control.FOCUS_NONE
	_next_btn.pressed.connect(advance)
	buttons.add_child(_next_btn)
	var close_btn := Button.new()
	close_btn.text = "Close tutorial"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(func() -> void: dismiss(false))
	buttons.add_child(close_btn)

	get_viewport().size_changed.connect(func() -> void:
		if active:
			_show_step())


func open() -> void:
	if steps.is_empty():
		return
	index = 0
	visible = true
	_show_step()


## Player-facing close (button / F1 / "?"): counts as dismissed and persists.
func dismiss(completed: bool) -> void:
	if not visible:
		return
	visible = false
	index = -1
	queue_redraw()
	dismissed.emit(completed)


## Silent close (e.g. the run ended): no flag persisted, may auto-open again.
func close_silent() -> void:
	visible = false
	index = -1
	queue_redraw()


func advance() -> void:
	if not active:
		return
	if index >= steps.size() - 1:
		dismiss(true)
		return
	index += 1
	_show_step()


## Called by Main from its existing signal handlers; advances the current
## step when it is waiting for exactly this player action.
func notify(event: StringName) -> void:
	if not active:
		return
	var advance_spec: Dictionary = steps[index].get("advance", {})
	if String(advance_spec.get("type", "")) == "signal" \
			and StringName(String(advance_spec.get("signal", ""))) == event:
		advance()


func current_step_id() -> StringName:
	if not active:
		return &""
	return StringName(String(steps[index].get("id", "")))


func _show_step() -> void:
	var step: Dictionary = steps[index]
	_title.text = String(step.get("title", ""))
	_body.text = String(step.get("text", ""))
	_counter.text = "%d / %d" % [index + 1, steps.size()]
	var is_signal := String(step.get("advance", {}).get("type", "")) == "signal"
	_next_btn.visible = not is_signal
	_next_btn.text = "Finish" if index == steps.size() - 1 else "Next"
	_hint.text = "Do it to continue..." if is_signal else ""
	_has_target = false
	_target_rect = Rect2()
	var target := StringName(String(step.get("target", "none")))
	if target != &"none" and anchor_resolver.is_valid():
		var rect: Rect2 = anchor_resolver.call(target)
		if rect.size != Vector2.ZERO:
			_target_rect = rect.grow(SPOT_MARGIN)
			_has_target = true
	_place_panel()
	queue_redraw()


func _place_panel() -> void:
	await get_tree().process_frame  # let the panel re-layout for the new text
	if not active:
		return
	var margin := PANEL_MARGIN
	var gap := PANEL_GAP
	# The layer is full-rect over the viewport; fall back to the viewport rect
	# if layout has not resolved yet (belt and braces for the 0-size case).
	var view := size
	if view.x < 2.0 or view.y < 2.0:
		view = get_viewport_rect().size
	var panel_size := _panel.size
	var x := (view.x - panel_size.x) / 2.0
	var y := (view.y - panel_size.y) / 2.0  # default: dead center (no target)
	if _has_target:
		# Place adjacent to the spotlight, on its roomier vertical side;
		# fall back to screen center when neither side can fit the panel.
		var above_space := _target_rect.position.y
		var below_space := view.y - _target_rect.end.y
		if _target_rect.get_center().y < view.y * 0.5 and below_space >= panel_size.y + gap + margin:
			y = _target_rect.end.y + gap
		elif above_space >= panel_size.y + gap + margin:
			y = _target_rect.position.y - panel_size.y - gap
		elif below_space >= panel_size.y + gap + margin:
			y = _target_rect.end.y + gap
		# Nudge horizontally off narrow spotlights when they would overlap.
		var candidate := Rect2(Vector2(x, y), panel_size)
		if candidate.intersects(_target_rect) and _target_rect.size.x < view.x * 0.6:
			var left_x := _target_rect.position.x - panel_size.x - gap
			x = left_x if left_x >= margin else _target_rect.end.x + gap
	# Safety net: always fully inside the viewport, whatever was chosen above.
	# maxf guards the min>max inversion when the panel is larger than the view.
	x = clampf(x, margin, maxf(margin, view.x - panel_size.x - margin))
	y = clampf(y, margin, maxf(margin, view.y - panel_size.y - margin))
	_panel.position = Vector2(x, y)


func _draw() -> void:
	if not active:
		return
	if not _has_target:
		draw_rect(Rect2(Vector2.ZERO, size), DIM)
		return
	var r := _target_rect
	# Four dim rects around the spotlight cutout.
	draw_rect(Rect2(0, 0, size.x, r.position.y), DIM)
	draw_rect(Rect2(0, r.end.y, size.x, size.y - r.end.y), DIM)
	draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), DIM)
	draw_rect(Rect2(r.end.x, r.position.y, size.x - r.end.x, r.size.y), DIM)
	# Spotlight outline.
	draw_rect(r, OUTLINE, false, 3.0)
