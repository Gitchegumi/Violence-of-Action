extends TileMapLayer

## Emitted when a tile is clicked and a unit is found or not found.
signal unit_selected(unit: Node)

signal deploy_tile_clicked(position: Vector2i)
signal deploy_radial_opened(origin: Vector2i)
signal deploy_unit_hovered(unit_id: String)
signal deploy_unit_selected(unit_id: String, origin: Vector2i)
signal deploy_placement_failed(reason: String, origin: Vector2i, unit_id: String)
signal deploy_radial_closed(reason: String)

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
var deployment_zones_data: Array = []

# --- Radial Menu Integration ---
var radial_menu_scene = preload("res://scenes/ui/radial_menu.tscn")
var radial_menu_instance = null
var radial_origin: Vector2i = Vector2i(-1, -1)
var current_radial_units: Array = []
var deployment_placeholders: Dictionary = {}  # Vector2i -> placeholder node

# --- Mock Resource System (for T018) ---
var player_essence: int = 10  # Mock starting resources


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
	deployment_zones_data = _get_deployment_zones(center_pos)
	_ensure_passable_zones(terrain_map, deployment_zones_data)

	# --- 3. Validate and Carve Paths to Objective ---
	_ensure_paths_to_objective(terrain_map, deployment_zones_data, center_pos)

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

# Check if a coordinate is in a player's deployment zone.
func is_in_deployment_zone(coord: Vector2i, player_index: int) -> bool:
	if player_index < 0 or player_index >= deployment_zones_data.size():
		return false
	return coord in deployment_zones_data[player_index]


# Gets the coordinates for deployment zones based on player count.
func _get_deployment_zones(center: Vector2i) -> Array:
	var zones = []
	var r = MAP_RADIUS

	if PLAYER_COUNT == 2:
		var zone_nw = []; var zone_se = []
		for i in range(r + 1):
			zone_nw.append(center + Vector2i(-r + i, -i))
			zone_se.append(center + Vector2i(r - i, i))
		zones.append(zone_nw); zones.append(zone_se)
	else: # 3 Players
		var zone_n = []; var zone_se = []; var zone_sw = []
		for i in range(r + 1):
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

	# Handle left-click for tile selection and unit selection
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		is_dragging = false
		
		var map_pos = local_to_map(get_local_mouse_position())

		_deploy_log("Left click tile %s" % str(map_pos))

		# Emit deploy tile clicked signal
		emit_signal("deploy_tile_clicked", map_pos)
		
		# Check if tile is in deployment zone for radial menu
		if is_in_deployment_zone(map_pos, 0):  # Assuming player 0 for now
			_show_radial_menu(map_pos)
		
		# Check if a unit is on this tile
		var unit_on_tile = troop_manager.get_unit_at_map_coord(map_pos)
		
		if unit_on_tile:
			_deploy_log("Unit found at tile %s: %s" % [str(map_pos), unit_on_tile.name])
			emit_signal("unit_selected", unit_on_tile)
		else:
			_deploy_log("No unit at tile %s" % str(map_pos))
			emit_signal("unit_selected", null)
			
		# Existing tile selection highlight logic (keep this)
		selection_layer.clear()
		selected_tile = map_pos
		selection_layer.set_cell(selected_tile, 0, objective_type.atlas_coord)
	
	# Press P to place a unit on the currently selected tile (if valid)
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		if selected_tile != Vector2i(-1, -1):
			if is_in_deployment_zone(selected_tile, 0):
				troop_manager.place_unit(selected_tile)
				get_viewport().set_input_as_handled()
			else:
				print("Cannot place unit outside of deployment zone.")
	
	# Debug keys for testing affordability (T018)
	if event is InputEventKey and event.pressed and event.keycode == KEY_1:
		set_player_essence(5)  # Low resources - some units unaffordable
	if event is InputEventKey and event.pressed and event.keycode == KEY_2:
		set_player_essence(10)  # Medium resources 
	if event is InputEventKey and event.pressed and event.keycode == KEY_3:
		set_player_essence(20)  # High resources - all affordable

# --- Radial Menu Functions ---

func _show_radial_menu(origin_tile: Vector2i):
	"""Show radial menu at the specified tile position with mock units"""
	# Close existing radial menu if open
	if radial_menu_instance:
		_close_radial_menu("new_location")

	# Create mock units for deployment
	var mock_units = _create_mock_units()
	current_radial_units = mock_units
	radial_origin = origin_tile

	# Instantiate radial menu
	radial_menu_instance = radial_menu_scene.instantiate()
	add_child(radial_menu_instance)

	# Position the radial menu at the tile center, then keep it on-screen (T029)
	var world_pos = map_to_local(origin_tile)
	radial_menu_instance.position = world_pos
	radial_menu_instance.reposition_within_viewport(get_viewport_rect().size)

	# Provide the placement-validation context and listen for outcomes.
	# tile_map is the centralized public signal surface (contract: signals.md);
	# it re-emits the radial's hover/selected signals for external consumers.
	radial_menu_instance.placement_context_provider = _build_placement_context
	radial_menu_instance.deploy_unit_hovered.connect(_on_radial_unit_hovered)
	radial_menu_instance.deploy_unit_selected.connect(_on_radial_unit_selected)
	radial_menu_instance.deploy_placement_failed.connect(_on_radial_placement_failed)
	radial_menu_instance.deploy_radial_closed.connect(_on_radial_self_closed)

	# Open the radial menu with mock units
	radial_menu_instance.open(origin_tile, mock_units)

	# Emit signal that radial menu is opened
	emit_signal("deploy_radial_opened", origin_tile)
	_deploy_log("Radial opened at %s" % str(origin_tile))

func _build_placement_context() -> Dictionary:
	"""Supply the radial menu with current validation context (T024)."""
	var occupied := troop_manager.get_unit_at_map_coord(radial_origin) != null \
		or deployment_placeholders.has(radial_origin)
	var valid := is_in_deployment_zone(radial_origin, 0)
	return {
		"resources": player_essence,
		"tile_valid": valid,
		"tile_occupied": occupied,
		"now_ms": Time.get_ticks_msec(),
	}

func _on_radial_unit_hovered(unit_id: String):
	emit_signal("deploy_unit_hovered", unit_id)

func _on_radial_unit_selected(unit_id: String, origin: Vector2i):
	"""Successful placement: deduct resources, spawn placeholder, re-validate,
	then close the radial as 'placed' (T024, T027)."""
	var unit := _find_radial_unit(unit_id)
	var cost := int(unit.get("unit_cost", 0)) if not unit.is_empty() else 0
	player_essence = maxi(0, player_essence - cost)
	_spawn_placeholder_unit(origin, unit_id)
	# Re-validate affordability with the reduced resource pool before closing.
	if radial_menu_instance:
		radial_menu_instance.revalidate_affordability(player_essence)
	emit_signal("deploy_unit_selected", unit_id, origin)
	_deploy_log("Placed %s at %s (essence=%d)" % [unit_id, str(origin), player_essence])
	_close_radial_menu("placed")

func _on_radial_placement_failed(reason: String, origin: Vector2i, unit_id: String):
	emit_signal("deploy_placement_failed", reason, origin, unit_id)
	_deploy_log("Placement failed (%s) for %s at %s" % [reason, unit_id, str(origin)])

func _on_radial_self_closed(reason: String):
	"""Radial closed itself (cancel/escape/right-click). Clean up our ref."""
	if reason == "placed":
		return  # _close_radial_menu drives this path; avoid double handling.
	_dispose_radial_instance()
	emit_signal("deploy_radial_closed", reason)
	_deploy_log("Radial closed (%s)" % reason)

func _find_radial_unit(unit_id: String) -> Dictionary:
	for u in current_radial_units:
		if u.get("unit_id", "") == unit_id:
			return u
	return {}

func _spawn_placeholder_unit(origin: Vector2i, unit_id: String):
	"""Spawn a lightweight placeholder marker for the deployed unit (T024)."""
	var marker := Marker2D.new()
	marker.name = "Deployed_%s_%d_%d" % [unit_id, origin.x, origin.y]
	marker.position = map_to_local(origin)
	add_child(marker)
	deployment_placeholders[origin] = marker

func _close_radial_menu(reason: String):
	"""Close the current radial menu if one exists"""
	if radial_menu_instance:
		radial_menu_instance.close(reason)
		_dispose_radial_instance()
		emit_signal("deploy_radial_closed", reason)

func _dispose_radial_instance():
	if radial_menu_instance:
		radial_menu_instance.queue_free()
		radial_menu_instance = null
	current_radial_units = []
	radial_origin = Vector2i(-1, -1)

func _create_mock_units() -> Array:
	"""Create mock units for testing radial menu functionality with affordability"""
	var units = []
	
	# Mock Infantry
	var infantry_cost = 3
	units.append({
		"unit_id": "infantry",
		"unit_name": "Infantry Squad", 
		"unit_role": "Assault",
		"unit_cost": infantry_cost,
		"affordable": player_essence >= infantry_cost,
		"stats_block": {"health": 12, "attack": 3, "range": 2, "armor": 1, "speed": 4},
		"abilities": "Basic combat unit with balanced stats"
	})
	
	# Mock Tank
	var tank_cost = 8
	units.append({
		"unit_id": "tank",
		"unit_name": "Battle Tank",
		"unit_role": "Heavy",
		"unit_cost": tank_cost,
		"affordable": player_essence >= tank_cost,
		"stats_block": {"health": 25, "attack": 6, "range": 3, "armor": 4, "speed": 2},
		"abilities": "Heavy armor and firepower, slow movement"
	})
	
	# Mock Artillery
	var artillery_cost = 6
	units.append({
		"unit_id": "artillery",
		"unit_name": "Artillery Unit",
		"unit_role": "Support",
		"unit_cost": artillery_cost,
		"affordable": player_essence >= artillery_cost,
		"stats_block": {"health": 8, "attack": 8, "range": 5, "armor": 1, "speed": 1},
		"abilities": "Long-range bombardment, fragile"
	})
	
	# Mock Expensive Unit (to test disabled state)
	var expensive_cost = 15
	units.append({
		"unit_id": "mech",
		"unit_name": "Battle Mech",
		"unit_role": "Elite",
		"unit_cost": expensive_cost,
		"affordable": player_essence >= expensive_cost,
		"stats_block": {"health": 30, "attack": 10, "range": 4, "armor": 5, "speed": 3},
		"abilities": "Elite war machine with superior stats"
	})
	
	return units

func _deploy_log(message: String) -> void:
	GameLog.debug("deployment.radial", message)

func set_player_essence(amount: int):
	"""Set player essence for testing affordability (temporary for T018)"""
	player_essence = amount
	_deploy_log("Player essence set to: %d" % player_essence)

func get_player_essence() -> int:
	"""Get current player essence"""
	return player_essence
