extends GutTest

var UnitInfoPanelScene = preload("res://scenes/ui/unit_info_panel.tscn")
var unit_info_panel_instance = null

func before_each():
	# This will fail because the scene does not exist yet
	unit_info_panel_instance = UnitInfoPanelScene.instantiate()
	add_child_autofree(unit_info_panel_instance)

func after_each():
	if unit_info_panel_instance:
		unit_info_panel_instance.free()
		unit_info_panel_instance = null

func test_show_unit_makes_panel_visible():
	# This test will fail because the scene and script are not implemented yet.
	# It assumes the panel has a 'visible' property or similar.
	# We will pass a mock unit for now.
	var MockUnit = load("res://tests/unit/mock_unit.gd")
	var mock_unit = MockUnit.new()
	mock_unit.name = "MockUnit"
	var mock_stats = {"health": 10, "attack": 2, "range": 1, "armor": 1, "speed": 3}
	mock_unit.unit_data = {"unit_name": "Test Unit", "unit_role": "Test Role", "unit_cost": 5, "stats_block": mock_stats}
	
	# This call will fail because show_unit() is not implemented
	unit_info_panel_instance.show_unit(mock_unit)
	
	assert_true(unit_info_panel_instance.visible, "Unit info panel should be visible after show_unit()")

func test_hide_panel_makes_panel_invisible():
	# This test will fail because the scene and script are not implemented yet.
	unit_info_panel_instance.visible = true # Set visible for testing hide
	
	# This call will fail because hide_panel() is not implemented
	unit_info_panel_instance.hide_panel()
	
	assert_false(unit_info_panel_instance.visible, "Unit info panel should be invisible after hide_panel()")
