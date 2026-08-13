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
		"abilities": ["Heals adjacent allies", "Can construct temporary barriers"],
	},
	"ghostthorn": {
		"name": "Ghostthorn",
		"role": "Special Forces",
		"description": "Stealthy infiltrators using teleportation tech.",
		"cost": 8,
		"cost_type": "standard",
		"stats": {"health": 2, "attack": 2, "range": 1, "armor": 0, "speed": 5},
		"terrain": {"field": 1, "forest": 1, "water": -1, "mountain": -1},
		"abilities": ["Can teleport up to 3 hexes once per game"],
	},
	"golemancer_hull": {
		"name": "Golemancer Hull",
		"role": "Heavy Armor",
		"description": "Massive exo-shell driven by arcane tech. Slow, powerful, and resilient.",
		"cost": 8,
		"cost_type": "standard",
		"stats": {"health": 5, "attack": 3, "range": 1, "armor": 2, "speed": 2},
		"terrain": {"field": 1, "forest": 2, "water": -1, "mountain": 10},
		"abilities": ["Splash damage in adjacent hexes"],
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
		"abilities": ["Ignores terrain penalties", "May move again after combat once per game"],
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


func test_every_documented_tier_one_profile_matches_game_rules():
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
