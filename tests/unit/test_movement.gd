extends GutTest

var TileMapScene = preload("res://scenes/tileMap.tscn")
var MockUnit = preload("res://tests/unit/mock_unit.gd")
var tile_map
var troop_manager


func before_each():
	GameState.start_playing_for_test(2)
	GameState.current_phase = GameState.TurnPhase.MOVEMENT
	tile_map = TileMapScene.instantiate()
	add_child_autofree(tile_map)
	await get_tree().process_frame
	troop_manager = tile_map.troop_manager
	tile_map.terrain_data_map.clear()


func after_each():
	GameState.return_to_menu()


func _terrain(name: String, cost: int = 1) -> TerrainType:
	var terrain := TerrainType.new()
	terrain.terrain_name = name
	terrain.move_cost = cost
	return terrain


func _unit(coord: Vector2i, player_id: int = 0, speed: int = 6) -> Node:
	var unit = MockUnit.new()
	var data := UnitType.new()
	data.stats_block = {"speed": speed}
	data.terrain_type_matrix = {"field": 1, "forest": 2, "mountain": -1, "water": -1}
	unit.unit_data = data
	unit.map_pos = coord
	unit.controller_player_id = player_id
	unit.reset_turn_state()
	tile_map.add_child(unit)
	troop_manager.units_on_map[coord] = unit
	return unit


func _set_tiles(coords: Array, terrain: TerrainType) -> void:
	for coord in coords:
		tile_map.terrain_data_map[coord] = terrain


func test_cheapest_path_uses_weighted_terrain_costs():
	var field := _terrain("Field")
	var forest := _terrain("Forest", 2)
	_set_tiles([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
	], field)
	tile_map.terrain_data_map[Vector2i(1, 0)] = forest
	tile_map.terrain_data_map[Vector2i(2, 0)] = forest
	var unit := _unit(Vector2i(0, 0))
	var result: Dictionary = troop_manager.find_cheapest_path(unit, Vector2i(3, 0))
	assert_true(result.success)
	assert_eq(result.cost, 4)
	assert_eq(result.path, [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 0),
	])


func test_friendly_units_allow_pass_through_but_not_occupied_destination():
	_set_tiles([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], _terrain("Field"))
	var mover := _unit(Vector2i(0, 0))
	_unit(Vector2i(1, 0), 0)
	var through_friend: Dictionary = troop_manager.find_cheapest_path(mover, Vector2i(2, 0))
	assert_true(through_friend.success)
	assert_eq(through_friend.path, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var occupied_destination: Dictionary = troop_manager.find_cheapest_path(mover, Vector2i(1, 0))
	assert_false(occupied_destination.success)
	assert_eq(occupied_destination.reason, "destination_occupied")


func test_enemy_occupied_hex_blocks_path():
	_set_tiles([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], _terrain("Field"))
	var mover := _unit(Vector2i(0, 0))
	_unit(Vector2i(1, 0), 1)
	var result: Dictionary = troop_manager.find_cheapest_path(mover, Vector2i(2, 0))
	assert_false(result.success)
	assert_eq(result.reason, "unreachable")


func test_movement_budget_can_be_split_across_multiple_moves():
	_set_tiles([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], _terrain("Field"))
	var mover := _unit(Vector2i(0, 0), 0, 4)
	var first: Dictionary = troop_manager.move_unit(mover, Vector2i(1, 0))
	assert_true(first.success)
	assert_eq(mover.movement_remaining, 3)
	var second: Dictionary = troop_manager.move_unit(mover, Vector2i(2, 0))
	assert_true(second.success)
	assert_eq(mover.movement_remaining, 2)
	assert_same(troop_manager.get_unit_at_map_coord(Vector2i(2, 0)), mover)


func test_single_engagement_allows_disengagement_but_forbids_later_action():
	_set_tiles([Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(-2, 0)], _terrain("Field"))
	var mover := _unit(Vector2i(0, 0))
	_unit(Vector2i(1, 0), 1)
	var result: Dictionary = troop_manager.move_unit(mover, Vector2i(-1, 0))
	assert_true(result.success)
	assert_true(mover.disengaged_this_turn)
	assert_false(troop_manager.record_non_movement_action(mover))
	var position_after_disengagement: Vector2i = mover.map_pos
	var movement_after_disengagement: int = mover.movement_remaining
	var second_move: Dictionary = troop_manager.move_unit(mover, Vector2i(-2, 0))
	assert_false(second_move.success)
	assert_eq(second_move.reason, "disengagement_complete")
	assert_eq(mover.map_pos, position_after_disengagement)
	assert_eq(mover.movement_remaining, movement_after_disengagement)


func test_path_cannot_continue_beyond_new_enemy_engagement():
	_set_tiles([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(1, 1),
	], _terrain("Field"))
	var mover := _unit(Vector2i(0, 0))
	_unit(Vector2i(1, 1), 1)
	var farther_result: Dictionary = troop_manager.find_cheapest_path(mover, Vector2i(3, 0))
	assert_false(farther_result.success)
	assert_eq(farther_result.reason, "unreachable")
	var engagement_result: Dictionary = troop_manager.move_unit(mover, Vector2i(1, 0))
	assert_true(engagement_result.success)
	assert_true(mover.entered_engagement_this_turn)
	var second_move: Dictionary = troop_manager.move_unit(mover, Vector2i(2, 0))
	assert_false(second_move.success)
	assert_eq(second_move.reason, "engaged_after_action")


func test_attack_without_destroying_adjacent_enemy_prevents_movement():
	_set_tiles([Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0)], _terrain("Field"))
	var mover := _unit(Vector2i(0, 0))
	_unit(Vector2i(1, 0), 1)
	assert_true(troop_manager.record_non_movement_action(mover))
	var result: Dictionary = troop_manager.move_unit(mover, Vector2i(-1, 0))
	assert_false(result.success)
	assert_eq(result.reason, "engaged_after_action")


func test_destroying_last_adjacent_enemy_unlocks_remaining_movement_during_combat():
	_set_tiles([Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0)], _terrain("Field"))
	var mover := _unit(Vector2i(0, 0))
	var enemy := _unit(Vector2i(1, 0), 1)
	troop_manager.units_on_map.erase(enemy.map_pos)
	enemy.queue_free()
	GameState.current_phase = GameState.TurnPhase.COMBAT
	assert_true(troop_manager.record_attack_resolution(mover, true, true))
	var result: Dictionary = troop_manager.move_unit(mover, Vector2i(-1, 0))
	assert_true(result.success)
	assert_eq(mover.movement_remaining, 5)


func test_combat_phase_movement_stays_blocked_without_destroying_last_enemy():
	_set_tiles([Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0)], _terrain("Field"))
	var mover := _unit(Vector2i(0, 0))
	_unit(Vector2i(1, 0), 1)
	GameState.current_phase = GameState.TurnPhase.COMBAT
	assert_true(troop_manager.record_attack_resolution(mover, false, true))
	var result: Dictionary = troop_manager.move_unit(mover, Vector2i(-1, 0))
	assert_false(result.success)
	assert_eq(result.reason, "not_movement_phase")


func test_non_engagement_kill_does_not_unlock_combat_movement():
	_set_tiles([Vector2i(0, 0), Vector2i(-1, 0)], _terrain("Field"))
	var mover := _unit(Vector2i(0, 0))
	GameState.current_phase = GameState.TurnPhase.COMBAT
	assert_true(troop_manager.record_attack_resolution(mover, true, false))
	var result: Dictionary = troop_manager.move_unit(mover, Vector2i(-1, 0))
	assert_false(result.success)
	assert_eq(result.reason, "not_movement_phase")


func test_multiple_adjacent_enemies_pin_unit():
	_set_tiles([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
	], _terrain("Field"))
	var mover := _unit(Vector2i(0, 0))
	_unit(Vector2i(1, 0), 1)
	_unit(Vector2i(0, 1), 1)
	var result: Dictionary = troop_manager.move_unit(mover, Vector2i(-1, 0))
	assert_false(result.success)
	assert_eq(result.reason, "pinned")


func test_movement_is_limited_to_active_player_movement_phase():
	_set_tiles([Vector2i(0, 0), Vector2i(1, 0)], _terrain("Field"))
	var inactive_unit := _unit(Vector2i(0, 0), 1)
	var inactive_result: Dictionary = troop_manager.move_unit(inactive_unit, Vector2i(1, 0))
	assert_false(inactive_result.success)
	assert_eq(inactive_result.reason, "not_active_player")
	GameState.current_phase = GameState.TurnPhase.COMBAT
	inactive_unit.controller_player_id = 0
	var wrong_phase_result: Dictionary = troop_manager.move_unit(inactive_unit, Vector2i(1, 0))
	assert_false(wrong_phase_result.success)
	assert_eq(wrong_phase_result.reason, "not_movement_phase")
