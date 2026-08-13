extends GutTest

var GameStateScript = preload("res://scripts/game_state.gd")
var MainScene = preload("res://scenes/main.tscn")
var state_machine


func before_each():
	get_tree().paused = false
	state_machine = GameStateScript.new()
	state_machine.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child_autofree(state_machine)


func after_each():
	get_tree().paused = false
	GameState.return_to_menu()
	GameState.active_player_id = 0
	GameSession.clear_match_config()


func test_match_enters_initial_deployment_with_all_players_pending():
	state_machine.begin_match({"player_count": 3})
	assert_eq(state_machine.current_state, state_machine.State.INITIAL_DEPLOYMENT)
	assert_eq(state_machine.player_count, 3)
	assert_eq(state_machine.deployment_ready, {0: false, 1: false, 2: false})
	assert_eq(state_machine.round_number, 0)


func test_all_players_ready_starts_round_one_at_start_turn():
	state_machine.begin_match({"player_count": 2, "seed": 982451653})
	assert_false(state_machine.mark_deployment_ready(0))
	assert_true(state_machine.mark_deployment_ready(1))
	assert_eq(state_machine.current_state, state_machine.State.PLAYING)
	assert_eq(state_machine.round_number, 1)
	assert_eq(state_machine.active_player_id, state_machine.starting_player_id)
	assert_eq(state_machine.current_phase, state_machine.TurnPhase.START_TURN)


func test_match_seed_deterministically_selects_a_valid_starting_player():
	state_machine.begin_match({"player_count": 3, "seed": 982451653})
	var selected_player: int = state_machine.starting_player_id
	state_machine.begin_match({"player_count": 3, "seed": 982451653})
	assert_eq(state_machine.starting_player_id, selected_player)
	assert_between(selected_player, 0, 2)


func test_phase_order_matches_game_rules_and_rotates_players():
	state_machine.start_playing_for_test(2)
	var observed: Array = [state_machine.current_phase]
	for _step in range(5):
		assert_true(state_machine.advance_phase())
		observed.append(state_machine.current_phase)
	assert_eq(observed, state_machine.PHASE_ORDER)
	assert_true(state_machine.advance_phase())
	assert_eq(state_machine.active_player_id, 1)
	assert_eq(state_machine.round_number, 1)
	assert_eq(state_machine.current_phase, state_machine.TurnPhase.START_TURN)
	for _step in range(6):
		state_machine.advance_phase()
	assert_eq(state_machine.active_player_id, 0)
	assert_eq(state_machine.round_number, 2)


func test_pause_and_resume_restore_playing_state_and_tree_processing():
	state_machine.start_playing_for_test(2)
	assert_true(state_machine.pause_game())
	assert_eq(state_machine.current_state, state_machine.State.PAUSED)
	assert_true(get_tree().paused)
	assert_false(state_machine.advance_phase(), "phases cannot advance while paused")
	assert_true(state_machine.resume_game())
	assert_eq(state_machine.current_state, state_machine.State.PLAYING)
	assert_false(get_tree().paused)


func test_initial_deployment_can_pause_without_skipping_setup():
	state_machine.begin_match({"player_count": 2})
	assert_true(state_machine.pause_game())
	assert_true(state_machine.resume_game())
	assert_eq(state_machine.current_state, state_machine.State.INITIAL_DEPLOYMENT)


func test_game_over_records_winner_and_blocks_phase_progression():
	state_machine.start_playing_for_test(2)
	assert_true(state_machine.declare_game_over(1, "objective_control"))
	assert_eq(state_machine.current_state, state_machine.State.GAME_OVER)
	assert_eq(state_machine.winner_player_id, 1)
	assert_eq(state_machine.game_over_reason, "objective_control")
	assert_false(state_machine.advance_phase())
	state_machine.return_to_menu()
	assert_eq(state_machine.current_state, state_machine.State.MENU)


func test_game_over_declared_at_turn_end_does_not_rotate_player():
	state_machine.start_playing_for_test(2)
	state_machine.current_phase = state_machine.TurnPhase.CLEAN_UP
	state_machine.turn_ended.connect(func(player_id, _round):
		state_machine.declare_game_over(player_id, "objective_control")
	)
	assert_true(state_machine.advance_phase())
	assert_eq(state_machine.current_state, state_machine.State.GAME_OVER)
	assert_eq(state_machine.active_player_id, 0)
	assert_eq(state_machine.current_phase, state_machine.TurnPhase.CLEAN_UP)


func test_main_objective_control_wins_after_three_later_controller_turns():
	GameState.begin_match({"player_count": 2, "seed": 982451653})
	var main = MainScene.instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	var tile_map = main.get_node("TileMapLayer")
	tile_map.troop_manager.set_current_unit("shard_walker")
	assert_true(tile_map.troop_manager.place_unit(tile_map.objective_position, 0))
	GameState.start_playing_for_test(2)
	var essence_before_capture: int = main.get_node("ResourceManager").get_essence(0)
	main._on_turn_ended(0, 1)
	assert_eq(main.get_node("ResourceManager").objective_controller, 0)
	assert_eq(main.get_node("ResourceManager").objective_control_turns, 0)
	assert_eq(main.get_node("ResourceManager").get_essence(0), essence_before_capture + 6)
	assert_eq(main.get_node("ObjectiveLabel").text, "Objective: Player 1 (0/3)")
	main._on_turn_ended(1, 1)
	assert_eq(main.get_node("ResourceManager").objective_control_turns, 0)
	for expected_turn in range(1, 4):
		main._on_turn_ended(0, expected_turn + 1)
		assert_eq(main.get_node("ResourceManager").objective_control_turns, expected_turn)
	assert_eq(GameState.current_state, GameState.State.GAME_OVER)
	assert_eq(GameState.winner_player_id, 0)
	assert_eq(GameState.game_over_reason, "objective_control")
	assert_true(main.get_node("TurnLabel").text.contains("Player 1 Wins"))
	assert_eq(main.get_node("ObjectiveLabel").text, "Objective: Player 1 (3/3)")


func test_destroying_penultimate_players_last_unit_declares_elimination():
	GameState.begin_match({"player_count": 2, "seed": 982451653})
	var main = MainScene.instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	var tile_map = main.get_node("TileMapLayer")
	tile_map.troop_manager.set_current_unit("shard_walker")
	var player_zero_tile: Vector2i = tile_map.deployment_zones_data[0][0]
	var player_one_tile: Vector2i = tile_map.deployment_zones_data[1][0]
	assert_true(tile_map.troop_manager.place_unit(player_zero_tile, 0))
	assert_true(tile_map.troop_manager.place_unit(player_one_tile, 1))
	GameState.start_playing_for_test(2)
	var defeated_unit = tile_map.troop_manager.get_unit_at_map_coord(player_one_tile)
	assert_true(tile_map.troop_manager.destroy_unit(defeated_unit, "defeated_unit"))
	assert_eq(GameState.current_state, GameState.State.GAME_OVER)
	assert_eq(GameState.winner_player_id, 0)
	assert_eq(GameState.game_over_reason, "elimination")
	assert_true(main.get_node("TurnLabel").text.contains("Player 1 Wins"))


func test_three_player_elimination_waits_until_only_one_player_remains():
	GameSession.set_match_config({"player_count": 3, "seed": 982451653})
	GameState.begin_match({"player_count": 3, "seed": 982451653})
	var main = MainScene.instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	var tile_map = main.get_node("TileMapLayer")
	tile_map.troop_manager.set_current_unit("shard_walker")
	var unit_tiles: Array[Vector2i] = []
	for player_id in range(3):
		var tile: Vector2i = tile_map.deployment_zones_data[player_id][0]
		unit_tiles.append(tile)
		assert_true(tile_map.troop_manager.place_unit(tile, player_id))
	GameState.start_playing_for_test(3)
	assert_true(tile_map.troop_manager.destroy_unit(
		tile_map.troop_manager.get_unit_at_map_coord(unit_tiles[2]),
		"player_three_unit",
	))
	assert_eq(GameState.current_state, GameState.State.PLAYING)
	assert_true(tile_map.troop_manager.destroy_unit(
		tile_map.troop_manager.get_unit_at_map_coord(unit_tiles[1]),
		"player_two_unit",
	))
	assert_eq(GameState.current_state, GameState.State.GAME_OVER)
	assert_eq(GameState.winner_player_id, 0)


func test_gameplay_ui_and_deployment_validation_follow_active_player():
	GameState.begin_match({"player_count": 2})
	var main = MainScene.instantiate()
	add_child_autofree(main)
	assert_true(main.get_node("TurnLabel").text.contains("Player 1"))
	main.get_node("AdvancePhaseButton").pressed.emit()
	assert_eq(GameState.active_player_id, 1)
	assert_true(main.get_node("TurnLabel").text.contains("Player 2"))
	assert_true(main.get_node("EssenceLabel").text.contains("Player 2"))
	var tile_map = main.get_node("TileMapLayer")
	tile_map.radial_origin = tile_map.deployment_zones_data[1][0]
	assert_true(tile_map._build_placement_context().tile_valid, "Player 2 uses Player 2's deployment zone")
	main.get_node("AdvancePhaseButton").pressed.emit()
	assert_eq(GameState.current_state, GameState.State.PLAYING)
	assert_eq(GameState.current_phase, GameState.TurnPhase.START_TURN)


func test_paused_real_scene_blocks_gameplay_processing_and_input():
	GameState.begin_match({"player_count": 2})
	var main = MainScene.instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	var tile_map = main.get_node("TileMapLayer")
	var starting_essence: int = tile_map.get_player_essence()
	assert_true(GameState.pause_game())
	assert_false(main.can_process(), "gameplay root is pausable")
	assert_false(tile_map.can_process(), "tile map cannot process behind pause overlay")
	assert_true(main.get_node("PauseInput").can_process(), "only pause input remains active")
	assert_true(main.get_node("PauseOverlay").visible)
	var debug_essence_input := InputEventKey.new()
	debug_essence_input.keycode = KEY_1
	debug_essence_input.pressed = true
	Input.parse_input_event(debug_essence_input)
	await get_tree().process_frame
	assert_eq(tile_map.get_player_essence(), starting_essence, "paused input cannot mutate gameplay")
