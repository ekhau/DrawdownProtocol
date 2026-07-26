class_name BannerLayer
extends Control
## Non-modal banner queue for event beats and the rare feedback/band
## interstitials. Damage register and opportunity register have distinct
## visual voices; damage always leads (docs/Phase_5/04).

const BEAT_TIME := 1.4

var _queue: Array[Dictionary] = []
var _label: RichTextLabel
var _panel: PanelContainer
var _style: StyleBoxFlat
var _showing := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0.13, 0.11, 0.09, 0.92)
	_style.set_corner_radius_all(8)
	_style.content_margin_left = 22.0
	_style.content_margin_right = 22.0
	_style.content_margin_top = 10.0
	_style.content_margin_bottom = 10.0
	_panel.add_theme_stylebox_override("panel", _style)
	_panel.anchor_left = 0.18
	_panel.anchor_right = 0.72
	_panel.anchor_top = 0.12
	_panel.anchor_bottom = 0.12
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("normal_font_size", 15)
	_panel.add_child(_label)


## kind: "damage" | "opportunity" | "interstitial" | "hope" | "combo"
func push(kind: String, text: String) -> void:
	_queue.append({"kind": kind, "text": text})
	if not _showing:
		_next()


func skip_all() -> void:
	_queue.clear()
	_panel.visible = false
	_showing = false


func _next() -> void:
	if _queue.is_empty():
		_panel.visible = false
		_showing = false
		return
	_showing = true
	var beat: Dictionary = _queue.pop_front()
	var color := "e0a080"
	match String(beat["kind"]):
		"opportunity": color = "a0d890"
		"interstitial": color = "f2c894"
		"hope": color = "b8e8b0"
		"combo": color = "e8d48a"
	_style.border_color = Color(color)
	_style.set_border_width_all(2)
	_label.text = "[color=#%s]%s[/color]" % [color, String(beat["text"]).replace("[", "[lb]")]
	_panel.visible = true
	_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(_panel, "modulate", Color.WHITE, 0.12)
	tween.tween_interval(BEAT_TIME)
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 0), 0.18)
	tween.tween_callback(_next)
