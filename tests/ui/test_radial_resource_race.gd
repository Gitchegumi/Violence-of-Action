extends GutTest

# Affordability re-validation when resources change mid-session (T027).

var RadialScene = preload("res://scenes/ui/radial_menu.tscn")
var menu = null

func before_each():
	menu = RadialScene.instantiate()
	menu.size = Vector2(400, 400)
	add_child_autofree(menu)
	menu.open(Vector2i(0, 0), [{
		"unit_id": "exp", "unit_name": "Expensive", "unit_cost": 10,
		"affordable": true, "stats_block": {}, "abilities": "",
	}])

func test_unit_becomes_unaffordable_mid_session():
	assert_true(menu.all_units[0]["affordable"], "starts affordable")

	menu.revalidate_affordability(5)  # below the unit's cost of 10

	assert_false(menu.all_units[0]["affordable"], "flagged unaffordable after drop")
	var icon = menu.unit_icons[0]
	assert_true(icon.disabled, "icon disabled when no longer affordable")
