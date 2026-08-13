extends GutTest

var TileMapScene = preload("res://scenes/tileMap.tscn")
var MockUnit = preload("res://tests/unit/mock_unit.gd")
var CombatResolverScript = preload("res://scripts/systems/combat_resolver.gd")
var tile_map
var troop_manager


func before_each():
	GameState.start_playing_for_test(2)
	GameState.current_phase = GameState.TurnPhase.COMBAT
	tile_map = TileMapScene.instantiate()
	add_child_autofree(tile_map)
	await get_tree().process_frame
	troop_manager = tile_map.troop_manager
	troop_manager.units_on_map.clear()


func after_each():
	GameState.return_to_menu()


func _unit(coord: Vector2i, player_id: int, health: int = 3, attack: int = 1, armor: int = 0, attack_range: int = 1) -> Node:
	var unit = MockUnit.new()
	var data := UnitType.new()
	data.stats_block = {
		"health": health,
		"attack": attack,
		"armor": armor,
		"range": attack_range,
		"speed": 4,
	}
	unit.unit_data = data
	unit.map_pos = coord
	unit.controller_player_id = player_id
	unit.reset_turn_state()
	tile_map.add_child(unit)
	troop_manager.units_on_map[coord] = unit
	return unit


func _terrain(name: String) -> TerrainType:
	var terrain := TerrainType.new()
	terrain.terrain_name = name
	return terrain


func test_attack_total_below_defense_target_misses_without_changing_hp():
	var attacker := _unit(Vector2i.ZERO, 0, 3, 1)
	var defender := _unit(Vector2i(1, 0), 1, 3, 0, 1)
	var result := CombatResolverScript.resolve_attack(attacker, defender, 3, 3)
	assert_false(result.hit)
	assert_eq(result.attack_total, 7)
	assert_eq(result.defense_target, 9)
	assert_eq(result.damage, 0)
	assert_eq(defender.current_hp, 3)


func test_attack_total_equal_to_defense_target_hits_for_one_damage():
	var attacker := _unit(Vector2i.ZERO, 0, 3, 1)
	var defender := _unit(Vector2i(1, 0), 1, 3)
	var result := CombatResolverScript.resolve_attack(attacker, defender, 3, 4)
	assert_true(result.hit)
	assert_eq(result.attack_total, result.defense_target)
	assert_eq(result.damage, 1)
	assert_eq(defender.current_hp, 2)


func test_attack_total_above_defense_target_hits():
	var result := CombatResolverScript.resolve_attack(
		_unit(Vector2i.ZERO, 0, 3, 3),
		_unit(Vector2i(1, 0), 1, 3),
		4,
		4,
	)
	assert_true(result.hit)
	assert_gt(result.attack_total, result.defense_target)


func test_natural_two_always_misses_and_natural_twelve_always_hits():
	var strong_attacker := _unit(Vector2i.ZERO, 0, 3, 20)
	var defender := _unit(Vector2i(1, 0), 1, 3, 0, 20)
	assert_false(CombatResolverScript.resolve_attack(strong_attacker, defender, 1, 1).hit)
	var weak_attacker := _unit(Vector2i(2, 0), 0, 3, -20)
	assert_true(CombatResolverScript.resolve_attack(weak_attacker, defender, 6, 6).hit)


func test_hp_persists_and_armor_does_not_change_when_turn_state_resets():
	var attacker := _unit(Vector2i.ZERO, 0, 3, 1)
	var defender := _unit(Vector2i(1, 0), 1, 3, 0, 2)
	CombatResolverScript.resolve_attack(attacker, defender, 6, 6)
	assert_eq(defender.current_hp, 2)
	assert_eq(defender.get_unit_data().stats_block.armor, 2)
	defender.reset_turn_state()
	assert_eq(defender.current_hp, 2)
	assert_eq(defender.maximum_hp, 3)
	assert_eq(defender.get_unit_data().stats_block.armor, 2)


func test_hp_cannot_fall_below_zero_and_destroyed_unit_leaves_board_once():
	var attacker := _unit(Vector2i.ZERO, 0, 3, 1)
	var defender := _unit(Vector2i(1, 0), 1, 1)
	var destructions := []
	troop_manager.unit_destroyed.connect(func(_unit, _player, destruction_id): destructions.append(destruction_id))
	var result: Dictionary = troop_manager.resolve_attack(attacker, defender, 6, 6)
	assert_true(result.destroyed)
	assert_eq(result.remaining_hp, 0)
	assert_null(troop_manager.get_unit_at_map_coord(Vector2i(1, 0)))
	assert_eq(destructions.size(), 1)
	var repeated: Dictionary = troop_manager.resolve_attack(attacker, defender, 6, 6)
	assert_false(repeated.success)
	assert_eq(destructions.size(), 1)


func test_invalid_attack_does_not_spend_action_damage_or_mutate_occupancy():
	var attacker := _unit(Vector2i.ZERO, 0, 3, 1, 0, 1)
	var defender := _unit(Vector2i(2, 0), 1, 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var rng_state := rng.state
	var result: Dictionary = troop_manager.roll_attack(attacker, defender, rng)
	assert_false(result.success)
	assert_eq(result.reason, "out_of_range")
	assert_eq(rng.state, rng_state)
	assert_false(attacker.attacked_this_turn)
	assert_eq(defender.current_hp, 3)
	assert_same(troop_manager.get_unit_at_map_coord(Vector2i(2, 0)), defender)


func test_attacker_cannot_attack_twice_in_one_turn():
	var attacker := _unit(Vector2i.ZERO, 0)
	var defender := _unit(Vector2i(1, 0), 1, 3)
	assert_true(troop_manager.resolve_attack(attacker, defender, 1, 1).success)
	var second: Dictionary = troop_manager.resolve_attack(attacker, defender, 6, 6)
	assert_false(second.success)
	assert_eq(second.reason, "attack_already_used")
	assert_eq(defender.current_hp, 3)


func test_fixed_dice_and_stats_produce_identical_results():
	var first := CombatResolverScript.resolve_attack(
		_unit(Vector2i.ZERO, 0, 3, 2), _unit(Vector2i(1, 0), 1, 3, 0, 1), 3, 4
	)
	var second := CombatResolverScript.resolve_attack(
		_unit(Vector2i(3, 0), 0, 3, 2), _unit(Vector2i(4, 0), 1, 3, 0, 1), 3, 4
	)
	assert_eq(first, second)


func test_forest_adds_one_to_defense_target():
	var attacker := _unit(Vector2i.ZERO, 0, 3, 1)
	var defender := _unit(Vector2i(1, 0), 1, 3)
	tile_map.terrain_data_map[defender.map_pos] = _terrain("Forest")
	var result: Dictionary = troop_manager.resolve_attack(attacker, defender, 3, 4)
	assert_true(result.success)
	assert_eq(result.defense_modifier, 1)
	assert_eq(result.defense_target, 9)
	assert_false(result.hit, "the same total that hits in Field misses against Forest cover")
	assert_eq(defender.current_hp, 3)


func test_intervening_mountain_blocks_line_of_sight_without_rolling():
	var attacker := _unit(Vector2i.ZERO, 0, 3, 1, 0, 2)
	var defender := _unit(Vector2i(2, 0), 1, 3)
	tile_map.terrain_data_map[Vector2i(1, 0)] = _terrain("Mountain")
	var rng := RandomNumberGenerator.new()
	rng.seed = 9876
	var rng_state := rng.state
	var result: Dictionary = troop_manager.roll_attack(attacker, defender, rng)
	assert_false(result.success)
	assert_eq(result.reason, "line_of_sight_blocked")
	assert_eq(rng.state, rng_state)
	assert_false(attacker.attacked_this_turn)
	assert_eq(defender.current_hp, 3)


func test_intervening_units_and_forest_do_not_block_line_of_sight():
	var attacker := _unit(Vector2i.ZERO, 0, 3, 1, 0, 2)
	_unit(Vector2i(1, 0), 0)
	var defender := _unit(Vector2i(2, 0), 1, 3)
	tile_map.terrain_data_map[Vector2i(1, 0)] = _terrain("Forest")
	assert_true(tile_map.has_line_of_sight(attacker.map_pos, defender.map_pos))
	assert_true(troop_manager.get_attack_validation(attacker, defender).valid)
