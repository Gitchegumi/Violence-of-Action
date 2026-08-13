extends GutTest

var TileMapScript = preload("res://scripts/tile_map.gd")
var TileMapScene = preload("res://scenes/tileMap.tscn")


func test_edge_scroll_direction_matches_viewport_edges():
	var viewport := Vector2(800, 600)
	assert_eq(TileMapScript.get_edge_scroll_direction(Vector2(10, 300), viewport, 24.0), Vector2.LEFT)
	assert_eq(TileMapScript.get_edge_scroll_direction(Vector2(790, 300), viewport, 24.0), Vector2.RIGHT)
	assert_eq(TileMapScript.get_edge_scroll_direction(Vector2(400, 10), viewport, 24.0), Vector2.UP)
	assert_eq(TileMapScript.get_edge_scroll_direction(Vector2(400, 590), viewport, 24.0), Vector2.DOWN)


func test_edge_scroll_direction_is_zero_away_from_edges():
	assert_eq(
		TileMapScript.get_edge_scroll_direction(Vector2(400, 300), Vector2(800, 600), 24.0),
		Vector2.ZERO
	)


func test_edge_scroll_direction_ignores_mouse_outside_viewport():
	assert_eq(
		TileMapScript.get_edge_scroll_direction(Vector2(-1, 300), Vector2(800, 600), 24.0),
		Vector2.ZERO
	)


func test_camera_position_clamps_to_visible_world_bounds():
	var bounds := Rect2(0, 0, 1000, 800)
	var viewport := Vector2(400, 200)
	assert_eq(
		TileMapScript.get_clamped_camera_position(Vector2(-100, -100), bounds, viewport, 1.0),
		Vector2(200, 100)
	)
	assert_eq(
		TileMapScript.get_clamped_camera_position(Vector2(1200, 900), bounds, viewport, 1.0),
		Vector2(800, 700)
	)


func test_camera_clamp_accounts_for_zoom():
	var bounds := Rect2(0, 0, 1000, 800)
	var viewport := Vector2(400, 200)
	assert_eq(
		TileMapScript.get_clamped_camera_position(Vector2.ZERO, bounds, viewport, 2.0),
		Vector2(100, 50)
	)


func test_small_map_stays_centered_when_viewport_is_larger():
	assert_eq(
		TileMapScript.get_clamped_camera_position(
			Vector2(999, 999),
			Rect2(100, 200, 200, 100),
			Vector2(800, 600),
			1.0
		),
		Vector2(200, 250)
	)


func test_objective_tile_uses_production_recenter_path():
	var tile_map = TileMapScene.instantiate()
	add_child_autofree(tile_map)
	var objective := Vector2i(6, 7)
	assert_true(tile_map.terrain_data_map.has(objective), "objective is a playable coordinate")

	tile_map.camera.position = Vector2(-10_000, -10_000)
	tile_map.center_camera_on_tile(objective)
	var expected := TileMapScript.get_clamped_camera_position(
		tile_map.map_to_local(objective),
		tile_map.camera_bounds,
		tile_map.get_viewport_rect().size,
		tile_map.camera.zoom.x
	)
	assert_eq(tile_map.camera.position, expected, "objective tile recenters the camera")
