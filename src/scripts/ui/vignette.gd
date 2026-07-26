class_name Vignette
extends Control
## Overshoot vignette: screen-edge tint by warming band (amber I, red II).
## It is weather, not an alarm screen - the board stays readable underneath.

var _edges: Array[ColorRect] = []
var _current := Color(0, 0, 0, 0)

const EDGE := 56.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 4:
		var rect := ColorRect.new()
		rect.color = Color(0, 0, 0, 0)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_edges.append(rect)
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	if _edges.size() < 4:
		return
	_edges[0].position = Vector2.ZERO
	_edges[0].size = Vector2(size.x, EDGE)
	_edges[1].position = Vector2(0, size.y - EDGE)
	_edges[1].size = Vector2(size.x, EDGE)
	_edges[2].position = Vector2(0, 0)
	_edges[2].size = Vector2(EDGE, size.y)
	_edges[3].position = Vector2(size.x - EDGE, 0)
	_edges[3].size = Vector2(EDGE, size.y)


func set_band(band: int) -> void:
	var target := Color(0, 0, 0, 0)
	match band:
		1: target = Color(0.85, 0.64, 0.25, 0.16)  # amber
		2: target = Color(0.77, 0.33, 0.18, 0.24)  # red
	_current = target
	for rect in _edges:
		var tween := create_tween()
		tween.tween_property(rect, "color", target, 0.8)
