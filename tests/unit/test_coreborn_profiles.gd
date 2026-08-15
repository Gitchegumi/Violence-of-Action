extends GutTest

const PROFILE_DIR := "res://assets/data/armies/TheCoreborn/tier-1/"

const EXPECTED_PROFILES := {
	"battlefield_scavenger": {
		"name": "Battlefield Scavenger",
		"role": "Scavenger",
		"description": "A unit that profits from destruction on the battlefield.",
		"cost": 1,
		"cost_type": "fibonacci",
		"stats": {"health": 1, "attack": 1, "range": 1, "armor": 0, "speed": 3},
		"terrain": {"field": 1, "forest": 2, "water": -1, "mountain": -1},
		"abilities": [
			"This unit's only method of generating essence. See GAME_RULES.md for scaling cost. Gains 3 essence for each unit (friendly or enemy) destroyed since the beginning of the player's last turn. This includes units destroyed during their own turn and during opponent turns between turns.",
		],
	},
	"fluxsmith": {
		"name": "Fluxsmith",
		"role": "Engineer / Support",
		"description": "Support unit with healing and terrain-altering abilities.",
		"cost": 4,
		"cost_type": "standard",
		"stats": {"health": 2, "attack": 1, "range": 1, "armor": 0, "speed": 3},
		"terrain": {"field": 1, "forest": 2, "water": -1, "mountain": -1},
		"abilities": ["Heal 1 HP on an adjacent ally instead of attacking", "Erect an adjacent 1 HP / 2 Armor barrier instead of attacking"],
	},
	"ghostthorn": {
		"name": "Ghostthorn",
		"role": "Special Forces",
		"description": "Stealthy infiltrators using teleportation tech.",
		"cost": 8,
		"cost_type": "standard",
		"stats": {"health": 2, "attack": 2, "range": 1, "armor": 0, "speed": 5},
		"terrain": {"field": 1, "forest": 1, "water": -1, "mountain": -1},
		"abilities": ["Free once-per-game teleport up to 3 hexes to an unoccupied non-Water tile"],
	},
	"golemancer_hull": {
		"name": "Golemancer Hull",
		"role": "Heavy Armor",
		"description": "Massive exo-shell driven by arcane tech. Slow, powerful, and resilient.",
		"cost": 8,
		"cost_type": "standard",
		"stats": {"health": 5, "attack": 3, "range": 1, "armor": 2, "speed": 2},
		"terrain": {"field": 1, "forest": 2, "water": -1, "mountain": 10},
		"abilities": ["A primary hit checks the same attack roll against adjacent enemies"],
	},
	"shard_walker": {
		"name": "Shardwalker",
		"role": "Core Infantry",
		"description": "Light troops augmented with crystal tech for standard mobility.",
		"cost": 2,
		"cost_type": "standard",
		"stats": {"health": 3, "attack": 1, "range": 1, "armor": 0, "speed": 4},
		"terrain": {"field": 1, "forest": 2, "water": -1, "mountain": -1},
		"abilities": [],
	},
	"sky_render": {
		"name": "Skyrender",
		"role": "All-Terrain Flanker",
		"description": "Hovering drone-rider capable of crossing all terrain types.",
		"cost": 12,
		"cost_type": "standard",
		"stats": {"health": 3, "attack": 2, "range": 2, "armor": 1, "speed": 6},
		"terrain": {"field": 1, "forest": 1, "water": 1, "mountain": 1},
		"abilities": ["Ignores terrain penalties", "Once per game, may take one unsplittable full-speed move after attacking", "Carries one Shardwalker, Ghostthorn, or Fluxsmith; load and unload each cost 3 movement"],
	},
	"tide_born": {
		"name": "Tideborn",
		"role": "Amphibious Unit",
		"description": "Bio-engineered aquatic troopers with amphibious mobility.",
		"cost": 4,
		"cost_type": "standard",
		"stats": {"health": 2, "attack": 2, "range": 1, "armor": 0, "speed": 3},
		"terrain": {"field": 1, "forest": 2, "water": 1, "mountain": -1},
		"abilities": [],
	},
}


func test_every_tier_one_profile_matches_authoritative_expectations():
	var directory := DirAccess.open(PROFILE_DIR)
	assert_not_null(directory)
	var resource_ids: Array[String] = []
	for filename in directory.get_files():
		if filename.ends_with(".tres"):
			resource_ids.append(filename.get_basename())
	resource_ids.sort()
	var expected_ids: Array = EXPECTED_PROFILES.keys()
	expected_ids.sort()
	assert_eq(resource_ids, expected_ids, "every Tier 1 resource has an authoritative expected profile")

	for unit_id in expected_ids:
		var expected: Dictionary = EXPECTED_PROFILES[unit_id]
		var actual: UnitType = load(PROFILE_DIR + unit_id + ".tres")
		assert_not_null(actual, "%s resource loads" % unit_id)
		assert_eq(actual.unit_name, expected.name, "%s name" % unit_id)
		assert_eq(actual.unit_role, expected.role, "%s role" % unit_id)
		assert_eq(actual.unit_tier, 1, "%s tier" % unit_id)
		assert_eq(actual.unit_description, expected.description, "%s description" % unit_id)
		assert_eq(actual.unit_cost_type, expected.cost_type, "%s cost type" % unit_id)
		assert_eq(actual.get_cost(0), expected.cost, "%s initial cost" % unit_id)
		assert_eq(actual.stats_block, expected.stats, "%s stats" % unit_id)
		assert_eq(actual.terrain_type_matrix, expected.terrain, "%s terrain matrix" % unit_id)
		assert_eq(Array(actual.special_abilities), expected.abilities, "%s abilities" % unit_id)
		assert_false(actual.can_upgrade, "%s upgrade remains disabled while rules are TBD" % unit_id)
		assert_eq(actual.upgrade_cost, -1, "%s has no guessed upgrade cost" % unit_id)
		assert_null(actual.upgrades_to, "%s has no guessed upgrade path" % unit_id)


func test_army_codex_profile_table_matches_live_resources() -> void:
	var file := FileAccess.open("res://docs/ARMY_CODEX.md", FileAccess.READ)
	assert_not_null(file, "Army Codex is readable")
	var rows: Dictionary = {}
	var in_profile_table := false
	while not file.eof_reached():
		var line := file.get_line()
		if line == "<!-- CODEX_PROFILE_TABLE_START -->":
			in_profile_table = true
			continue
		if line == "<!-- CODEX_PROFILE_TABLE_END -->":
			break
		if not in_profile_table or not line.begins_with("|"):
			continue
		var columns := line.split("|", false)
		if columns.size() != 15:
			continue
		var unit_id := columns[0].strip_edges()
		if unit_id in ["Unit ID", "---"]:
			continue
		rows[unit_id] = Array(columns).map(func(value): return value.strip_edges())

	var expected_ids: Array = EXPECTED_PROFILES.keys()
	expected_ids.sort()
	var codex_ids: Array = rows.keys()
	codex_ids.sort()
	assert_eq(codex_ids, expected_ids, "Codex documents every live Tier 1 profile exactly once")
	for unit_id in expected_ids:
		var actual: UnitType = load(PROFILE_DIR + unit_id + ".tres")
		var row: Array = rows[unit_id]
		assert_eq(row[1], actual.unit_name, "%s Codex name" % unit_id)
		assert_eq(row[2], actual.unit_role, "%s Codex role" % unit_id)
		assert_eq(int(row[3]), actual.unit_tier, "%s Codex tier" % unit_id)
		assert_eq(row[4], actual.unit_cost_type, "%s Codex cost type" % unit_id)
		assert_eq(int(row[5]), actual.unit_cost, "%s Codex cost" % unit_id)
		for comparison in [
			[6, "health"], [7, "attack"], [8, "range"], [9, "armor"], [10, "speed"],
		]:
			assert_eq(int(row[comparison[0]]), int(actual.stats_block[comparison[1]]), "%s Codex %s" % [unit_id, comparison[1]])
		for comparison in [[11, "field"], [12, "forest"], [13, "mountain"], [14, "water"]]:
			assert_eq(int(row[comparison[0]]), int(actual.terrain_type_matrix[comparison[1]]), "%s Codex %s" % [unit_id, comparison[1]])
