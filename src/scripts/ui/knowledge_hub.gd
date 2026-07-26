class_name KnowledgeHub
extends PanelContainer
## The Knowledge tree (meta-progression): spend Knowledge Points on nodes that
## persist across runs. Each node is one explainable insight (pillar 4).
## Unlocks apply from the NEXT run (docs/Phase_4/02: never mid-run).

signal closed

var _kp_label: Label
var _nodes_box: VBoxContainer
var _catalog: Catalog


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1a1e18", 0.97)
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = Color("79a94a")
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	add_theme_stylebox_override("panel", style)
	anchor_left = 0.24
	anchor_right = 0.76
	anchor_top = 0.12
	anchor_bottom = 0.88
	visible = false

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	var title := Label.new()
	title.text = "KNOWLEDGE  -  what every timeline taught us"
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("cfe8b8"))
	vbox.add_child(title)
	_kp_label = Label.new()
	_kp_label.add_theme_font_size_override("font_size", 14)
	_kp_label.add_theme_color_override("font_color", Color("e8d48a"))
	vbox.add_child(_kp_label)
	var note := Label.new()
	note.text = "Unlocks apply from the next timeline. H closes this panel."
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color("9aa694"))
	vbox.add_child(note)
	_nodes_box = VBoxContainer.new()
	_nodes_box.add_theme_constant_override("separation", 6)
	_nodes_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_nodes_box)
	var close := Button.new()
	close.text = "Close (H)"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func() -> void: closed.emit())
	vbox.add_child(close)


func open(catalog: Catalog) -> void:
	_catalog = catalog
	_rebuild()
	visible = true


func _rebuild() -> void:
	for child in _nodes_box.get_children():
		child.queue_free()
	_kp_label.text = "Knowledge Points available: %d" % Meta.kp_total
	for node: Dictionary in _catalog.knowledge:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_nodes_box.add_child(row)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(150, 0)
		btn.focus_mode = Control.FOCUS_NONE
		var unlocked := Meta.is_unlocked(String(node["id"]))
		if unlocked:
			btn.text = "UNLOCKED"
			btn.disabled = true
		else:
			btn.text = "Unlock (%d KP)" % int(node["kp_cost"])
			btn.disabled = not Meta.can_unlock(node)
			var n := node
			btn.pressed.connect(func() -> void:
				Meta.unlock(n)
				_rebuild())
		row.add_child(btn)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var name_label := Label.new()
		name_label.text = String(node["name"])
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color",
			Color("cfe8b8") if unlocked else Color("d8d8d0"))
		text.add_child(name_label)
		var insight := Label.new()
		insight.text = String(node["insight"])
		insight.add_theme_font_size_override("font_size", 11)
		insight.add_theme_color_override("font_color", Color("9aa694"))
		insight.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(insight)
