extends GutTest

# Placeholder test file asserting future deploy_ signal declarations.
# These will fail until radial_menu.gd (or controlling script) declares signals.

var TileMapScript = preload("res://scripts/tile_map.gd")
var tile_map_instance = null

func before_each():
	tile_map_instance = TileMapScript.new()

func after_each():
	if tile_map_instance:
		tile_map_instance.free()
		tile_map_instance = null

func test_declares_deploy_signals():
	var expected = [
		"deploy_tile_clicked",
		"deploy_radial_opened",
		"deploy_unit_hovered",
		"deploy_unit_selected",
		"deploy_placement_failed",
		"deploy_radial_closed"
	]
	for s in expected:
		assert_has_signal(tile_map_instance, s, "Expected signal '%s' not declared" % s)
