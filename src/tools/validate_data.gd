extends SceneTree
## Headless CI gate for the content catalogs:
##   godot --headless --path src --script res://tools/validate_data.gd
## Exits non-zero on any Error (warnings are reported but pass).


func _initialize() -> void:
	var v := DataValidator.load_and_validate()
	print(v.report())
	quit(0 if v.ok() else 1)
