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


func _gameplay_tile_map():
	var main = MainScene.instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	return main.get_node("TileMapLayer")


func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _joy_motion(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


func _accept_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = "ui_accept"
	event.pressed = true
	return event


func _cancel_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	return event


func test_first_controller_direction_initializes_a_valid_cursor() -> void:
	var tile_map = await _gameplay_tile_map()
	assert_false(tile_map.terrain_data_map.has(tile_map.selected_tile))
	tile_map._unhandled_input(_joy_button(JOY_BUTTON_DPAD_RIGHT))
	assert_true(tile_map.terrain_data_map.has(tile_map.selected_tile))
	assert_eq(tile_map.selection_layer.get_used_cells(), [tile_map.selected_tile])


func test_dpad_moves_cursor_one_adjacent_valid_hex() -> void:
	var tile_map = await _gameplay_tile_map()
	tile_map.set_selected_tile(tile_map.objective_position)
	var origin: Vector2i = tile_map.selected_tile
	tile_map._unhandled_input(_joy_button(JOY_BUTTON_DPAD_RIGHT))
	assert_has(tile_map._get_neighbors(origin), tile_map.selected_tile)
	assert_true(tile_map.terrain_data_map.has(tile_map.selected_tile))
	assert_eq(tile_map.selection_layer.get_used_cells(), [tile_map.selected_tile])


func test_left_stick_requires_a_new_directional_press_for_each_hex() -> void:
	var tile_map = await _gameplay_tile_map()
	tile_map.set_selected_tile(tile_map.objective_position)
	var origin: Vector2i = tile_map.selected_tile
	var right := _joy_motion(JOY_AXIS_LEFT_X, 1.0)
	tile_map._unhandled_input(right)
	await get_tree().process_frame
	var first_step: Vector2i = tile_map.selected_tile
	tile_map._unhandled_input(right)
	await get_tree().process_frame
	assert_eq(tile_map.selected_tile, first_step, "held direction does not skip multiple hexes")
	tile_map._unhandled_input(_joy_motion(JOY_AXIS_LEFT_X, 0.0))
	tile_map._unhandled_input(right)
	await get_tree().process_frame
	assert_ne(tile_map.selected_tile, first_step, "returning through the deadzone permits another step")
	assert_gt(tile_map._hex_distance(origin, tile_map.selected_tile), 1)


func test_diagonal_stick_target_is_independent_of_axis_event_order() -> void:
	var x_first_map = await _gameplay_tile_map()
	x_first_map.set_selected_tile(x_first_map.objective_position)
	x_first_map._unhandled_input(_joy_motion(JOY_AXIS_LEFT_X, 0.8))
	x_first_map._unhandled_input(_joy_motion(JOY_AXIS_LEFT_Y, -0.8))
	await get_tree().process_frame
	var x_first_target: Vector2i = x_first_map.selected_tile

	var y_first_map = await _gameplay_tile_map()
	y_first_map.set_selected_tile(y_first_map.objective_position)
	y_first_map._unhandled_input(_joy_motion(JOY_AXIS_LEFT_Y, -0.8))
	y_first_map._unhandled_input(_joy_motion(JOY_AXIS_LEFT_X, 0.8))
	await get_tree().process_frame
	assert_eq(y_first_map.selected_tile, x_first_target,
		"the complete stick vector selects the same nearest hex in either event order")


func test_radial_lifecycle_resets_board_stick_state() -> void:
	var tile_map = await _gameplay_tile_map()
	tile_map.set_selected_tile(tile_map.objective_position)
	tile_map._unhandled_input(_joy_motion(JOY_AXIS_LEFT_X, 1.0))
	await get_tree().process_frame
	var moved_right: Vector2i = tile_map.selected_tile

	tile_map._show_radial_menu(tile_map.deployment_zones_data[0][0])
	assert_not_null(tile_map.radial_menu_instance)
	tile_map._unhandled_input(_joy_motion(JOY_AXIS_LEFT_X, 0.0))
	tile_map._close_radial_menu("test")
	assert_null(tile_map.radial_menu_instance)

	var expected_up: Vector2i = tile_map._nearest_valid_neighbor_in_direction(moved_right, Vector2.UP)
	tile_map._unhandled_input(_joy_motion(JOY_AXIS_LEFT_Y, -1.0))
	await get_tree().process_frame
	assert_eq(tile_map.selected_tile, expected_up,
		"closing a radial releases the board latch and removes stale axis state")


func test_opening_radial_invalidates_queued_board_stick_move() -> void:
	var tile_map = await _gameplay_tile_map()
	tile_map.set_selected_tile(tile_map.objective_position)
	var origin: Vector2i = tile_map.selected_tile
	tile_map._unhandled_input(_joy_motion(JOY_AXIS_LEFT_X, 1.0))
	tile_map._show_radial_menu(tile_map.deployment_zones_data[0][0])
	await get_tree().process_frame
	assert_eq(tile_map.selected_tile, origin,
		"a deferred board move cannot commit after radial input ownership begins")


func test_primary_action_opens_deployment_radial_on_cursor_hex() -> void:
	var tile_map = await _gameplay_tile_map()
	var origin: Vector2i = tile_map.deployment_zones_data[0][0]
	tile_map.set_selected_tile(origin)
	tile_map._unhandled_input(_accept_event())
	assert_not_null(tile_map.radial_menu_instance)
	assert_false(tile_map.radial_menu_instance.is_action_mode())
	assert_eq(tile_map.radial_origin, origin)


func test_primary_action_opens_action_radial_on_cursor_unit() -> void:
	var tile_map = await _gameplay_tile_map()
	var origin: Vector2i = tile_map.deployment_zones_data[0][0]
	assert_true(tile_map.troop_manager.place_unit(origin, 0))
	tile_map.set_selected_tile(origin)
	tile_map._unhandled_input(_accept_event())
	assert_not_null(tile_map.radial_menu_instance)
	assert_true(tile_map.radial_menu_instance.is_action_mode())
	assert_eq(tile_map.radial_origin, origin)


func test_primary_action_resolves_pending_target_on_cursor_hex() -> void:
	var tile_map = await _gameplay_tile_map()
	var origin: Vector2i = tile_map.deployment_zones_data[0][0]
	tile_map.troop_manager.set_current_unit("shard_walker")
	assert_true(tile_map.troop_manager.place_unit(origin, 0))
	assert_true(tile_map.troop_manager.place_unit(tile_map.deployment_zones_data[1][0], 1))
	GameState.start_playing_for_test(2)
	GameState.current_phase = GameState.TurnPhase.MOVEMENT
	tile_map.troop_manager.start_turn(0)
	var unit = tile_map.troop_manager.get_unit_at_map_coord(origin)
	tile_map._begin_pending_action("move", unit, origin)
	var destination: Vector2i = tile_map.get_action_highlighted_cells()[0]
	tile_map.set_selected_tile(destination)
	tile_map._unhandled_input(_accept_event())
	assert_same(tile_map.troop_manager.get_unit_at_map_coord(destination), unit)
	assert_true(tile_map.pending_action.is_empty())


func test_controller_cancel_clears_pending_target_selection() -> void:
	var tile_map = await _gameplay_tile_map()
	var origin: Vector2i = tile_map.deployment_zones_data[0][0]
	tile_map.troop_manager.set_current_unit("shard_walker")
	assert_true(tile_map.troop_manager.place_unit(origin, 0))
	assert_true(tile_map.troop_manager.place_unit(tile_map.deployment_zones_data[1][0], 1))
	GameState.start_playing_for_test(2)
	GameState.current_phase = GameState.TurnPhase.MOVEMENT
	tile_map.troop_manager.start_turn(0)
	tile_map._begin_pending_action(
		"move",
		tile_map.troop_manager.get_unit_at_map_coord(origin),
		origin
	)
	tile_map._unhandled_input(_cancel_event())
	assert_true(tile_map.pending_action.is_empty())
	assert_true(tile_map.get_action_highlighted_cells().is_empty())
