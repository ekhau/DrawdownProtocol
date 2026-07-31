class_name WarmingGauge
extends Control
## THE CLIMATE CLOCK - the adversary, as one legible gauge (design pillar 1).
## A 0-100% race track (100% = +2.0 C = the tipping point = defeat), the
## history of the curve the player is bending, and the projected next-turn
## rise. Reads RunState; never computes climate itself.

const BAND_COLORS := [Color("7fae5c"), Color("d9a441"), Color("c4552e")]

var clock := 30.0
var band := 0
var forecast := 0.0
var history: PackedFloat32Array = []      # clock % per resolved turn
var _flash := 0.0                          # 1 -> 0 plunge celebration


func _ready() -> void:
	custom_minimum_size = Vector2(380, 56)


func set_state(rs: RunState) -> void:
	clock = rs.clock_pct()
	band = rs.warming_band()
	forecast = rs.clock_forecast_pct()
	history = PackedFloat32Array()
	history.append(ClimateCalc.clock_pct(float(Tuning.c("T_START"))))
	for rec in rs.records:
		history.append(rec.clock_pct)
	tooltip_text = ("CLIMATE CLOCK: %.0f%% of the way to the tipping point\n" % clock) \
		+ ("(+%.2f C; 100%% = +2.0 C = defeat)\n" % rs.temp) \
		+ ("Projected next turn if you do nothing: %+.1f points\n" % forecast) \
		+ "The clock climbs on its own - the world's blocs keep emitting.\n" \
		+ "Bend the curve to net <= 0 before 100% and the run is WON."
	queue_redraw()


## Juice hook: the curve visibly plunges (win / big drawdown moment).
func flash_plunge() -> void:
	_flash = 1.0
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		_flash = v
		queue_redraw(), 1.0, 0.0, 1.2)


func _draw() -> void:
	var w := size.x
	var bar_h := 13.0
	var y := 14.0
	var font := get_theme_default_font()
	# Header: the adversary's name and the numbers that matter.
	var head_color: Color = BAND_COLORS[band].lightened(0.25)
	if _flash > 0.0:
		head_color = head_color.lerp(Color("b8ffb0"), _flash)
	draw_string(font, Vector2(0, 10), "CLIMATE CLOCK  %.0f%%" % clock,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, head_color)
	var fc_text := "next: %+.1f" % forecast
	var fc_color := Color("e0a080") if forecast > 0.05 else Color("a0d890")
	draw_string(font, Vector2(w - 90, 10), fc_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, fc_color)
	# The race track: 0..100%, warning zone from 50% (+1.5 C), red past 75%.
	draw_rect(Rect2(0, y, w, bar_h), Color("2e332c"))
	draw_rect(Rect2(0.50 * w, y, 0.25 * w, bar_h), Color("5c4a26"))
	draw_rect(Rect2(0.75 * w, y, 0.25 * w, bar_h), Color("5c2a26"))
	var fill_color: Color = BAND_COLORS[band]
	if _flash > 0.0:
		fill_color = fill_color.lerp(Color("9fe88a"), _flash)
	draw_rect(Rect2(0, y + 2, clock / 100.0 * w, bar_h - 4), fill_color)
	# Projection tick: where the clock lands next turn, hands off.
	var proj := clampf(clock + forecast, 0.0, 100.0)
	draw_rect(Rect2(proj / 100.0 * w - 1, y, 2, bar_h), Color("f2f7e8", 0.65))
	# Threshold ticks: +1.5 C (50%) and the tipping point (100%).
	for frac in [0.5, 1.0]:
		var x: float = float(frac) * w - 1.0
		draw_rect(Rect2(x - 1, y - 3, 2, bar_h + 6), Color("f2f7e8"))
	draw_string(font, Vector2(0.5 * w - 12, y + bar_h + 11), "+1.5",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d8d8d0"))
	draw_string(font, Vector2(w - 34, y + bar_h + 11), "TIP",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e0a080"))
	# The curve so far: a sparkline of every resolved turn (the arc to bend).
	if history.size() >= 2:
		var sx := 40.0
		var sw := w - 120.0
		var sy := y + bar_h + 4.0
		var sh := 10.0
		var points: PackedVector2Array = []
		for i in history.size():
			points.append(Vector2(
				sx + sw * float(i) / float(maxi(1, history.size() - 1)),
				sy + sh * (1.0 - clampf(history[i], 0.0, 100.0) / 100.0)))
		draw_polyline(points, fill_color.lightened(0.2), 1.4)
