extends GutTest

var TileMapScript = preload("res://scripts/tile_map.gd")
var tile_map_instance = null

func before_each():
	tile_map_instance = TileMapScript.new()

func after_each():
	if tile_map_instance:
		tile_map_instance.free()
		tile_map_instance = null

func test_tile_map_declares_unit_selected_signal():
	# This test will fail because the signal 'unit_selected' does not exist yet in tile_map.gd.
	# It asserts the declaration of the signal.
	assert_has_signal(tile_map_instance, "unit_selected", "TileMap script should declare 'unit_selected' signal")
