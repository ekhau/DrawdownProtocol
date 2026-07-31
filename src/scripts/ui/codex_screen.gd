class_name CodexScreen
extends PanelContainer
## The Codex of real climate solutions (C toggles it). Funding a card for the
## first time - in any run - unlocks its entry: two or three sentences on the
## real-world solution it represents, sources per docs/Concept.md. Undiscovered
## entries show as ??? so the codex is also a collection meter.

signal closed

var _list: RichTextLabel
var _count_label: Label
var _catalog: Catalog


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1a1e18", 0.97)
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = Color("8ac6c6")
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	add_theme_stylebox_override("panel", style)
	anchor_left = 0.22
	anchor_right = 0.78
	anchor_top = 0.10
	anchor_bottom = 0.90
	visible = false

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	var title := Label.new()
	title.text = "CODEX  -  the real solutions behind the cards"
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("aee0e0"))
	vbox.add_child(title)
	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 12)
	_count_label.add_theme_color_override("font_color", Color("e8d48a"))
	vbox.add_child(_count_label)
	_list = RichTextLabel.new()
	_list.bbcode_enabled = true
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_theme_font_size_override("normal_font_size", 12)
	vbox.add_child(_list)
	var close := Button.new()
	close.text = "Close (C)"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func() -> void: closed.emit())
	vbox.add_child(close)


func open(catalog: Catalog) -> void:
	_catalog = catalog
	_rebuild()
	visible = true


func _rebuild() -> void:
	var seen := 0
	var total := 0
	var lines: PackedStringArray = []
	for card: Dictionary in _catalog.cards:
		var codex: Dictionary = card.get("codex", {})
		if codex.is_empty():
			continue
		total += 1
		var id := String(card["id"])
		if Meta.codex_seen.has(id):
			seen += 1
			lines.append("[b][color=#cfe8b8]%s[/color][/b]  [color=#9aa694](%s)[/color]" % [
				String(codex.get("title", "")), String(card.get("name", id))])
			lines.append("[color=#d8d8d0]%s[/color]" % String(codex.get("body", "")))
		else:
			lines.append("[b][color=#6e746a]???[/color][/b]  [color=#4e544a](fund %s once to learn the real solution)[/color]" % String(card.get("name", id)))
		lines.append("")
	_count_label.text = "Solutions discovered: %d / %d  -  playing a card for the first time unlocks its entry, forever" % [seen, total]
	_list.text = "\n".join(lines)
