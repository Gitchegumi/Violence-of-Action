extends GutTest

var TileMapScene = preload("res://scenes/tileMap.tscn")
var MockUnit = preload("res://tests/unit/mock_unit.gd")
var tile_map
var troop_manager


func before_each():
	GameState.start_playing_for_test(2)
	GameState.current_phase = GameState.TurnPhase.COMBAT
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
	terrain.passable_by = "land" if name.to_lower() not in ["water", "mountain"] else name.to_lower()
	return terrain


func _set_tiles(coords: Array, terrain: TerrainType) -> void:
	for coord in coords:
		tile_map.terrain_data_map[coord] = terrain


func _unit(
	coord: Vector2i,
	type_id: String,
	player_id: int = 0,
	stats: Dictionary = {"attack": 2, "armor": 1, "health": 3, "range": 2, "speed": 6},
	terrain_matrix: Dictionary = {"field": 1, "forest": 1, "mountain": -1, "water": -1},
) -> Node:
	var unit = MockUnit.new()
	var data := UnitType.new()
	data.stats_block = stats
	data.terrain_type_matrix = terrain_matrix
	unit.unit_data = data
	unit.unit_type_id = type_id
	unit.map_pos = coord
	unit.controller_player_id = player_id
	unit.reset_turn_state()
	tile_map.add_child(unit)
	troop_manager.units_on_map[coord] = unit
	return unit


func test_fluxsmith_heals_one_adjacent_ally_and_spends_combat_action():
	_set_tiles([Vector2i.ZERO, Vector2i(1, 0)], _terrain("Field"))
	var fluxsmith := _unit(Vector2i.ZERO, "fluxsmith")
	var ally := _unit(Vector2i(1, 0), "shard_walker")
	ally.current_hp = 1
	var result: Dictionary = troop_manager.heal_unit(fluxsmith, ally)
	assert_true(result.success)
	assert_eq(ally.current_hp, 2)
	assert_true(fluxsmith.attacked_this_turn)
	assert_false(troop_manager.get_attack_start_validation(fluxsmith).valid)


func test_fluxsmith_barrier_rejects_occupied_water_and_mountain_hexes():
	_set_tiles([Vector2i.ZERO, Vector2i(1, 0)], _terrain("Field"))
	tile_map.terrain_data_map[Vector2i(0, 1)] = _terrain("Water")
	tile_map.terrain_data_map[Vector2i(-1, 1)] = _terrain("Mountain")
	var fluxsmith := _unit(Vector2i.ZERO, "fluxsmith")
	_unit(Vector2i(1, 0), "shard_walker")
	assert_false(troop_manager.create_barrier(fluxsmith, Vector2i(1, 0)).success)
	assert_false(troop_manager.create_barrier(fluxsmith, Vector2i(0, 1)).success)
	assert_false(troop_manager.create_barrier(fluxsmith, Vector2i(-1, 1)).success)


func test_barrier_costs_three_movement_blocks_los_and_expires_on_third_owner_turn():
	_set_tiles([Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], _terrain("Field"))
	var fluxsmith := _unit(Vector2i.ZERO, "fluxsmith")
	var barrier_result: Dictionary = troop_manager.create_barrier(fluxsmith, Vector2i(1, 0))
	assert_true(barrier_result.success)
	var barrier: TacticalBarrier = barrier_result.barrier
	var mover := _unit(Vector2i(3, 0), "shard_walker", 1)
	assert_eq(troop_manager._movement_cost(mover, Vector2i(1, 0)), 3)
	assert_false(tile_map.has_line_of_sight(Vector2i.ZERO, Vector2i(2, 0)))
	troop_manager.end_turn(0)
	troop_manager.end_turn(0)
	assert_same(troop_manager.get_barrier_at(Vector2i(1, 0)), barrier)
	troop_manager.end_turn(0)
	assert_null(troop_manager.get_barrier_at(Vector2i(1, 0)))


func test_enemy_must_occupy_barrier_hex_to_attack_and_friendly_owner_can_dismantle():
	_set_tiles([Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1)], _terrain("Field"))
	var fluxsmith := _unit(Vector2i.ZERO, "fluxsmith")
	var first: Dictionary = troop_manager.create_barrier(fluxsmith, Vector2i(1, 0))
	var barrier: TacticalBarrier = first.barrier
	var enemy := _unit(Vector2i(2, 0), "shard_walker", 1)
	GameState.active_player_id = 1
	assert_eq(troop_manager.get_barrier_attack_validation(enemy, barrier).reason, "must_occupy_barrier_hex")
	troop_manager.units_on_map.erase(enemy.map_pos)
	enemy.map_pos = Vector2i(1, 0)
	troop_manager.units_on_map[enemy.map_pos] = enemy
	assert_true(troop_manager.resolve_barrier_attack(enemy, barrier, 6, 6).destroyed)
	assert_null(troop_manager.get_barrier_at(Vector2i(1, 0)))
	GameState.active_player_id = 0
	fluxsmith.reset_turn_state()
	var second: Dictionary = troop_manager.create_barrier(fluxsmith, Vector2i(0, 1))
	assert_true(troop_manager.dismantle_barrier(second.barrier, 0))
	assert_null(troop_manager.get_barrier_at(Vector2i(0, 1)))


func test_ghostthorn_teleport_is_free_once_per_game_and_ignores_mountain():
	_set_tiles([Vector2i.ZERO], _terrain("Field"))
	tile_map.terrain_data_map[Vector2i(2, 0)] = _terrain("Mountain")
	tile_map.terrain_data_map[Vector2i(0, 2)] = _terrain("Water")
	var ghost := _unit(Vector2i.ZERO, "ghostthorn")
	ghost.attacked_this_turn = true
	var movement_before: int = ghost.movement_remaining
	var result: Dictionary = troop_manager.teleport_unit(ghost, Vector2i(2, 0))
	assert_true(result.success)
	assert_eq(ghost.movement_remaining, movement_before)
	assert_true(ghost.teleport_used)
	assert_false(troop_manager.teleport_unit(ghost, Vector2i.ZERO).success)
	ghost.teleport_used = false
	assert_false(troop_manager.teleport_unit(ghost, Vector2i(0, 2)).success)


func test_golemancer_successful_primary_hit_splashes_only_adjacent_enemies():
	_set_tiles([Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)], _terrain("Field"))
	var golem := _unit(Vector2i.ZERO, "golemancer_hull")
	var primary := _unit(Vector2i(1, 0), "shard_walker", 1)
	var adjacent_enemy := _unit(Vector2i(2, 0), "shard_walker", 1)
	var adjacent_friend := _unit(Vector2i(1, 1), "shard_walker", 0)
	var result: Dictionary = troop_manager.resolve_attack(golem, primary, 6, 6)
	assert_true(result.hit)
	assert_eq(primary.current_hp, 2)
	assert_eq(adjacent_enemy.current_hp, 2)
	assert_eq(adjacent_friend.current_hp, 3)
	assert_eq(result.splash_results.size(), 1)


func test_skyrender_post_combat_move_is_full_speed_once_and_not_splittable():
	_set_tiles([Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(-2, 0)], _terrain("Field"))
	var carrier := _unit(Vector2i.ZERO, "sky_render")
	var enemy := _unit(Vector2i(2, 0), "shard_walker", 1)
	var attack: Dictionary = troop_manager.resolve_attack(carrier, enemy, 1, 1)
	assert_false(attack.hit)
	assert_true(carrier.post_combat_move_available)
	assert_eq(carrier.movement_remaining, 6)
	GameState.current_phase = GameState.TurnPhase.RESOLVE
	assert_false(troop_manager.get_move_validation(carrier).valid, "ordinary movement remains phase-bound")
	assert_true(troop_manager.move_unit_post_combat(carrier, Vector2i(-1, 0)).success)
	assert_eq(carrier.movement_remaining, 0)
	assert_true(carrier.post_combat_move_used)
	assert_false(troop_manager.move_unit_post_combat(carrier, Vector2i(-2, 0)).success)
	carrier.reset_turn_state()
	assert_true(carrier.post_combat_move_used, "once-per-game flag persists between turns")


func test_skyrender_load_and_unload_each_cost_three_and_preserve_passenger_state():
	_set_tiles([Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0)], _terrain("Field"))
	GameState.current_phase = GameState.TurnPhase.MOVEMENT
	var carrier := _unit(Vector2i.ZERO, "sky_render")
	var passenger := _unit(Vector2i(1, 0), "fluxsmith")
	passenger.attacked_this_turn = true
	assert_true(troop_manager.load_transport(carrier, passenger).success)
	assert_eq(carrier.movement_remaining, 3)
	assert_false(passenger.visible)
	assert_null(troop_manager.get_unit_at_map_coord(Vector2i(1, 0)))
	assert_true(troop_manager.unload_transport(carrier, Vector2i(-1, 0)).success)
	assert_eq(carrier.movement_remaining, 0)
	assert_true(passenger.visible)
	assert_true(passenger.attacked_this_turn)
	assert_same(troop_manager.get_unit_at_map_coord(Vector2i(-1, 0)), passenger)


func test_destroyed_skyrender_over_water_destroys_incapable_passenger():
	_set_tiles([Vector2i.ZERO, Vector2i(1, 0)], _terrain("Field"))
	tile_map.terrain_data_map[Vector2i(-1, 0)] = _terrain("Water")
	GameState.current_phase = GameState.TurnPhase.MOVEMENT
	var carrier := _unit(Vector2i.ZERO, "sky_render", 0, {"attack": 2, "armor": 1, "health": 1, "range": 2, "speed": 6}, {"field": 1, "water": 1})
	var passenger := _unit(Vector2i(1, 0), "shard_walker")
	assert_true(troop_manager.load_transport(carrier, passenger).success)
	assert_true(troop_manager.move_unit(carrier, Vector2i(-1, 0)).success)
	assert_true(troop_manager.destroy_unit(carrier, "carrier_destroyed"))
	assert_false(is_instance_valid(passenger) and not passenger.is_queued_for_deletion())
	assert_false(troop_manager.units_on_map.has(Vector2i(-1, 0)))


func test_transport_crash_survivor_is_placed_on_destroyed_carriers_hex():
	_set_tiles([Vector2i.ZERO, Vector2i(1, 0)], _terrain("Field"))
	GameState.current_phase = GameState.TurnPhase.MOVEMENT
	var carrier := _unit(Vector2i.ZERO, "sky_render")
	var passenger := _unit(Vector2i(1, 0), "ghostthorn")
	assert_true(troop_manager.load_transport(carrier, passenger).success)
	var winning_seed := -1
	for candidate in range(1000):
		var probe := RandomNumberGenerator.new()
		probe.seed = candidate
		if probe.randi_range(1, 6) + probe.randi_range(1, 6) > 8:
			winning_seed = candidate
			break
	assert_gte(winning_seed, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = winning_seed
	assert_true(troop_manager.destroy_unit(carrier, "carrier_destroyed", rng))
	assert_same(troop_manager.get_unit_at_map_coord(Vector2i.ZERO), passenger)
	assert_true(passenger.visible)
	assert_null(passenger.transported_by)
