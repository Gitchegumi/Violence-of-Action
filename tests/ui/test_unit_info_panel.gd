extends GutTest

var UnitInfoPanelScene = preload("res://scenes/ui/unit_info_panel.tscn")
var unit_info_panel_instance = null

func before_each():
	unit_info_panel_instance = UnitInfoPanelScene.instantiate()
	add_child_autofree(unit_info_panel_instance)

func after_each():
	unit_info_panel_instance = null

func test_show_unit_makes_panel_visible():
	var MockUnit = load("res://tests/unit/mock_unit.gd")
	var mock_unit = MockUnit.new()
	add_child_autofree(mock_unit)
	mock_unit.name = "MockUnit"
	var mock_stats = {"health": 10, "attack": 2, "range": 1, "armor": 1, "speed": 3}
	mock_unit.unit_data = {"unit_name": "Test Unit", "unit_role": "Test Role", "unit_cost": 5, "stats_block": mock_stats}
	mock_unit.reset_turn_state()
	
	unit_info_panel_instance.show_unit(mock_unit)
	
	assert_true(unit_info_panel_instance.visible, "Unit info panel should be visible after show_unit()")
	assert_eq(unit_info_panel_instance.movement_label.text, "Movement: 3/3")
	assert_true(unit_info_panel_instance.movement_label.visible)

func test_hide_panel_makes_panel_invisible():
	unit_info_panel_instance.visible = true # Set visible for testing hide

	unit_info_panel_instance.hide_panel()

	assert_false(unit_info_panel_instance.visible, "Unit info panel should be invisible after hide_panel()")

func test_show_unit_type_binds_from_resource():
	# Deploy-hover preview: bind the big panel directly from a UnitType resource
	# (no placed unit node required).
	var data = load("res://assets/data/armies/TheCoreborn/tier-1/shard_walker.tres")
	unit_info_panel_instance.show_unit_type(data)
	assert_true(unit_info_panel_instance.visible, "panel visible after show_unit_type()")
	assert_true(unit_info_panel_instance.unit_name_label.text.contains("Shardwalker"),
		"name label shows the unit name")
	assert_true(unit_info_panel_instance.health_label.text.contains("3"),
		"health stat bound from the resource")
	assert_false(unit_info_panel_instance.movement_label.visible,
		"catalog previews do not display live movement state")

func test_refresh_current_unit_updates_remaining_movement():
	var MockUnit = load("res://tests/unit/mock_unit.gd")
	var mock_unit = MockUnit.new()
	add_child_autofree(mock_unit)
	mock_unit.unit_data = {
		"unit_name": "Test Unit",
		"unit_role": "Test Role",
		"unit_cost": 5,
		"stats_block": {"health": 3, "attack": 2, "range": 1, "armor": 1, "speed": 5},
	}
	mock_unit.reset_turn_state()
	unit_info_panel_instance.show_unit(mock_unit)
	mock_unit.movement_remaining = 2
	unit_info_panel_instance.refresh_current_unit()
	assert_eq(unit_info_panel_instance.movement_label.text, "Movement: 2/5")

func test_show_unit_type_with_null_hides():
	unit_info_panel_instance.visible = true
	unit_info_panel_instance.show_unit_type(null)
	assert_false(unit_info_panel_instance.visible, "null data hides the panel")
