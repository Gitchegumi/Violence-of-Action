extends GutTest

var TileMapScene = preload("res://scenes/tileMap.tscn")
var TileMapScript = preload("res://scripts/tile_map.gd")
var field: TerrainType
var forest: TerrainType
var mountain: TerrainType
var objective: TerrainType


func before_each():
	GameSession.clear_match_config()
	field = load("res://assets/data/terrain_types/field.tres")
	forest = load("res://assets/data/terrain_types/forest.tres")
	mountain = load("res://assets/data/terrain_types/mountain.tres")
	objective = load("res://assets/data/terrain_types/objective.tres")


func after_each():
	GameSession.clear_match_config()


func _generated_map(players: int, seed_value: int):
	GameSession.set_match_config({"player_count": players, "seed": seed_value})
	var tile_map = TileMapScene.instantiate()
	add_child_autofree(tile_map)
	return tile_map


func _path_costs(tile_map) -> Array[int]:
	return tile_map.get_zone_path_costs(
		tile_map.terrain_data_map,
		tile_map.deployment_zones_data,
		Vector2i(6, 7)
	)


func test_fixed_two_player_seed_has_equal_weighted_objective_paths():
	var tile_map = _generated_map(2, 20260813)
	var costs := _path_costs(tile_map)
	assert_eq(costs.size(), 2)
	assert_eq(costs[0], costs[1], "two-player starts have equal movement-point distance")
	assert_true(tile_map.are_zone_paths_fair(costs, 2))


func test_fixed_three_player_seed_has_equal_weighted_objective_paths():
	var tile_map = _generated_map(3, 424242)
	var costs := _path_costs(tile_map)
	assert_eq(costs.size(), 3)
	for zone in tile_map.deployment_zones_data:
		for coordinate in zone:
			assert_true(tile_map.terrain_data_map.has(coordinate), "deployment tile is on the generated map")
			assert_eq(tile_map._hex_distance(coordinate, Vector2i(6, 7)), 8, "deployment tile stays on the outer ring")
	assert_eq(costs.min(), costs.max(), "three-player starts are equal when repair is possible")
	assert_true(tile_map.are_zone_paths_fair(costs, 3))


func test_weighted_validation_detects_unfair_terrain_costs():
	var tile_map = TileMapScript.new()
	tile_map.objective_type = objective
	var terrain_map := {
		Vector2i(-2, 0): field,
		Vector2i(-1, 0): field,
		Vector2i(2, 0): mountain,
		Vector2i(1, 0): mountain,
	}
	var zones := [[Vector2i(-2, 0)], [Vector2i(2, 0)]]
	var costs := tile_map.get_zone_path_costs(terrain_map, zones, Vector2i.ZERO)
	assert_eq(costs, [2, 6], "terrain entry costs affect shortest paths")
	assert_false(tile_map.are_zone_paths_fair(costs, 2), "unequal weighted paths are rejected")
	tile_map.free()


func test_deterministic_repair_swaps_terrain_and_preserves_distribution():
	var tile_map = TileMapScript.new()
	tile_map.objective_type = objective
	var repair_terrains: Array[TerrainType] = [field, mountain]
	tile_map.terrain_types = repair_terrains
	var terrain_map := {
		Vector2i(-2, 0): field,
		Vector2i(-1, 0): field,
		Vector2i(2, 0): mountain,
		Vector2i(1, 0): mountain,
		Vector2i(-10, 10): field,
		Vector2i(-11, 11): field,
	}
	var zones := [[Vector2i(-2, 0)], [Vector2i(2, 0)]]
	var field_count_before := terrain_map.values().count(field)
	var mountain_count_before := terrain_map.values().count(mountain)
	assert_true(tile_map._ensure_fair_paths_to_objective(terrain_map, zones, Vector2i.ZERO))
	var costs := tile_map.get_zone_path_costs(terrain_map, zones, Vector2i.ZERO)
	assert_eq(costs, [2, 2], "repair creates equal minimum-cost corridors")
	assert_eq(terrain_map.values().count(field), field_count_before, "field distribution is preserved")
	assert_eq(terrain_map.values().count(mountain), mountain_count_before, "mountain distribution is preserved")
	tile_map.free()


func test_equalizable_one_point_tolerance_is_rejected_when_repair_cannot_prove_equality():
	var tile_map = TileMapScript.new()
	tile_map.objective_type = objective
	var repair_terrains: Array[TerrainType] = [field, forest]
	tile_map.terrain_types = repair_terrains
	var terrain_map := {
		Vector2i(-2, 0): field,
		Vector2i(-1, 0): field,
		Vector2i(2, 0): field,
		Vector2i(1, 0): forest,
		Vector2i(0, 2): field,
		Vector2i(0, 1): forest,
		Vector2i(10, -10): forest,
	}
	var zones := [
		[Vector2i(-2, 0)],
		[Vector2i(2, 0)],
		[Vector2i(0, 2)],
	]
	var original := terrain_map.duplicate()
	var costs := tile_map.get_zone_path_costs(terrain_map, zones, Vector2i.ZERO)
	assert_eq(costs, [2, 3, 3])
	assert_true(tile_map.are_zone_paths_fair(costs, 3), "one-point spread is within tolerance")
	assert_false(
		tile_map._ensure_fair_paths_to_objective(terrain_map, zones, Vector2i.ZERO),
		"candidate is rejected because failed lowering does not prove equality impossible"
	)
	assert_eq(terrain_map, original, "failed atomic repair does not partially mutate the candidate")
	tile_map.free()


func test_equal_seed_reproduces_repaired_three_player_map():
	var first = _generated_map(3, 8675309)
	var first_snapshot := _snapshot(first)
	var second = _generated_map(3, 8675309)
	assert_eq(_snapshot(second), first_snapshot)


func _snapshot(tile_map) -> Array[String]:
	var coordinates: Array = tile_map.terrain_data_map.keys()
	coordinates.sort_custom(func(a: Vector2i, b: Vector2i):
		return a.x < b.x or (a.x == b.x and a.y < b.y)
	)
	var result: Array[String] = []
	for coordinate in coordinates:
		result.append("%s:%s" % [coordinate, tile_map.terrain_data_map[coordinate].terrain_name])
	return result
