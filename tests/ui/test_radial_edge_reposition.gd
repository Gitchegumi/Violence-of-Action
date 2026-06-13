extends GutTest

# Edge repositioning keeps the full icon ring visible near viewport edges (T029).

var RadialScene = preload("res://scenes/ui/radial_menu.tscn")
var menu = null
const MARGIN := 140.0  # RADIUS (80) + ICON_SIZE.x (60)

func before_each():
	menu = RadialScene.instantiate()
	menu.size = Vector2(400, 400)
	add_child_autofree(menu)
	menu.open(Vector2i(0, 0), [])

func test_radial_menu_repositions_when_near_right_edge():
	var vp := Vector2(800, 600)
	menu.position = Vector2(790, 300)
	menu.reposition_within_viewport(vp)
	assert_almost_eq(menu.position.x, vp.x - MARGIN, 0.5, "clamped inward from right edge")

func test_radial_menu_repositions_when_near_left_edge():
	menu.position = Vector2(5, 300)
	menu.reposition_within_viewport(Vector2(800, 600))
	assert_almost_eq(menu.position.x, MARGIN, 0.5, "clamped inward from left edge")

func test_radial_menu_repositions_when_near_top_edge():
	menu.position = Vector2(300, 5)
	menu.reposition_within_viewport(Vector2(800, 600))
	assert_almost_eq(menu.position.y, MARGIN, 0.5, "clamped inward from top edge")

func test_radial_menu_repositions_when_near_bottom_edge():
	var vp := Vector2(800, 600)
	menu.position = Vector2(300, 590)
	menu.reposition_within_viewport(vp)
	assert_almost_eq(menu.position.y, vp.y - MARGIN, 0.5, "clamped inward from bottom edge")
