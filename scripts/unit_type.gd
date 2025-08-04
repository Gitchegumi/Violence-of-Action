extends Resource
class_name UnitType

## The display name of the unit.
@export var unit_name: String = "Unnamed"

## The Unit's combat role
@export var unit_role: String = "Undefined"

## The Unit's upgrade tier
@export var unit_tier: int = 1

## Is the unit upgradable?
@export var can_upgrade: bool = true

## The essence cost to upgrade
@export var upgrade_cost: int = 0

## Upgrades to which unit?
@export var upgrades_to: UnitType

## Unit Description
@export var unit_description: String = "Description"

## Essence cost to play the unit. Can be an integer or a string for dynamic costs.
@export var unit_cost_type: String = "standard"
@export var unit_cost: int = 0

## The Unit's Stats Block
@export var stats_block: Dictionary = {
	"health": 0,
	"attack": 0,
	"range": 0,
	"armor": 0,
	"speed": 0
}

## The Units ability to traverse terrain
@export var terrain_type_matrix: Dictionary = {
	"field": 1,
	"forest": 2,
	"mountain": 5,
	"water": 0
}

## Any Special Abilities
@export var special_abilities: Array[String] = []


func _init(
	p_unit_name: String,
	p_unit_role: String,
	p_unit_tier: int,
	p_can_upgrade: bool,
	p_upgrade_cost: int,
	p_upgrades_to: UnitType,
	p_unit_description: String,
	p_unit_cost_data: Variant,
	p_stats_block: Dictionary,
	p_terrain_type_matrix: Dictionary,
	p_special_abilities: Array[String]
):
	unit_name = p_unit_name
	unit_role = p_unit_role
	unit_tier = p_unit_tier
	can_upgrade = p_can_upgrade
	upgrade_cost = p_upgrade_cost
	upgrades_to = p_upgrades_to
	unit_description = p_unit_description
	if p_unit_cost_data is int:
		unit_cost_type = "standard"
		unit_cost = p_unit_cost_data
	elif p_unit_cost_data is String:
		unit_cost_type = p_unit_cost_data
		unit_cost = 0
	stats_block = p_stats_block
	terrain_type_matrix = p_terrain_type_matrix
	special_abilities = p_special_abilities


## Gets the cost of the unit.
## p_unit_count: The number of units of this type already in play.
func get_cost(p_unit_count: int = 0) -> int:
	if unit_cost_type == "standard":
		return unit_cost
	elif unit_cost_type == "fibonacci":
		return fibonacci(p_unit_count + 1)
	return 0 # Default case for unknown cost types


# Calculates the nth Fibonacci number.
func fibonacci(n: int) -> int:
	if n <= 0:
		return 0
	var a = 0
	var b = 1
	for _i in range(n - 1):
		var temp = a
		a = b
		b = temp + b
	return b
