extends GutTest

# Pagination behaviour for the radial menu (T028).

var RadialScene = preload("res://scenes/ui/radial_menu.tscn")
var menu = null

func _units_count(n: int) -> Array:
	var arr := []
	for i in range(n):
		arr.append({
			"unit_id": "u%d" % i,
			"unit_name": "Unit %d" % i,
			"unit_cost": 1,
			"affordable": true,
			"stats_block": {},
			"abilities": "",
		})
	return arr

func before_each():
	menu = RadialScene.instantiate()
	menu.size = Vector2(400, 400)
	add_child_autofree(menu)

func test_pagination_controls_hidden_with_few_units():
	menu.open(Vector2i(0, 0), _units_count(5))
	assert_false(menu.has_pagination(), "no pagination with <= 12 units")
	assert_null(menu.get_node_or_null("NextPageButton"), "next button absent")

func test_pagination_controls_visible_with_many_units():
	menu.open(Vector2i(0, 0), _units_count(20))
	assert_true(menu.has_pagination(), "pagination active with > 12 units")
	assert_not_null(menu.get_node_or_null("NextPageButton"), "next button present")
	assert_not_null(menu.get_node_or_null("PrevPageButton"), "prev button present")

func test_pagination_next_changes_page():
	menu.open(Vector2i(0, 0), _units_count(20))
	assert_eq(menu.page_index, 0, "starts on first page")
	menu.next_page()
	assert_eq(menu.page_index, 1, "advances to second page")
	assert_eq(menu.visible_units.size(), 8, "second page holds remaining 8 units")

func test_pagination_previous_changes_page():
	menu.open(Vector2i(0, 0), _units_count(20))
	menu.prev_page()
	assert_eq(menu.page_index, 1, "prev wraps from first to last page")

func test_pagination_next_wraps_around_and_resets_focus():
	# 20 units => 2 pages. next from last page wraps to first (T039).
	menu.open(Vector2i(0, 0), _units_count(20))
	menu.focus_index = 5
	menu.next_page()
	assert_eq(menu.page_index, 1, "advanced to last page")
	assert_eq(menu.focus_index, 0, "focus resets on page change")
	menu.next_page()
	assert_eq(menu.page_index, 0, "wraps back to first page")
	assert_eq(menu.visible_units.size(), 12, "first page is full")
