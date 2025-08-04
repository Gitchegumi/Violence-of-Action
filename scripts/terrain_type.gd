extends Resource
class_name TerrainType

## The display name of the terrain.
@export var terrain_name: String = "Unnamed"

## The coordinate of the tile in the tileset atlas.
@export var atlas_coord: Vector2i = Vector2i(0, 0)

## The movement cost to enter this tile.
@export var move_cost: int = 1

## How many of this tile should be on the map. Used for distribution.
@export var distribution_count: int = 0

## The type of unit movement required to cross this tile (e.g., "land", "water-crossing").
@export var passable_by: String = "land"

## The cost to hold this tile, if applicable.
@export var essence_cost_to_hold: int = 0
