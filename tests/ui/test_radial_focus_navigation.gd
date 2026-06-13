extends GutTest

# Focus & angular navigation for the radial menu (T019-T022).

var RadialScene = preload("res://scenes/ui/radial_menu.tscn")
var menu = null

func _units(costs: Array) -> Array:
	var arr := []
	for i in range(costs.size()):
		arr.append({
			"unit_id": "u%d" % i,
			"unit_name": "Unit %d" % i,
			"unit_cost": costs[i],
			"affordable": true,
			"stats_block": {},
			"abilities": "",
		})
	return arr

func before_each():
	menu = RadialScene.instantiate()
	menu.size = Vector2(400, 400)
	add_child_autofree(menu)

func test_focus_cycles_forward():
	menu.open(Vector2i(0, 0), _units([3, 1, 2]))
	var start = menu.focus_index
	menu.focus_next()
	assert_eq(menu.focus_index, (start + 1) % 3, "focus_next advances cyclically")

func test_focus_cycles_backward():
	menu.open(Vector2i(0, 0), _units([3, 1, 2]))
	menu.focus_index = 0
	menu.focus_previous()
	assert_eq(menu.focus_index, 2, "focus_previous wraps to last icon")

func test_focus_sets_from_angle():
	# 4 units => icons at angles 0, PI/2, PI, 3PI/2.
	menu.open(Vector2i(0, 0), _units([1, 1, 1, 1]))
	menu.set_focus_from_angle(PI / 2.0)
	assert_eq(menu.focus_index, 1, "angle ~PI/2 selects second icon")

func test_initial_focus_is_lowest_cost():
	menu.open(Vector2i(0, 0), _units([5, 2, 8]))
	assert_eq(menu.focus_index, 1, "initial focus lands on lowest-cost unit")

func test_mouse_exit_emits_unhovered_in_deploy_mode():
	menu.open(Vector2i(0, 0), _units([1, 2]))
	watch_signals(menu)
	menu._on_icon_unhovered()
	assert_signal_emitted(menu, "deploy_unit_unhovered",
		"leaving a unit icon clears the deploy preview")
