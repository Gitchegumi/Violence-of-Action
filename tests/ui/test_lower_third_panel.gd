extends GutTest

var MainScene = preload("res://scenes/main.tscn")


func before_each() -> void:
	get_tree().paused = false
	GameState.begin_match({"player_count": 2, "seed": 982451653})


func after_each() -> void:
	get_tree().paused = false
	GameSession.clear_match_config()
	GameState.return_to_menu()
	GameState.active_player_id = 0


func _main_scene():
	var main = MainScene.instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	return main


func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event


func test_lower_third_is_one_screen_space_panel_with_three_regions() -> void:
	var main = await _main_scene()
	var canvas: CanvasLayer = main.get_node("HUDCanvasLayer")
	var panel: Control = canvas.get_node("LowerThirdPanel")
	assert_true(panel.visible)
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(panel.anchor_left, 0.0)
	assert_eq(panel.anchor_right, 1.0)
	assert_eq(panel.anchor_top, 1.0)
	assert_eq(panel.anchor_bottom, 1.0)
	assert_not_null(panel.get_node("Margin/Regions/TerrainRegion"))
	assert_not_null(panel.get_node("Margin/Regions/UnitCombatRegion"))
	assert_not_null(panel.get_node("Margin/Regions/MatchRegion"))

	assert_false(main.get_node("EssenceLabel").visible)
	assert_false(main.get_node("TurnLabel").visible)
	assert_false(main.get_node("ObjectiveLabel").visible)
	assert_false(main.get_node("CombatResultLabel").visible)
	assert_false(main.get_node("UnitInfoPanel").visible)


func test_cursor_focus_updates_terrain_and_clears_stale_unit_without_activation() -> void:
	var main = await _main_scene()
	var tile_map = main.get_node("TileMapLayer")
	var panel = main.get_node("HUDCanvasLayer/LowerThirdPanel")
	var occupied: Vector2i = tile_map.deployment_zones_data[0][0]
	var empty: Vector2i = tile_map._get_neighbors(occupied).filter(
		func(coord: Vector2i): return tile_map.terrain_data_map.has(coord)
	)[0]

	tile_map.troop_manager.set_current_unit("shard_walker")
	assert_true(tile_map.troop_manager.place_unit(occupied, 0))
	tile_map.set_selected_tile(occupied)
	assert_true(panel.unit_name_label.text.contains("Shardwalker"))
	assert_true(panel.movement_label.visible)
	assert_true(panel.terrain_name_label.text.contains(
		tile_map.terrain_data_map[occupied].terrain_name
	))

	tile_map.set_selected_tile(empty)
	assert_eq(panel.unit_name_label.text, "Unit: Empty")
	assert_false(panel.movement_label.visible)
	assert_true(panel.terrain_name_label.text.contains(
		tile_map.terrain_data_map[empty].terrain_name
	))


func test_focused_live_unit_refreshes_without_reselection() -> void:
	var main = await _main_scene()
	var tile_map = main.get_node("TileMapLayer")
	var panel = main.get_node("HUDCanvasLayer/LowerThirdPanel")
	var occupied: Vector2i = tile_map.deployment_zones_data[0][0]
	tile_map.troop_manager.set_current_unit("shard_walker")
	assert_true(tile_map.troop_manager.place_unit(occupied, 0))
	var unit = tile_map.troop_manager.get_unit_at_map_coord(occupied)
	tile_map.set_selected_tile(occupied)

	unit.current_hp -= 1
	unit.movement_remaining -= 1
	tile_map.unit_moved.emit(unit, [], 1, unit.movement_remaining)
	assert_eq(panel.health_label.text, "Health: %d/%d" % [unit.current_hp, unit.maximum_hp])
	assert_eq(panel.movement_label.text, "Movement: %d/%d" % [
		unit.movement_remaining,
		unit.get_unit_data().stats_block.speed,
	])


func test_controller_cursor_immediately_transitions_between_occupied_and_empty_tiles() -> void:
	var main = await _main_scene()
	var tile_map = main.get_node("TileMapLayer")
	var panel = main.get_node("HUDCanvasLayer/LowerThirdPanel")
	var occupied: Vector2i = tile_map.deployment_zones_data[0][0]
	tile_map.troop_manager.set_current_unit("shard_walker")
	assert_true(tile_map.troop_manager.place_unit(occupied, 0))
	tile_map.set_selected_tile(occupied)
	assert_true(panel.unit_name_label.text.contains("Shardwalker"))

	var movement_pairs := [
		[JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_LEFT, Vector2.RIGHT, Vector2.LEFT],
		[JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_UP, Vector2.DOWN, Vector2.UP],
		[JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, Vector2.LEFT, Vector2.RIGHT],
		[JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, Vector2.UP, Vector2.DOWN],
	]
	var selected_pair: Array = []
	for pair: Array in movement_pairs:
		var destination: Vector2i = tile_map._nearest_valid_neighbor_in_direction(occupied, pair[2])
		if destination != occupied \
				and tile_map._nearest_valid_neighbor_in_direction(destination, pair[3]) == occupied:
			selected_pair = pair
			break
	assert_false(selected_pair.is_empty(), "test tile has a reversible controller neighbor")
	if selected_pair.is_empty():
		return

	tile_map._unhandled_input(_joy_button(selected_pair[0]))
	assert_eq(panel.unit_name_label.text, "Unit: Empty")
	assert_null(tile_map.radial_menu_instance, "cursor movement does not require primary action")
	tile_map._unhandled_input(_joy_button(selected_pair[1]))
	assert_true(panel.unit_name_label.text.contains("Shardwalker"))


func test_panel_position_is_independent_of_camera_pan_and_zoom() -> void:
	var main = await _main_scene()
	var tile_map = main.get_node("TileMapLayer")
	var panel: Control = main.get_node("HUDCanvasLayer/LowerThirdPanel")
	var original_position := panel.global_position
	tile_map.camera.position += Vector2(250.0, 125.0)
	tile_map.camera.zoom = Vector2(1.75, 1.75)
	await get_tree().process_frame
	assert_eq(panel.global_position, original_position)
