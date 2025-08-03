extends TileMapLayer

# Enum for terrain types to make the code more readable.
enum TerrainType { FIELD, FOREST, WATER, MOUNTAIN, OBJECTIVE }

# The distribution of terrain tiles as specified in GAME_RULES.md.
const TILE_DISTRIBUTION = {
	TerrainType.FIELD: 62,
	TerrainType.FOREST: 61,
	TerrainType.WATER: 53,
	TerrainType.MOUNTAIN: 40,
}

const TERRAIN_TO_ATLAS_COORD = {
	TerrainType.FIELD: Vector2i(6, 0),
	TerrainType.FOREST: Vector2i(7, 0),
	TerrainType.WATER: Vector2i(0, 0),
	TerrainType.MOUNTAIN: Vector2i(8, 0),
	TerrainType.OBJECTIVE: Vector2i(3, 0)
}

# The radius of the hexagonal map in tiles.
const MAP_RADIUS = 8

func _ready():
	_generate_map()

# Generates the entire hex grid based on the specified radius and tile distribution.
func _generate_map():
	# Clear the existing map before generating a new one.
	clear()

	# Create a pool of terrain tiles based on the distribution.
	var tile_pool = []
	for terrain_type in TILE_DISTRIBUTION:
		var count = TILE_DISTRIBUTION[terrain_type]
		for i in range(count):
			tile_pool.append(terrain_type)
	
	# Shuffle the pool for random placement.
	tile_pool.shuffle()

	var tile_set_source_id = 0
	var center_pos = Vector2i(6, 7)

	# Place the objective tile at the center first.
	var objective_atlas_coord = TERRAIN_TO_ATLAS_COORD[TerrainType.OBJECTIVE]
	set_cell(center_pos, tile_set_source_id, objective_atlas_coord)
	var tiles_placed = 1
	print("Placing Objective at: ", center_pos, " with atlas: ", objective_atlas_coord)

	# Get all coordinates and remove the center
	var coordinates = _get_hex_coordinates_in_radius(MAP_RADIUS, center_pos)
	coordinates.erase(center_pos)

	# Sort coordinates to create a clockwise spiral
	coordinates.sort_custom(func(a, b):
		var rel_a = a - center_pos
		var rel_b = b - center_pos

		# Calculate distance (ring number) from the center
		var dist_a = (abs(rel_a.x) + abs(rel_a.y) + abs(-rel_a.x - rel_a.y)) / 2
		var dist_b = (abs(rel_b.x) + abs(rel_b.y) + abs(-rel_b.x - rel_b.y)) / 2
		if dist_a != dist_b:
			return dist_a < dist_b
		
		# If on the same ring, sort by angle (clockwise)
		# We use atan2 on approximated cartesian coordinates for sorting.
		var angle_a = atan2(rel_a.y + rel_a.x * 0.5, rel_a.x)
		var angle_b = atan2(rel_b.y + rel_b.x * 0.5, rel_b.x)
		return angle_a < angle_b
	)

	# Place the rest of the tiles in spiral order
	for coord in coordinates:
		if not tile_pool.is_empty():
			var terrain_type = tile_pool.pop_front()
			var atlas_coord = TERRAIN_TO_ATLAS_COORD[terrain_type]
			set_cell(coord, tile_set_source_id, atlas_coord)
			tiles_placed += 1
			print("Placing tile at: ", coord, " with atlas: ", atlas_coord)
		else:
			# This fallback should not be reached if the tile distribution
			# and radius are correct (216 tiles + 1 objective = 217 total).
			print("Error: Tile pool is empty but coordinates remain.")
			break
	
	print("Total tiles placed: ", tiles_placed)

# Returns an array of Vector2i coordinates for all tiles in a hex grid of a given radius.
# This uses the "axial coordinates" system for hex grids.
func _get_hex_coordinates_in_radius(radius: int, center: Vector2i = Vector2i(0, 0)) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			coords.append(center + Vector2i(q, r))
	return coords

@export var camera_speed = 400.0
@onready var camera = $Camera2D

func _process(delta):
	if camera:
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		camera.position += input_dir * camera_speed * delta
