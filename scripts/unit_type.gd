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

## Essence cost to play the unit
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
	"water": null
}

## Any Special Abilities
@export var special_abilities: Array[String] = []
