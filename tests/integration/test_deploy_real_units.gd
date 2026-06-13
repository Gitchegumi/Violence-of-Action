extends GutTest

# Verifies the real asset pipeline the deploy radial depends on: the Shard
# Walker UnitType loads from the troop catalog with the expected fields.

var TroopManagerScript = preload("res://scripts/troop_manager.gd")
var TileMapScript = preload("res://scripts/tile_map.gd")
var MockUnit = preload("res://tests/unit/mock_unit.gd")

func test_shard_walker_loads_from_catalog():
	var tm = TroopManagerScript.new()
	add_child_autofree(tm)
	await get_tree().process_frame  # let _ready populate the catalog
	assert_true(tm.catalog.has("shard_walker"), "catalog loads the shard_walker UnitType")
	var data = tm.catalog.get("shard_walker")
	assert_eq(data.unit_name, "Shard Walker")
	assert_eq(data.get_cost(0), 1, "Shard Walker costs 1 essence")

func test_shard_walker_resource_fields():
	var data = load("res://assets/data/armies/TheCoreborn/tier-1/shard_walker.tres")
	assert_not_null(data, "shard_walker.tres loads")
	assert_eq(data.unit_role, "Core Infantry")
	assert_true(data.stats_block.has("health"), "stats_block has health")
	assert_true(data.can_upgrade, "Shard Walker can upgrade")
	# No upgrade target wired yet -> the Upgrade action should render disabled.
	assert_null(data.upgrades_to, "no upgrade target set yet")

func test_occupied_tile_actions_are_attack_move_upgrade_inspect():
	var tm = TileMapScript.new()  # not added to tree: avoids scene-only @onready
	var mock = MockUnit.new()
	mock.unit_data = load("res://assets/data/armies/TheCoreborn/tier-1/shard_walker.tres")
	var actions = tm._build_unit_actions(mock)
	var ids := []
	for a in actions:
		ids.append(a.action_id)
	assert_eq(actions.size(), 4, "four action options")
	assert_true(ids.has("attack") and ids.has("move") and ids.has("upgrade") and ids.has("inspect"),
		"actions are Attack/Move/Upgrade/Inspect")
	for a in actions:
		if a.action_id == "upgrade":
			assert_false(a.enabled, "Upgrade disabled (Shard Walker has no upgrade target)")
		else:
			assert_true(a.enabled, "%s enabled" % a.action_id)
	mock.free()
	tm.free()
