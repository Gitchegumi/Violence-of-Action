extends GutTest

var ResourceManagerScript = preload("res://scripts/systems/resource_manager.gd")
var manager: ResourceManager


func before_each():
	manager = ResourceManagerScript.new()
	add_child_autofree(manager)
	manager.configure_players(2)


func _unit(unit_name: String, unit_cost: int) -> Dictionary:
	return {"unit_name": unit_name, "unit_cost": unit_cost}


func test_players_begin_with_twelve_essence():
	assert_eq(manager.get_essence(0), 12)
	assert_eq(manager.get_essence(1), 12)


func test_diversity_income_counts_each_non_scavenger_type_once():
	var units := [_unit("Shard Walker", 2), _unit("Shard Walker", 2), _unit("Tide Born", 4)]
	assert_eq(manager.start_turn(0, units), 3)
	assert_eq(manager.get_essence(0), 15)


func test_zero_unit_player_receives_minimum_rebuild_income():
	manager.set_essence(0, 0, "test_depleted_army")
	assert_eq(manager.start_turn(0, []), 1)
	assert_eq(manager.get_essence(0), 1)


func test_only_scavengers_have_no_passive_income():
	assert_eq(manager.start_turn(0, [_unit("Battlefield Scavenger", 1)]), 0)
	assert_eq(manager.get_essence(0), 12)


func test_scavenger_rewards_each_unique_destruction_once_not_per_scavenger():
	manager.record_unit_destroyed("unit_a")
	manager.record_unit_destroyed("unit_a")
	manager.record_unit_destroyed("unit_b")
	var scavengers := [_unit("Battlefield Scavenger", 1), _unit("Battlefield Scavenger", 2)]
	assert_eq(manager.start_turn(0, scavengers), 6)
	assert_eq(manager.start_turn(0, scavengers), 0, "destruction window resets at turn start")


func test_spending_emits_state_change_and_rejects_unaffordable_cost():
	watch_signals(manager)
	assert_true(manager.try_spend(0, 4, "purchase:tide_born"))
	assert_eq(manager.get_essence(0), 8)
	assert_signal_emitted_with_parameters(manager, "essence_changed", [0, 8, -4, "purchase:tide_born"])
	assert_false(manager.try_spend(0, 9, "purchase:ghostthorn"))
	assert_eq(manager.get_essence(0), 8)


func test_upgrade_is_once_per_turn_and_requires_safe_unit():
	assert_false(manager.try_purchase_upgrade(0, "unit_1", 3, true, false))
	assert_false(manager.try_purchase_upgrade(0, "unit_1", 3, false, true))
	assert_true(manager.try_purchase_upgrade(0, "unit_1", 3, false, false))
	assert_false(manager.try_purchase_upgrade(0, "unit_1", 3, false, false))
	manager.start_turn(0, [])
	assert_true(manager.try_purchase_upgrade(0, "unit_1", 3, false, false))


func test_objective_capture_grants_bonus_only_when_control_changes():
	assert_true(manager.capture_objective(0))
	assert_eq(manager.get_essence(0), 18)
	assert_false(manager.capture_objective(0))
	assert_eq(manager.get_essence(0), 18)
	assert_true(manager.capture_objective(1))
	assert_eq(manager.get_essence(1), 18)
	assert_eq(manager.objective_control_turns, 0)


func test_capture_turn_defers_upkeep_and_control_progress():
	manager.capture_objective(0)
	var capture_turn := manager.resolve_objective_turn(0)
	assert_true(capture_turn.retained)
	assert_false(capture_turn.paid_upkeep)
	assert_eq(capture_turn.turns, 0)
	assert_eq(manager.get_essence(0), 18)


func test_controller_turns_pay_upkeep_and_reach_victory_on_three():
	manager.capture_objective(0)
	manager.resolve_objective_turn(0)
	for expected_turn in range(1, 4):
		var result := manager.resolve_objective_turn(0)
		assert_true(result.paid_upkeep)
		assert_eq(result.turns, expected_turn)
		assert_eq(result.victory, expected_turn == 3)
	assert_eq(manager.get_essence(0), 9)


func test_opponent_turn_does_not_charge_or_advance_control():
	manager.capture_objective(0)
	manager.resolve_objective_turn(0)
	var opponent_turn := manager.resolve_objective_turn(1)
	assert_false(opponent_turn.paid_upkeep)
	assert_eq(opponent_turn.turns, 0)
	assert_eq(manager.get_essence(0), 18)


func test_opposing_capture_resets_progress_and_defers_new_controller_upkeep():
	manager.capture_objective(0)
	manager.resolve_objective_turn(0)
	manager.resolve_objective_turn(0)
	assert_eq(manager.objective_control_turns, 1)
	assert_true(manager.capture_objective(1))
	assert_eq(manager.objective_controller, 1)
	assert_eq(manager.objective_control_turns, 0)
	var capture_turn := manager.resolve_objective_turn(1)
	assert_false(capture_turn.paid_upkeep)
	assert_eq(manager.get_essence(1), 18)


func test_unaffordable_upkeep_removes_control_without_progress():
	manager.capture_objective(0)
	manager.resolve_objective_turn(0)
	manager.set_essence(0, 2)
	var result := manager.resolve_objective_turn(0)
	assert_false(result.retained)
	assert_false(result.victory)
	assert_eq(result.turns, 0)
	assert_eq(manager.objective_controller, ResourceManager.NO_PLAYER)


func test_clear_objective_control_removes_token_and_progress():
	manager.capture_objective(0)
	manager.resolve_objective_turn(0)
	manager.resolve_objective_turn(0)
	assert_eq(manager.objective_control_turns, 1)
	assert_true(manager.clear_objective_control())
	assert_eq(manager.objective_controller, ResourceManager.NO_PLAYER)
	assert_eq(manager.objective_control_turns, 0)
	assert_false(manager.objective_upkeep_due)
	assert_false(manager.clear_objective_control(), "clearing an uncontrolled Objective is a no-op")


func test_scavenger_cost_uses_fibonacci_progression():
	var scavenger: UnitType = load("res://assets/data/armies/TheCoreborn/tier-1/battlefield_scavenger.tres")
	var costs: Array[int] = []
	for existing_count in range(6):
		costs.append(scavenger.get_cost(existing_count))
	assert_eq(costs, [1, 2, 3, 5, 8, 13])
