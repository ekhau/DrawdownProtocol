extends SceneTree
## Throwaway visual-check driver (not part of the suite): boots the real UI,
## buys two cut cards, and saves before/after screenshots of the window.
##   godot -s res://tests/screenshot_driver.gd -- /absolute/output/dir

var frames := 0
var out_dir := "/tmp"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	process_frame.connect(_tick)


func _tick() -> void:
	frames += 1
	if frames == 2:
		root.add_child((load("res://scenes/main.tscn") as PackedScene).instantiate())
	elif frames == 25:
		# The launch intro and act card cover the top bar — dismiss both for a clean shot.
		var ui := root.get_node("Main")
		ui.overlay.visible = false
		ui.era_modal.visible = false
	elif frames == 30:
		root.get_texture().get_image().save_png(out_dir + "/before.png")
		# Deterministic pokes through the sim (market offer is seed-dependent):
		# two permanent cuts + one absorption gain, then repaint via signals.
		var game := root.get_node("/root/Game")
		game.sim.state.add_sector_emissions("housing", -1)
		game.sim.state.add_sector_emissions("transport", -1)
		game.sim.state.add_absorption(1)
	elif frames == 90:
		root.get_texture().get_image().save_png(out_dir + "/after.png")
		quit()
