class_name BoardView
extends Node2D
## Tier A dashboard board: 12 RegionPanels at data/board_layout.json slots,
## era tint via CanvasModulate, event flashes. Renders state, owns nothing.

signal region_clicked(region_id: StringName)
signal region_hovered(region_id: StringName)

const LAYOUT_PATH := "res://data/board_layout.json"
const ERA_SMOG := Color("8f8f87")
const ERA_MID := Color("d8d8d0")
const ERA_BRIGHT := Color("f2f7e8")

var panels: Dictionary = {}  # StringName -> RegionPanel
var _era: CanvasModulate
var _ground: ColorRect
var _layout: Dictionary = {}


func _ready() -> void:
	_layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	_ground = ColorRect.new()
	_ground.color = Color("575c55")
	_ground.size = Vector2(1920, 1080)
	_ground.z_index = -10
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ground)
	_era = CanvasModulate.new()
	_era.color = ERA_MID
	add_child(_era)
	for slot: Dictionary in _layout["slots"]:
		var panel := RegionPanel.new()
		var pos: Dictionary = slot["pos"]
		var psize: Dictionary = _layout["panel_size"]
		# panel_origin: "center" - position is the panel center.
		panel.position = Vector2(float(pos["x"]) - float(psize["w"]) / 2.0,
			float(pos["y"]) - float(psize["h"]) / 2.0)
		panel.name = String(slot["region_id"])
		add_child(panel)
		panels[StringName(String(slot["region_id"]))] = panel
		panel.panel_clicked.connect(func(id: StringName) -> void: region_clicked.emit(id))
		panel.panel_hovered.connect(func(id: StringName) -> void: region_hovered.emit(id))


func bind_world(rs: RunState) -> void:
	for r in rs.world:
		if panels.has(r.id):
			panels[r.id].bind_region(r)
	refresh(rs)


func refresh(rs: RunState) -> void:
	for id in panels:
		panels[id].refresh(rs)
	set_era(rs.avg_progress() / 100.0)


## The grey-to-solarpunk arc, delivered through color (Risk #9 mitigation).
func set_era(progress: float) -> void:
	var target := ERA_SMOG.lerp(ERA_MID, clampf(progress * 2.0, 0.0, 1.0)) \
		if progress < 0.5 else ERA_MID.lerp(ERA_BRIGHT, clampf((progress - 0.5) * 2.0, 0.0, 1.0))
	var tween := create_tween()
	tween.tween_property(_era, "color", target, 0.4)


func flash_event(region_id: StringName, opportunity: StringName) -> void:
	if not panels.has(region_id):
		return
	var panel: RegionPanel = panels[region_id]
	panel.flash(Color(1.0, 0.45, 0.35))  # damage first...
	if opportunity != &"":
		get_tree().create_timer(0.35).timeout.connect(func() -> void:
			if is_instance_valid(panel):
				panel.flash(Color(0.55, 1.0, 0.55)))  # ...opportunity second


func set_selection(region_id: StringName) -> void:
	for id in panels:
		panels[id].set_selected(id == region_id)


func set_target_highlights(ids: Array) -> void:
	for id in panels:
		panels[id].set_highlighted(ids.has(id))
