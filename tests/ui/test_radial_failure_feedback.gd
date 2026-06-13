extends GutTest

# Placement failure precedence & feedback signals (T024-T025).

var RadialScene = preload("res://scenes/ui/radial_menu.tscn")
var menu = null

func _unit(cost: int) -> Dictionary:
	return {
		"unit_id": "u0",
		"unit_name": "Unit 0",
		"unit_cost": cost,
		"affordable": true,
		"stats_block": {},
		"abilities": "",
	}

func before_each():
	menu = RadialScene.instantiate()
	menu.size = Vector2(400, 400)
	add_child_autofree(menu)
	menu.open(Vector2i(2, 2), [_unit(5)])

func test_feedback_for_insufficient_resources():
	watch_signals(menu)
	var res = menu.attempt_placement(menu.all_units[0], {
		"resources": 1, "tile_valid": true, "tile_occupied": false, "now_ms": 1000,
	})
	assert_false(res.success, "placement fails when unaffordable")
	assert_eq(res.reason, "insufficient_resources")
	assert_signal_emitted_with_parameters(menu, "deploy_placement_failed",
		["insufficient_resources", Vector2i(2, 2), "u0"])

func test_feedback_for_occupied_tile():
	watch_signals(menu)
	var res = menu.attempt_placement(menu.all_units[0], {
		"resources": 10, "tile_valid": true, "tile_occupied": true, "now_ms": 1000,
	})
	assert_eq(res.reason, "tile_occupied", "occupied tile rejected after affordability")
	assert_signal_emitted_with_parameters(menu, "deploy_placement_failed",
		["tile_occupied", Vector2i(2, 2), "u0"])

func test_feedback_for_invalid_tile():
	watch_signals(menu)
	var res = menu.attempt_placement(menu.all_units[0], {
		"resources": 10, "tile_valid": false, "tile_occupied": false, "now_ms": 1000,
	})
	assert_eq(res.reason, "invalid_tile", "invalid tile rejected")
	assert_signal_emitted_with_parameters(menu, "deploy_placement_failed",
		["invalid_tile", Vector2i(2, 2), "u0"])

func test_resources_take_precedence_over_tile():
	# Both unaffordable and occupied: resource failure wins (data-model precedence).
	var res = menu.attempt_placement(menu.all_units[0], {
		"resources": 1, "tile_valid": false, "tile_occupied": true, "now_ms": 1000,
	})
	assert_eq(res.reason, "insufficient_resources", "resources outrank tile state")
