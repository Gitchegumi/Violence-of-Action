extends GutTest

# Verifies the real asset pipeline the deploy radial depends on: the Shard
# Walker UnitType loads from the troop catalog with the expected fields.

var TroopManagerScript = preload("res://scripts/troop_manager.gd")
var TileMapScript = preload("res://scripts/tile_map.gd")
var MockUnit = preload("res://tests/unit/mock_unit.gd")
var MainScene = preload("res://scenes/main.tscn")

func _gameplay_tile_map():
	var main = MainScene.instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	return main.get_node("TileMapLayer")

func _land_tiles(tile_map, required: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in tile_map.terrain_data_map:
		var terrain: TerrainType = tile_map.terrain_data_map[coord]
		if terrain != null and terrain.passable_by == "land":
			result.append(coord)
			if result.size() == required:
				break
	return result

func test_shard_walker_loads_from_catalog():
	var tm = TroopManagerScript.new()
	add_child_autofree(tm)
	await get_tree().process_frame  # let _ready populate the catalog
	assert_true(tm.catalog.has("shard_walker"), "catalog loads the shard_walker UnitType")
	var data = tm.catalog.get("shard_walker")
	assert_eq(data.unit_name, "Shardwalker")
	assert_eq(data.get_cost(0), 2, "Shard Walker cost matches GAME_RULES.md")

func test_shard_walker_resource_fields():
	var data = load("res://assets/data/armies/TheCoreborn/tier-1/shard_walker.tres")
	assert_not_null(data, "shard_walker.tres loads")
	assert_eq(data.unit_role, "Core Infantry")
	assert_true(data.stats_block.has("health"), "stats_block has health")
	assert_false(data.can_upgrade, "upgrade mechanics remain disabled while GAME_RULES.md marks them TBD")
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

func test_unsafe_upgrade_path_stays_disabled_without_spending():
	var tile_map = await _gameplay_tile_map()
	var upgraded := UnitType.new()
	upgraded.unit_name = "Upgrade Target"
	var source := UnitType.new()
	source.unit_name = "Upgradeable Unit"
	source.can_upgrade = true
	source.upgrade_cost = 3
	source.upgrades_to = upgraded
	var mock = MockUnit.new()
	mock.unit_data = source
	var actions: Array = tile_map._build_unit_actions(mock)
	var upgrade_action: Dictionary = actions.filter(func(action): return action.action_id == "upgrade")[0]
	assert_false(upgrade_action.enabled, "upgrade fails closed without authoritative combat safety state")
	var starting_essence: int = tile_map.get_player_essence()
	tile_map._upgrade_unit(mock, Vector2i.ZERO)
	assert_eq(tile_map.get_player_essence(), starting_essence, "rejected upgrade spends no essence")
	assert_same(mock.get_unit_data(), source, "rejected upgrade does not change unit data")
	mock.free()

func test_successive_dynamic_cost_deployments_revalidate_live_unit_count():
	var tile_map = await _gameplay_tile_map()
	var scavenger: UnitType = tile_map.troop_manager.catalog.get("battlefield_scavenger")
	assert_not_null(scavenger, "production catalog exposes Battlefield Scavenger data")
	var land_tiles := _land_tiles(tile_map, 2)
	assert_eq(land_tiles.size(), 2, "generated map has two deployable land tiles")
	var stale_quote: Dictionary = tile_map._unit_type_to_dict("battlefield_scavenger", scavenger)
	assert_eq(stale_quote.unit_cost, 1, "first Scavenger quote uses first Fibonacci price")
	tile_map.current_radial_units = [stale_quote]
	tile_map._on_radial_unit_selected("battlefield_scavenger", land_tiles[0])
	assert_eq(tile_map.get_player_essence(), 11)
	assert_eq(tile_map.troop_manager.count_units("battlefield_scavenger", 0), 1)
	# Reuse the stale 1-Essence quote: confirmation must resolve the live cost as 2.
	tile_map.current_radial_units = [stale_quote]
	tile_map._on_radial_unit_selected("battlefield_scavenger", land_tiles[1])
	assert_eq(tile_map.get_player_essence(), 9, "second Scavenger charges the live Fibonacci price")
	assert_eq(tile_map.troop_manager.count_units("battlefield_scavenger", 0), 2)
