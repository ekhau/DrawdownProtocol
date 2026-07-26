class_name WarmingGauge
extends Control
## The warming thermometer with the +1.5 / +2.0 marks drawn on the gauge
## (design pillar 1: thresholds are always visible).

const T_MIN := 1.2
const T_MAX := 2.1

var temp := 1.30
var band := 0


func _ready() -> void:
	custom_minimum_size = Vector2(340, 40)


func set_temp(t: float, b: int) -> void:
	temp = t
	band = b
	queue_redraw()
	tooltip_text = ("Warming: +%.2f C above pre-industrial\n" % t) \
		+ "Band: %s\n" % ["Stable", "OVERSHOOT I", "OVERSHOOT II"][b] \
		+ "Warning +1.5 C - Defeat +2.0 C"


func _frac(t: float) -> float:
	return clampf((t - T_MIN) / (T_MAX - T_MIN), 0.0, 1.0)


func _draw() -> void:
	var w := size.x
	var bar_h := 14.0
	var y := 18.0
	# Track with band zones.
	draw_rect(Rect2(0, y, w, bar_h), Color("2e332c"))
	draw_rect(Rect2(_frac(1.5) * w, y, (_frac(2.0) - _frac(1.5)) * w, bar_h), Color("5c4a26"))
	draw_rect(Rect2(_frac(2.0) * w, y, (1.0 - _frac(2.0)) * w, bar_h), Color("5c2a26"))
	# Fill to current temperature.
	var fill_color := [Color("7fae5c"), Color("d9a441"), Color("c4552e")][band] as Color
	draw_rect(Rect2(0, y + 2, _frac(temp) * w, bar_h - 4), fill_color)
	# Threshold ticks.
	for t in [1.5, 2.0]:
		var x := _frac(t) * w
		draw_rect(Rect2(x - 1, y - 4, 2, bar_h + 8), Color("f2f7e8"))
	# Labels.
	var font := get_theme_default_font()
	draw_string(font, Vector2(_frac(1.5) * w - 14, y - 6), "1.5", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("d8d8d0"))
	draw_string(font, Vector2(_frac(2.0) * w - 14, y - 6), "2.0", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("d8d8d0"))
	var label := "+%.2f C" % temp
	if band > 0:
		label += "  OVERSHOOT" + (" II" if band == 2 else "")
	draw_string(font, Vector2(4, y + bar_h + 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, fill_color.lightened(0.3))
