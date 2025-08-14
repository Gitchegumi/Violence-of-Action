extends TileMapLayer

# The radius of the hexagonal map in tiles.
const MAP_RADIUS = 8
const PLAYER_COUNT = 2 # Can be 2 or 3

## An array to hold all the TerrainType resources (.tres files).
## Assign these in the Godot Inspector.
@export var terrain_types: Array[TerrainType]

## The resource for the central objective tile.
## Assign this in the Godot Inspector.
@export var objective_type: TerrainType

# --- Troop Placement Integration ---
@onready var troop_manager = preload("res://scripts/troop_manager.gd").new()

# --- Built-in Godot Functions ---

func _ready():
	_generate_map()
	# Wire up the troop manager (keeps mechanics out of main.gd)
	add_child(troop_manager)
	troop_manager.tile_map = self

# --- Map Generation ---

# Generates the entire hex grid using a noise map and ensures player path validity.
func _generate_map():
	if terrain_types.is_empty() or not objective_type:
		print("Error: TerrainType resources are not assigned in the Inspector.")
		return

	clear()
	var tile_set_source_id = 0
	var center_pos = Vector2i(6, 7)

	# --- 1. Generate Noise-Based Terrain ---
	var terrain_map = _generate_noise_terrain(center_pos)

	# --- 2. Define Deployment Zones and Ensure They Are Passable ---
	var deployment_zones = _get_deployment_zones(center_pos)
	_ensure_passable_zones(terrain_map, deployment_zones)

	# --- 3. Validate and Carve Paths to Objective ---
	_ensure_paths_to_objective(terrain_map, deployment_zones, center_pos)

	# --- 4. Place Tiles on the Map ---
	self.terrain_data_map = terrain_map # Make the map data available for selection logic
	for coord in terrain_map:
		var terrain: TerrainType = terrain_map[coord]
		set_cell(coord, tile_set_source_id, terrain.atlas_coord)

	# --- 5. Place the Objective Tile ---
	set_cell(center_pos, tile_set_source_id, objective_type.atlas_coord)
	
	print("Total tiles placed: ", terrain_map.size() + 1)


# Creates the initial terrain layout using Perlin noise.
func _generate_noise_terrain(center: Vector2i) -> Dictionary:
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.03
	noise.seed = randi()

	var coordinates = _get_concentric_hex_rings(MAP_RADIUS, center)
	var noise_data = []
	for coord in coordinates:
		var noise_value = noise.get_noise_2d(coord.x, coord.y)
		noise_data.append({ "coord": coord, "noise": noise_value })

	noise_data.sort_custom(func(a, b): return a.noise < b.noise)

	var tile_pool = []
	for type in terrain_types:
		for i in range(type.distribution_count):
			tile_pool.append(type)
	
	# Sort the pool by passability to ensure water/mountains are placed first
	tile_pool.sort_custom(func(a, b): return a.passable_by > b.passable_by)

	var terrain_map = {}
	for i in range(noise_data.size()):
		if i < tile_pool.size():
			terrain_map[noise_data[i].coord] = tile_pool[i]
		else:
			print("Warning: Not enough tiles in the pool to fill the map.")
			break
			
	return terrain_map


# --- Pathfinding and Validation ---

# Ensures a valid path from each deployment zone to the objective.
func _ensure_paths_to_objective(terrain_map: Dictionary, zones: Array, objective: Vector2i):
	for zone_coords in zones:
		var path_found = false
		for start_coord in zone_coords:
			if _find_path(start_coord, objective, terrain_map):
				path_found = true
				break
		
		if not path_found:
			print("No path found for a zone. Carving a path...")
			var best_start = zone_coords[0]
			for coord in zone_coords:
				if coord.distance_to(objective) < best_start.distance_to(objective):
					best_start = coord
			_carve_path(best_start, objective, terrain_map)

# Carves a path by swapping blocking tiles with passable ones.
func _carve_path(start: Vector2i, end: Vector2i, terrain_map: Dictionary):
	var path_coords = _get_line_path(start, end)
	var swappable_coords = []
	for coord in terrain_map:
		var type: TerrainType = terrain_map[coord]
		if type.passable_by == "land":
			swappable_coords.append(coord)
	
	swappable_coords.shuffle()

	for coord in path_coords:
		if terrain_map.has(coord):
			var current_type: TerrainType = terrain_map[coord]
			if current_type.passable_by != "land":
				if not swappable_coords.is_empty():
					var swap_with = swappable_coords.pop_front()
					terrain_map[coord] = terrain_map[swap_with]
					terrain_map[swap_with] = current_type
				else:
					print("Warning: Ran out of swappable tiles. Could not carve full path.")
					break

# Simple Breadth-First Search to check for a path.
func _find_path(start: Vector2i, end: Vector2i, terrain_map: Dictionary) -> bool:
	var queue = [start]
	var visited = {start: true}
	
	while not queue.is_empty():
		var current = queue.pop_front()
		if current == end:
			return true
			
		for neighbor in _get_neighbors(current):
			if terrain_map.has(neighbor) and not visited.has(neighbor):
				var type: TerrainType = terrain_map[neighbor]
				if type.passable_by == "land" or neighbor == end:
					visited[neighbor] = true
					queue.append(neighbor)
	return false

# --- Coordinate and Zone Helpers ---

# Gets the coordinates for deployment zones based on player count.
func _get_deployment_zones(center: Vector2i) -> Array:
	var zones = []
	var r = MAP_RADIUS

	if PLAYER_COUNT == 2:
		var zone_nw = []; var zone_se = []
		for i in range(r):
			zone_nw.append(center + Vector2i(-r + i, -i))
			zone_se.append(center + Vector2i(r - i, i))
		zones.append(zone_nw); zones.append(zone_se)
	else: # 3 Players
		var zone_n = []; var zone_se = []; var zone_sw = []
		for i in range(r):
			zone_n.append(center + Vector2i(i, -r))
			zone_se.append(center + Vector2i(r, i))
			zone_sw.append(center + Vector2i(-r + i, r - i))
		zones.append(zone_n); zones.append(zone_se); zones.append(zone_sw)
		
	return zones

# Ensures all tiles in the deployment zones are passable.
func _ensure_passable_zones(terrain_map: Dictionary, zones: Array):
	var all_zone_coords = []
	for zone in zones:
		for coord in zone:
			all_zone_coords.append(coord)

	var swappable_coords = []
	for coord in terrain_map:
		if not coord in all_zone_coords:
			var type: TerrainType = terrain_map[coord]
			if type.passable_by == "land":
				swappable_coords.append(coord)
	
	swappable_coords.shuffle()

	for zone in zones:
		for coord in zone:
			if terrain_map.has(coord):
				var current_type: TerrainType = terrain_map[coord]
				if current_type.passable_by != "land":
					if not swappable_coords.is_empty():
						var swap_with = swappable_coords.pop_front()
						terrain_map[coord] = terrain_map[swap_with]
						terrain_map[swap_with] = current_type
					else:
						print("Warning: Ran out of swappable tiles for deployment zone.")
						break

# Returns an array of Vector2i coordinates for all tiles in concentric hex rings.
func _get_concentric_hex_rings(radius: int, center: Vector2i) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	if radius <= 0: return coords

	const STEP_DIRECTIONS = [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)
	]

	for r in range(1, radius + 1):
		var current_pos = center + r * Vector2i(0, -1)
		for i in range(6):
			var direction = STEP_DIRECTIONS[i]
			for j in range(r):
				coords.append(current_pos)
				current_pos += direction
	return coords

# Gets the 6 neighbors of a hex tile.
func _get_neighbors(coord: Vector2i) -> Array:
	const NEIGHBOR_VECTORS = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1),
		Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 1)
	]
	var neighbors = []
	for vec in NEIGHBOR_VECTORS:
		neighbors.append(coord + vec)
	return neighbors

# Returns a line of coordinates from start to end (for path carving).
func _get_line_path(start: Vector2i, end: Vector2i) -> Array:
	var line_coords = []
	var n = start.distance_to(end)
	if n == 0: return []
	for i in range(int(n) + 1):
		var t = float(i) / n
		var interpolated = Vector2(start).lerp(Vector2(end), t)
		line_coords.append(Vector2i(round(interpolated.x), round(interpolated.y)))
	return line_coords


# --- Camera Controls ---

@export var camera_speed = 400.0
@onready var camera = $Camera2D

func _process(delta):
	if camera:
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		camera.position += input_dir * camera_speed * delta

# --- Selection and Input Handling ---

@onready var selection_layer = get_node("SelectionLayer")
var selected_tile = Vector2i(-1, -1) # Off-map coordinate by default
var is_dragging = false

# This dictionary will be populated in _generate_map
var terrain_data_map: Dictionary = {}

func _unhandled_input(event):
	# Handle right-click button press/release for camera dragging
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		is_dragging = event.is_pressed()

	# Handle mouse motion for dragging
	if event is InputEventMouseMotion and is_dragging:
		camera.position -= event.relative

	# Handle left-click for tile selection
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		is_dragging = false
		
		var map_pos = local_to_map(get_local_mouse_position())
		
		if get_cell_source_id(map_pos) != -1:
			var terrain: TerrainType = terrain_data_map.get(map_pos)
			
			selection_layer.clear()
			selected_tile = map_pos
			
			selection_layer.set_cell(selected_tile, 0, objective_type.atlas_coord)
			
			if terrain:
				var info = str("Selected: ", terrain.terrain_name, ", Cost: ", terrain.move_cost)
				if terrain.essence_cost_to_hold > 0:
					info += str(", Essence Cost: ", terrain.essence_cost_to_hold)
				if terrain.passable_by != "land":
					info += str(", Requires: ", terrain.passable_by)
				print(info)
			else:
				# This could happen if the objective tile is selected
				if map_pos == Vector2i(6,7):
					var info = str("Selected: ", objective_type.terrain_name, ", Cost: ", objective_type.move_cost)
					if objective_type.essence_cost_to_hold > 0:
						info += str(", Essence Cost: ", objective_type.essence_cost_to_hold)
					print(info)
				else:
					print("Selected tile: ", selected_tile, " (Unknown Terrain)")
	
	# Press P to place a unit on the currently selected tile (if valid)
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		if selected_tile != Vector2i(-1, -1):
			troop_manager.place_unit(selected_tile)
