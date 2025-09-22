extends GutTest

# Test for radial unit info panel (part of radial menu system)

var RadialUnitInfoPanelScene = preload("res://scenes/ui/radial_unit_info_panel.tscn")
var panel_instance = null

func before_each():
	panel_instance = RadialUnitInfoPanelScene.instantiate()
	add_child_autofree(panel_instance)

func after_each():
	if panel_instance:
		panel_instance.free()
		panel_instance = null

func test_radial_unit_info_panel_scene_exists():
	var exists = ResourceLoader.exists("res://scenes/ui/radial_unit_info_panel.tscn")
	assert_true(exists, "Radial unit info panel scene should exist")

func test_show_unit_makes_panel_visible():
	# Create mock unit with unit_data structure
	var MockUnit = load("res://tests/unit/mock_unit.gd")
	var mock_unit = MockUnit.new()
	mock_unit.name = "MockUnit"
	var mock_stats = {"health": 10, "attack": 2, "range": 1, "armor": 1, "speed": 3}
	mock_unit.unit_data = {"unit_name": "Test Unit", "unit_role": "Test Role", "unit_cost": 5, "stats_block": mock_stats}
	
	# Panel should start hidden
	assert_false(panel_instance.visible, "Panel should start hidden")
	
	# Show unit should make panel visible
	panel_instance.show_unit(mock_unit)
	assert_true(panel_instance.visible, "Unit info panel should be visible after show_unit()")

func test_hide_panel_makes_panel_invisible():
	# Set visible for testing hide functionality
	panel_instance.visible = true
	assert_true(panel_instance.visible, "Panel should be visible before hide test")
	
	# Hide should make panel invisible
	panel_instance.hide_panel()
	assert_false(panel_instance.visible, "Unit info panel should be invisible after hide_panel()")

func test_panel_has_required_methods():
	assert_true(panel_instance.has_method("show_unit"), "Panel should have show_unit method")
	assert_true(panel_instance.has_method("hide_panel"), "Panel should have hide_panel method")
	assert_true(panel_instance.has_method("is_panel_visible"), "Panel should have is_panel_visible method")