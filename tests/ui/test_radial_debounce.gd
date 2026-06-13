extends GutTest

# Rapid double-placement is debounced (T026).

var RadialScene = preload("res://scenes/ui/radial_menu.tscn")
var menu = null

func before_each():
	menu = RadialScene.instantiate()
	menu.size = Vector2(400, 400)
	add_child_autofree(menu)
	menu.open(Vector2i(0, 0), [{
		"unit_id": "u0", "unit_name": "Unit 0", "unit_cost": 1,
		"affordable": true, "stats_block": {}, "abilities": "",
	}])

func _ctx(now_ms: int) -> Dictionary:
	return {"resources": 10, "tile_valid": true, "tile_occupied": false, "now_ms": now_ms}

func test_rapid_placement_is_debounced():
	var unit = menu.all_units[0]

	var first = menu.attempt_placement(unit, _ctx(1000))
	assert_true(first.success, "first placement succeeds")

	var rapid = menu.attempt_placement(unit, _ctx(1100))  # 100ms later (< 250ms)
	assert_false(rapid.success, "second placement within window is blocked")
	assert_eq(rapid.reason, "debounced")

	var later = menu.attempt_placement(unit, _ctx(1400))  # 400ms after first
	assert_true(later.success, "placement after debounce window succeeds")
