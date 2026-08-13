extends GutTest

var MainMenuScene = preload("res://scenes/ui/main_menu.tscn")
var TileMapScene = preload("res://scenes/tileMap.tscn")
var menu = null


func before_each():
	GameSession.clear_match_config()
	menu = MainMenuScene.instantiate()
	add_child_autofree(menu)


func after_each():
	GameSession.clear_match_config()


func test_menu_exposes_required_options():
	assert_eq(menu.start_button.text, "Start Game")
	assert_eq(menu.rules_button.text, "Rules")
	assert_eq(menu.quit_button.text, "Quit")


func test_two_and_three_player_configs_preserve_seed():
	assert_eq(menu.build_match_config(2, "12345", 99), {"player_count": 2, "seed": 12345})
	assert_eq(menu.build_match_config(3, "67890", 99), {"player_count": 3, "seed": 67890})


func test_blank_seed_uses_resolved_random_fallback():
	assert_eq(menu.build_match_config(2, "", 24680), {"player_count": 2, "seed": 24680})


func test_explicit_zero_seed_is_preserved():
	assert_eq(menu.build_match_config(2, "0", 24680), {"player_count": 2, "seed": 0})


func test_setup_submission_emits_and_stores_match_config():
	watch_signals(menu)
	menu.player_count_option.select(1)
	menu.seed_input.text = "13579"
	var config: Dictionary = menu.submit_setup(false)
	assert_eq(config, {"player_count": 3, "seed": 13579})
	assert_eq(GameSession.match_config, config)
	assert_signal_emitted_with_parameters(menu, "match_config_created", [config])


func test_gameplay_tile_map_consumes_session_config_on_ready():
	GameSession.set_match_config({"player_count": 3, "seed": 13579})
	var tile_map = TileMapScene.instantiate()
	add_child_autofree(tile_map)
	assert_eq(tile_map.player_count, 3)
	assert_eq(tile_map.map_seed, 13579)
	assert_eq(tile_map.deployment_zones_data.size(), 3)


func test_zero_seed_is_applied_by_gameplay_map():
	GameSession.set_match_config({"player_count": 2, "seed": 0})
	var tile_map = TileMapScene.instantiate()
	add_child_autofree(tile_map)
	assert_eq(tile_map.map_seed, 0)
	assert_eq(tile_map.map_rng.seed, 0)


func test_equal_seeds_generate_identical_complete_maps():
	GameSession.set_match_config({"player_count": 2, "seed": 424242})
	var first_map = TileMapScene.instantiate()
	add_child_autofree(first_map)
	var first_snapshot := _terrain_snapshot(first_map)

	var second_map = TileMapScene.instantiate()
	add_child_autofree(second_map)
	var second_snapshot := _terrain_snapshot(second_map)
	assert_eq(second_snapshot, first_snapshot, "equal seeds reproduce the complete repaired terrain map")


func _terrain_snapshot(tile_map) -> Array[String]:
	var coordinates: Array = tile_map.terrain_data_map.keys()
	coordinates.sort_custom(func(a: Vector2i, b: Vector2i):
		return a.x < b.x or (a.x == b.x and a.y < b.y)
	)
	var snapshot: Array[String] = []
	for coordinate in coordinates:
		var terrain: TerrainType = tile_map.terrain_data_map[coordinate]
		snapshot.append("%d,%d:%s" % [coordinate.x, coordinate.y, terrain.terrain_name])
	return snapshot


func test_only_one_popup_can_be_open():
	menu.open_setup_dialog()
	assert_eq(menu.get_open_popup_count(), 1)
	menu.open_rules_dialog()
	assert_eq(menu.get_open_popup_count(), 1)
	assert_false(menu.setup_dialog.visible)
	assert_true(menu.rules_dialog.visible)


func test_escape_closes_rules_without_quitting():
	menu.open_rules_dialog()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	menu._unhandled_key_input(escape)
	assert_false(menu.rules_dialog.visible)
	assert_true(menu.is_inside_tree(), "escape closes rules without exiting the scene tree")


func test_rules_summary_is_scrollable_and_covers_required_sections():
	var scroll = menu.get_node("RulesDialog/RulesScroll")
	var text: String = menu.get_node("RulesDialog/RulesScroll/RulesText").text
	assert_true(scroll is ScrollContainer)
	for section in [
		"Start and Deployment",
		"Controls",
		"Turn Phases",
		"Movement and Engagement",
		"Combat",
		"Objective",
		"Victory",
		"Essence",
	]:
		assert_true(text.contains(section), "rules include %s" % section)
	assert_true(text.contains("Each unit may attack once per turn"))
	assert_true(text.contains("Opponents' turns do not charge upkeep or advance it"))
