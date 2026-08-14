extends TileMapLayer

## Emitted when a tile is clicked and a unit is found or not found.
signal unit_selected(unit: Node)

signal deploy_tile_clicked(position: Vector2i)
signal deploy_radial_opened(origin: Vector2i)
signal deploy_unit_hovered(unit_id: String)
signal deploy_unit_selected(unit_id: String, origin: Vector2i)
signal deploy_placement_failed(reason: String, origin: Vector2i, unit_id: String)
signal deploy_radial_closed(reason: String)
signal deploy_action_selected(action_id: String, origin: Vector2i)
signal unit_moved(unit: Node, path: Array, movement_cost: int, movement_remaining: int)
signal unit_move_rejected(reason: String, destination: Vector2i)
signal unit_attack_resolved(attacker: Node, defender: Node, result: Dictionary)
signal unit_attack_rejected(reason: String, destination: Vector2i)
signal pending_action_changed(active: bool, action_type: String)
signal action_highlights_changed(action_type: String, coordinates: Array[Vector2i])
# Emitted when a DEPLOY radial closes, so the shared info panel can hide its
# hover preview. (Action radials do not emit this — see _on_radial_self_closed.)
signal deploy_preview_ended

# The radius of the hexagonal map in tiles.
const MAP_RADIUS = 8
const MOVE_HIGHLIGHT_COLOR := Color(0.35, 0.75, 1.0, 0.52)
const ATTACK_HIGHLIGHT_COLOR := Color(1.0, 0.2, 0.2, 0.52)
var player_count := 2
var map_seed := 0
var map_rng := RandomNumberGenerator.new()
var objective_position := Vector2i(6, 7)

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
const MVP_COREBORN_ROSTER: Array[String] = [
	"battlefield_scavenger",
	"fluxsmith",
	"ghostthorn",
	"golemancer_hull",
	"shard_walker",
	"sky_render",
	"tide_born",
]
var radial_menu_instance = null
var radial_origin: Vector2i = Vector2i(-1, -1)
var current_radial_units: Array = []
var current_radial_unit_node = null  # Occupied-tile unit when in action mode
var pending_action: Dictionary = {}  # Set when an action awaits target selection
var _radial_is_deploy: bool = false  # True while a DEPLOY radial is open

var resource_manager: ResourceManager


# --- Built-in Godot Functions ---

func _ready():
	resource_manager = get_node_or_null("../ResourceManager") as ResourceManager
	if resource_manager == null:
		resource_manager = ResourceManager.new()
		add_child(resource_manager)
	if GameSession.has_match_config():
		player_count = int(GameSession.match_config.get("player_count", 2))
		map_seed = int(GameSession.match_config.get("seed", 0))
	else:
		var random_seed_source := RandomNumberGenerator.new()
		random_seed_source.randomize()
		map_seed = random_seed_source.randi()
	map_rng.seed = map_seed
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
	var center_pos = objective_position

	# --- 1. Generate Noise-Based Terrain ---
	var terrain_map = _generate_noise_terrain(center_pos)

	# --- 2. Define Deployment Zones and Ensure They Are Passable ---
	deployment_zones_data = _get_deployment_zones(center_pos)
	_ensure_passable_zones(terrain_map, deployment_zones_data)

	# --- 3. Validate and Repair Fair Paths to Objective ---
	if not _ensure_fair_paths_to_objective(terrain_map, deployment_zones_data, center_pos):
		push_error("Generated map rejected: objective paths could not be made fair.")
		return

	# --- 4. Place Tiles on the Map ---
	self.terrain_data_map = terrain_map.duplicate() # Complete playable map for selection logic
	for coord in terrain_map:
		var terrain: TerrainType = terrain_map[coord]
		set_cell(coord, tile_set_source_id, terrain.atlas_coord)

	# --- 5. Place the Objective Tile ---
	set_cell(center_pos, tile_set_source_id, objective_type.atlas_coord)
	terrain_data_map[center_pos] = objective_type
	_update_camera_bounds(terrain_data_map.keys())
	
	print("Total tiles placed: ", terrain_map.size() + 1)


# Creates the initial terrain layout using Perlin noise.
func _generate_noise_terrain(center: Vector2i) -> Dictionary:
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.03
	noise.seed = map_seed

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

# Fairness uses land movement and each terrain's documented movement-point cost.
# The starting deployment tile costs nothing; each entered tile, including the
# objective, contributes its move_cost.
func get_zone_path_costs(terrain_map: Dictionary, zones: Array, objective: Vector2i) -> Array[int]:
	var costs: Array[int] = []
	for zone in zones:
		costs.append(_shortest_land_path_cost(zone, objective, terrain_map))
	return costs


func are_zone_paths_fair(costs: Array[int], configured_player_count: int) -> bool:
	if costs.size() != configured_player_count or costs.is_empty():
		return false
	for cost in costs:
		if cost < 0:
			return false
	var tolerance := 0 if configured_player_count == 2 else 1
	return costs.max() - costs.min() <= tolerance


func _ensure_fair_paths_to_objective(
	terrain_map: Dictionary,
	zones: Array,
	objective: Vector2i
) -> bool:
	var costs := get_zone_path_costs(terrain_map, zones, objective)
	if _all_path_costs_equal(costs, zones.size()):
		return true
	print("Unequal objective paths detected (%s). Repairing..." % str(costs))
	if not _repair_objective_paths(terrain_map, zones, objective):
		# A one-point three-player spread is only valid when equality is proven
		# impossible. This repair is not an exhaustive proof, so fail closed and
		# let generation reject the candidate instead of accepting tolerance.
		return false
	costs = get_zone_path_costs(terrain_map, zones, objective)
	return _all_path_costs_equal(costs, zones.size())


func _all_path_costs_equal(costs: Array[int], configured_player_count: int) -> bool:
	return costs.size() == configured_player_count \
		and not costs.is_empty() \
		and costs.min() >= 0 \
		and costs.min() == costs.max()


func _repair_objective_paths(terrain_map: Dictionary, zones: Array, objective: Vector2i) -> bool:
	var preferred_terrain := _lowest_cost_land_terrain()
	if preferred_terrain == null:
		return false
	var protected: Dictionary = {}
	var routes: Array = []
	for zone in zones:
		var start := _nearest_zone_coordinate(zone, objective)
		if start == Vector2i(-2147483648, -2147483648):
			return false
		var route := _get_hex_line_path(start, objective)
		routes.append(route)
		for coord in route:
			if coord != objective:
				protected[coord] = true
	for zone in zones:
		for coord in zone:
			protected[coord] = true

	var donors: Array[Vector2i] = []
	for coord in terrain_map:
		if not protected.has(coord) and terrain_map[coord] == preferred_terrain:
			donors.append(coord)
	donors.sort_custom(_coordinate_less)

	var replacements: Array[Vector2i] = []
	var replacement_set: Dictionary = {}
	for route in routes:
		for coord in route:
			if coord == objective or not terrain_map.has(coord):
				continue
			if terrain_map[coord] == preferred_terrain or replacement_set.has(coord):
				continue
			replacements.append(coord)
			replacement_set[coord] = true
	if donors.size() < replacements.size():
		return false
	for coord in replacements:
		var donor: Vector2i = donors.pop_front()
		var displaced: TerrainType = terrain_map[coord]
		terrain_map[coord] = preferred_terrain
		terrain_map[donor] = displaced
	return true


func _shortest_land_path_cost(zone: Array, objective: Vector2i, terrain_map: Dictionary) -> int:
	var distances: Dictionary = {}
	var open: Dictionary = {}
	for start in zone:
		if terrain_map.has(start) and _is_land(terrain_map[start]):
			distances[start] = 0
			open[start] = true
	while not open.is_empty():
		var current = _lowest_distance_coordinate(open, distances)
		var current_cost: int = distances[current]
		open.erase(current)
		if current == objective:
			return current_cost
		for neighbor in _get_neighbors(current):
			if neighbor != objective and not terrain_map.has(neighbor):
				continue
			var terrain: TerrainType = objective_type if neighbor == objective else terrain_map[neighbor]
			if neighbor != objective and not _is_land(terrain):
				continue
			var candidate := current_cost + maxi(1, terrain.move_cost)
			if candidate < int(distances.get(neighbor, 2147483647)):
				distances[neighbor] = candidate
				open[neighbor] = true
	return -1


func _lowest_distance_coordinate(open: Dictionary, distances: Dictionary) -> Vector2i:
	var best: Vector2i = open.keys()[0]
	for coord in open:
		if distances[coord] < distances[best] or (
			distances[coord] == distances[best] and _coordinate_less(coord, best)
		):
			best = coord
	return best


func _lowest_cost_land_terrain() -> TerrainType:
	var best: TerrainType = null
	for terrain in terrain_types:
		if _is_land(terrain) and (best == null or terrain.move_cost < best.move_cost):
			best = terrain
	return best


static func _is_land(terrain: TerrainType) -> bool:
	return terrain != null and terrain.passable_by == "land"


func _nearest_zone_coordinate(zone: Array, objective: Vector2i) -> Vector2i:
	var invalid := Vector2i(-2147483648, -2147483648)
	var best: Vector2i = invalid
	for coord in zone:
		if best == invalid or _hex_distance(coord, objective) < _hex_distance(best, objective) or (
			_hex_distance(coord, objective) == _hex_distance(best, objective)
			and _coordinate_less(coord, best)
		):
			best = coord
	return best


static func _coordinate_less(a: Vector2i, b: Vector2i) -> bool:
	return a.x < b.x or (a.x == b.x and a.y < b.y)

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

	if player_count == 2:
		var zone_nw = []; var zone_se = []
		for i in range(r + 1):
			zone_nw.append(center + Vector2i(-r + i, -i))
			zone_se.append(center + Vector2i(r - i, i))
		zones.append(zone_nw); zones.append(zone_se)
	else: # 3 Players
		var zone_n = []; var zone_se = []; var zone_sw = []
		for i in range(r + 1):
			zone_n.append(center + Vector2i(i, -r))
			zone_se.append(center + Vector2i(r - i, i))
			zone_sw.append(center + Vector2i(-r, r - i))
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
	
	_shuffle_with_map_rng(swappable_coords)

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


func _shuffle_with_map_rng(items: Array) -> void:
	for index in range(items.size() - 1, 0, -1):
		var swap_index := map_rng.randi_range(0, index)
		var value = items[index]
		items[index] = items[swap_index]
		items[swap_index] = value

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

# Returns a minimum-step axial hex line, including both endpoints.
func _get_hex_line_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var distance := _hex_distance(start, end)
	if distance == 0:
		return [start]
	var line: Array[Vector2i] = []
	var start_cube := Vector3(start.x, -start.x - start.y, start.y)
	var end_cube := Vector3(end.x, -end.x - end.y, end.y)
	for index in range(distance + 1):
		var cube := start_cube.lerp(end_cube, float(index) / distance)
		line.append(_cube_round_to_axial(cube))
	return line


func has_line_of_sight(start: Vector2i, end: Vector2i) -> bool:
	# Adjacent targets never have an intervening hex. Blocking policy for longer
	# lines is intentionally centralized here so terrain/unit rules are not
	# duplicated in combat validation.
	return _get_hex_line_path(start, end).size() <= 2 or not _line_of_sight_has_blocker(start, end)


func _line_of_sight_has_blocker(_start: Vector2i, _end: Vector2i) -> bool:
	var line := _get_hex_line_path(_start, _end)
	for index in range(1, line.size() - 1):
		var terrain: TerrainType = terrain_data_map.get(line[index])
		if terrain != null and terrain.terrain_name.to_lower() == "mountain":
			return true
	return false


static func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	var delta := a - b
	return floori((absi(delta.x) + absi(delta.y) + absi(delta.x + delta.y)) / 2.0)


static func _cube_round_to_axial(cube: Vector3) -> Vector2i:
	var rounded_x := roundi(cube.x)
	var rounded_y := roundi(cube.y)
	var rounded_z := roundi(cube.z)
	var x_difference := absf(rounded_x - cube.x)
	var y_difference := absf(rounded_y - cube.y)
	var z_difference := absf(rounded_z - cube.z)
	if x_difference > y_difference and x_difference > z_difference:
		rounded_x = -rounded_y - rounded_z
	elif y_difference > z_difference:
		rounded_y = -rounded_x - rounded_z
	else:
		rounded_z = -rounded_x - rounded_y
	return Vector2i(rounded_x, rounded_z)


# --- Camera Controls ---

@export var camera_speed := 400.0
@export var camera_edge_margin := 24.0
@export var camera_min_zoom := 0.5
@export var camera_max_zoom := 2.0
@export var camera_zoom_step := 0.15
@export var camera_zoom_smoothing := 12.0
@onready var camera: Camera2D = $Camera2D
var camera_bounds := Rect2()
var camera_target_zoom := 1.0

func _process(delta: float) -> void:
	if not camera:
		return

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	input_dir += Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()

	# Edge scrolling pauses over UI so camera movement cannot disturb radial
	# selection or placement controls.
	if radial_menu_instance == null and get_viewport().gui_get_hovered_control() == null:
		input_dir += get_edge_scroll_direction(
			get_viewport().get_mouse_position(),
			get_viewport_rect().size,
			camera_edge_margin
		)
	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()

	_move_camera(input_dir * camera_speed * delta / camera.zoom.x)
	var zoom_weight := 1.0 - exp(-camera_zoom_smoothing * delta)
	var next_zoom := lerpf(camera.zoom.x, camera_target_zoom, zoom_weight)
	camera.zoom = Vector2.ONE * next_zoom
	_clamp_camera_to_bounds()


static func get_edge_scroll_direction(
	mouse_position: Vector2,
	viewport_size: Vector2,
	edge_margin: float
) -> Vector2:
	if edge_margin <= 0.0 or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Vector2.ZERO
	if mouse_position.x < 0.0 or mouse_position.y < 0.0 \
		or mouse_position.x > viewport_size.x or mouse_position.y > viewport_size.y:
		return Vector2.ZERO

	var direction := Vector2.ZERO
	if mouse_position.x <= edge_margin:
		direction.x -= 1.0
	elif mouse_position.x >= viewport_size.x - edge_margin:
		direction.x += 1.0
	if mouse_position.y <= edge_margin:
		direction.y -= 1.0
	elif mouse_position.y >= viewport_size.y - edge_margin:
		direction.y += 1.0
	return direction.normalized() if direction != Vector2.ZERO else direction


static func get_clamped_camera_position(
	target: Vector2,
	world_bounds: Rect2,
	viewport_size: Vector2,
	zoom_level: float
) -> Vector2:
	if not world_bounds.has_area() or zoom_level <= 0.0:
		return target
	var half_view := viewport_size / (2.0 * zoom_level)
	var center := world_bounds.get_center()
	var min_position := world_bounds.position + half_view
	var max_position := world_bounds.end - half_view
	return Vector2(
		center.x if min_position.x > max_position.x else clampf(target.x, min_position.x, max_position.x),
		center.y if min_position.y > max_position.y else clampf(target.y, min_position.y, max_position.y)
	)


func _update_camera_bounds(map_coordinates: Array) -> void:
	if map_coordinates.is_empty() or tile_set == null:
		camera_bounds = Rect2()
		return
	var first_center := map_to_local(map_coordinates[0])
	var minimum := first_center
	var maximum := first_center
	for coordinate in map_coordinates:
		var tile_center := map_to_local(coordinate)
		minimum = minimum.min(tile_center)
		maximum = maximum.max(tile_center)
	var half_tile := Vector2(tile_set.tile_size) / 2.0
	camera_bounds = Rect2(minimum - half_tile, maximum - minimum + half_tile * 2.0)
	_clamp_camera_to_bounds()


func _move_camera(offset: Vector2) -> void:
	if camera and offset != Vector2.ZERO:
		camera.position += offset
		_clamp_camera_to_bounds()


func _clamp_camera_to_bounds() -> void:
	if camera:
		camera.position = get_clamped_camera_position(
			camera.position,
			camera_bounds,
			get_viewport_rect().size,
			camera.zoom.x
		)


func center_camera_on_tile(tile: Vector2i) -> void:
	if camera and terrain_data_map.has(tile):
		camera.position = map_to_local(tile)
		_clamp_camera_to_bounds()

# --- Selection and Input Handling ---

@onready var selection_layer = get_node("SelectionLayer")
@onready var action_highlight_layer: TileMapLayer = get_node("ActionHighlightLayer")
var selected_tile = Vector2i(-1, -1) # Off-map coordinate by default
var is_dragging = false

# This dictionary will be populated in _generate_map
var terrain_data_map: Dictionary = {}

func _unhandled_input(event):
	# Handle right-click button press/release for camera dragging
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.is_pressed() and not pending_action.is_empty():
			cancel_pending_action()
			get_viewport().set_input_as_handled()
			return
		is_dragging = event.is_pressed()
		get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_target_zoom = clampf(
				camera_target_zoom + camera_zoom_step,
				camera_min_zoom,
				camera_max_zoom
			)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_target_zoom = clampf(
				camera_target_zoom - camera_zoom_step,
				camera_min_zoom,
				camera_max_zoom
			)
			get_viewport().set_input_as_handled()

	# Handle mouse motion for dragging
	if event is InputEventMouseMotion and is_dragging:
		_move_camera(-event.relative / camera.zoom.x)
		get_viewport().set_input_as_handled()

	# Handle left-click for tile selection and unit selection
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		is_dragging = false
		
		var map_pos = local_to_map(get_local_mouse_position())

		_deploy_log("Left click tile %s" % str(map_pos))

		# Emit deploy tile clicked signal
		emit_signal("deploy_tile_clicked", map_pos)

		# Route the click: occupied tile -> action radial; empty deployment
		# tile -> deploy radial; anything else -> plain selection.
		var unit_on_tile = troop_manager.get_unit_at_map_coord(map_pos)

		if not pending_action.is_empty():
			_resolve_pending_action(map_pos)
		elif unit_on_tile:
			_deploy_log("Unit found at tile %s: %s" % [str(map_pos), unit_on_tile.name])
			_show_action_radial(map_pos, unit_on_tile)
			emit_signal("unit_selected", unit_on_tile)
		elif _can_deploy_at(map_pos):
			_deploy_log("Empty deployment tile %s" % str(map_pos))
			_show_radial_menu(map_pos)
			emit_signal("unit_selected", null)
		else:
			_deploy_log("No unit at tile %s" % str(map_pos))
			emit_signal("unit_selected", null)

		# Existing tile selection highlight logic (keep this)
		selection_layer.clear()
		selected_tile = map_pos
		selection_layer.set_cell(selected_tile, 0, objective_type.atlas_coord)
	
	# Press P to open the normal purchase flow on the selected tile.
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		if selected_tile != Vector2i(-1, -1):
			if _can_deploy_at(selected_tile):
				_show_radial_menu(selected_tile)
				get_viewport().set_input_as_handled()
			else:
				print("Cannot deploy on this tile during the current phase.")

	# F recenters on the selected hex (including a selected unit's hex).
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		center_camera_on_tile(selected_tile)
		get_viewport().set_input_as_handled()
	
# --- Radial Menu Functions ---

func _show_radial_menu(origin_tile: Vector2i):
	"""Show the DEPLOY radial at an empty deployment tile with real units."""
	if not _can_deploy_at(origin_tile):
		_deploy_log("Deploy radial rejected outside an eligible deployment tile or phase")
		return
	if radial_menu_instance:
		_close_radial_menu("new_location")

	current_radial_units = _get_deployable_units()
	current_radial_unit_node = null
	radial_origin = origin_tile
	_radial_is_deploy = true

	radial_menu_instance = radial_menu_scene.instantiate()
	add_child(radial_menu_instance)

	# Position at the tile center, then keep the full ring on-screen (T029).
	radial_menu_instance.position = map_to_local(origin_tile)
	radial_menu_instance.reposition_within_viewport(get_viewport_rect().size)

	# tile_map is the centralized public signal surface (contract: signals.md);
	# it re-emits the radial's hover/selected signals for external consumers.
	radial_menu_instance.placement_context_provider = _build_placement_context
	radial_menu_instance.deploy_unit_hovered.connect(_on_radial_unit_hovered)
	radial_menu_instance.deploy_unit_unhovered.connect(_on_radial_unit_unhovered)
	radial_menu_instance.deploy_unit_selected.connect(_on_radial_unit_selected)
	radial_menu_instance.deploy_placement_failed.connect(_on_radial_placement_failed)
	radial_menu_instance.deploy_radial_closed.connect(_on_radial_self_closed)

	radial_menu_instance.open(origin_tile, current_radial_units)

	emit_signal("deploy_radial_opened", origin_tile)
	_deploy_log("Deploy radial opened at %s (%d units)" % [str(origin_tile), current_radial_units.size()])

func _show_action_radial(origin_tile: Vector2i, unit_node):
	"""Show the ACTION radial at an occupied tile (Attack/Move/Upgrade/Inspect)."""
	if radial_menu_instance:
		_close_radial_menu("new_location")

	radial_origin = origin_tile
	current_radial_unit_node = unit_node
	current_radial_units = []
	_radial_is_deploy = false

	radial_menu_instance = radial_menu_scene.instantiate()
	add_child(radial_menu_instance)

	radial_menu_instance.position = map_to_local(origin_tile)
	radial_menu_instance.reposition_within_viewport(get_viewport_rect().size)

	radial_menu_instance.deploy_action_selected.connect(_on_radial_action_selected)
	radial_menu_instance.deploy_radial_closed.connect(_on_radial_self_closed)

	radial_menu_instance.open_actions(origin_tile, _build_unit_actions(unit_node))

	emit_signal("deploy_radial_opened", origin_tile)
	_deploy_log("Action radial opened at %s" % str(origin_tile))

func _get_deployable_units() -> Array:
	"""Build the stat-only MVP roster in a stable player-facing order."""
	var units: Array = []
	for unit_id in MVP_COREBORN_ROSTER:
		var data: UnitType = troop_manager.catalog.get(unit_id)
		if data:
			units.append(_unit_type_to_dict(unit_id, data))
		else:
			_deploy_log("MVP roster unit missing from troop catalog: %s" % unit_id)
	return units


func get_deployable_unit_preview(unit_id: String) -> Dictionary:
	return _find_radial_unit(unit_id)

func _unit_type_to_dict(id: String, data: UnitType) -> Dictionary:
	var existing_count := troop_manager.count_units(id, GameState.active_player_id)
	var cost := data.get_cost(existing_count)
	return {
		"unit_id": id,
		"unit_name": data.unit_name,
		"unit_role": data.unit_role,
		"unit_cost": cost,
		"affordable": resource_manager.can_afford(GameState.active_player_id, cost),
		"stats_block": data.stats_block,
		"abilities": data.special_abilities,
		"unit_description": data.unit_description,
	}

func _build_unit_actions(unit_node) -> Array:
	"""Action options for an occupied tile. Upgrade is enabled only when the
	unit has an upgrade target, the player can afford it, and authoritative
	combat safety state is available."""
	var data: UnitType = null
	if unit_node and unit_node.has_method("get_unit_data"):
		data = unit_node.get_unit_data()
	var can_upgrade := _has_authoritative_upgrade_safety_state(unit_node) \
		and data != null and data.can_upgrade \
		and data.upgrades_to != null and resource_manager.can_afford(GameState.active_player_id, data.upgrade_cost)
	var move_validation: Dictionary = troop_manager.get_move_validation(unit_node)
	var attack_validation: Dictionary = troop_manager.get_attack_start_validation(unit_node)
	return [
		{
			"action_id": "attack",
			"label": "Attack",
			"enabled": attack_validation.valid,
			"description": "Attack a target" if attack_validation.valid else (
				"Attack unavailable: %s" % String(attack_validation.reason).replace("_", " ")
			),
		},
		{"action_id": "move", "label": "Move", "enabled": move_validation.valid, "description": _move_description(move_validation)},
		{"action_id": "upgrade", "label": "Upgrade", "enabled": can_upgrade, "description": "Upgrade this unit"},
		{"action_id": "inspect", "label": "Inspect", "enabled": true, "description": "View unit details"},
	]

func _build_placement_context() -> Dictionary:
	"""Supply the radial menu with current validation context (T024)."""
	return {
		"resources": get_player_essence(),
		"tile_valid": _can_deploy_at(radial_origin),
		"tile_occupied": troop_manager.get_unit_at_map_coord(radial_origin) != null,
		"now_ms": Time.get_ticks_msec(),
	}

func _on_radial_unit_hovered(unit_id: String):
	emit_signal("deploy_unit_hovered", unit_id)

func _on_radial_unit_unhovered():
	# Mouse left a deploy icon -> hide the shared info-panel preview.
	emit_signal("deploy_preview_ended")

func _on_radial_unit_selected(unit_id: String, origin: Vector2i):
	"""Reserve essence, place the real unit, and refund any rejected placement."""
	if not _can_deploy_at(origin):
		_deploy_log("Deployment rejected outside an eligible tile or phase")
		deploy_placement_failed.emit("deployment_not_allowed", origin, unit_id)
		_close_radial_menu("deployment_not_allowed")
		return
	var data: UnitType = troop_manager.catalog.get(unit_id)
	if data == null or _find_radial_unit(unit_id).is_empty():
		_deploy_log("Unknown deployment unit rejected: %s" % unit_id)
		return
	# Re-resolve dynamic pricing at confirmation time so a stale radial quote
	# cannot undercharge after the player's board state changes.
	var cost := data.get_cost(troop_manager.count_units(unit_id, GameState.active_player_id))
	if not resource_manager.try_spend(GameState.active_player_id, cost, "purchase:%s" % unit_id):
		_deploy_log("Not enough essence to place %s" % unit_id)
		return
	troop_manager.set_current_unit(unit_id)
	if troop_manager.place_unit(origin, GameState.active_player_id):
		_deploy_log("Placed %s at %s (essence=%d)" % [unit_id, str(origin), get_player_essence()])
	else:
		resource_manager.add_essence(GameState.active_player_id, cost, "purchase_refund:%s" % unit_id)
		_deploy_log("troop_manager rejected placement of %s at %s" % [unit_id, str(origin)])
	if radial_menu_instance:
		radial_menu_instance.revalidate_affordability(get_player_essence())
	emit_signal("deploy_unit_selected", unit_id, origin)
	_close_radial_menu("placed")


func _can_deploy_at(origin: Vector2i) -> bool:
	return _is_deployment_phase() \
		and is_in_deployment_zone(origin, GameState.active_player_id) \
		and troop_manager.get_unit_at_map_coord(origin) == null


func _is_deployment_phase() -> bool:
	return GameState.current_state == GameState.State.INITIAL_DEPLOYMENT \
		or (GameState.current_state == GameState.State.PLAYING \
		and GameState.current_phase == GameState.TurnPhase.MARSHAL_TROOPS)

func _on_radial_action_selected(action_id: String, origin: Vector2i):
	"""Dispatch a selected unit action, then close the action radial."""
	var unit_node = current_radial_unit_node
	emit_signal("deploy_action_selected", action_id, origin)
	match action_id:
		"inspect":
			emit_signal("unit_selected", unit_node)  # drives the big info panel
		"upgrade":
			_upgrade_unit(unit_node, origin)
		"move":
			_begin_pending_action("move", unit_node, origin)
		"attack":
			_begin_pending_action("attack", unit_node, origin)
	_close_radial_menu("action:%s" % action_id)

func _upgrade_unit(unit_node, origin: Vector2i):
	if unit_node == null or not unit_node.has_method("get_unit_data"):
		return
	var data: UnitType = unit_node.get_unit_data()
	if data == null or not data.can_upgrade or data.upgrades_to == null:
		_deploy_log("Upgrade unavailable for unit at %s" % str(origin))
		return
	if not _has_authoritative_upgrade_safety_state(unit_node):
		_deploy_log("Upgrade disabled until combat engagement and adjacency state is available")
		return

func _has_authoritative_upgrade_safety_state(_unit_node) -> bool:
	return _unit_node != null \
		and troop_manager.get_unit_at_map_coord(_unit_node.map_pos) == _unit_node \
		and troop_manager.get_adjacent_enemies(_unit_node).is_empty()

func _begin_pending_action(kind: String, unit_node, origin: Vector2i):
	clear_action_highlights()
	if kind == "move":
		var validation := troop_manager.get_move_validation(unit_node)
		if not validation.valid:
			unit_move_rejected.emit(validation.reason, origin)
			_deploy_log("Move rejected: %s" % validation.reason)
			return
	elif kind == "attack":
		var validation := troop_manager.get_attack_start_validation(unit_node)
		if not validation.valid:
			unit_attack_rejected.emit(validation.reason, origin)
			_deploy_log("Attack rejected: %s" % validation.reason)
			return
	# Move/Attack use a follow-up target-selection step.
	pending_action = {"type": kind, "unit": unit_node, "origin": origin}
	_show_action_highlights(kind, unit_node)
	pending_action_changed.emit(true, kind)
	_deploy_log("%s requested for unit at %s (awaiting target tile)" % [kind.capitalize(), str(origin)])


func _resolve_pending_action(destination: Vector2i) -> void:
	var action_type: String = pending_action.get("type", "")
	if action_type == "attack":
		_resolve_pending_attack(destination)
		return
	if action_type != "move":
		return
	var unit: Node = pending_action.get("unit")
	var result := troop_manager.move_unit(unit, destination)
	if not result.success:
		unit_move_rejected.emit(result.reason, destination)
		_deploy_log("Move rejected at %s: %s" % [str(destination), result.reason])
		return
	clear_action_highlights()
	pending_action.clear()
	pending_action_changed.emit(false, "")
	unit_moved.emit(unit, result.path, result.cost, unit.movement_remaining)
	emit_signal("unit_selected", unit)
	_deploy_log("Moved to %s for %d points (%d remaining)" % [
		str(destination), result.cost, unit.movement_remaining
	])


func _resolve_pending_attack(destination: Vector2i) -> void:
	var attacker: Node = pending_action.get("unit")
	var defender := troop_manager.get_unit_at_map_coord(destination)
	var result := troop_manager.roll_attack(attacker, defender, map_rng)
	if not result.success:
		unit_attack_rejected.emit(result.reason, destination)
		_deploy_log("Attack rejected at %s: %s" % [str(destination), result.reason])
		return
	clear_action_highlights()
	pending_action.clear()
	pending_action_changed.emit(false, "")
	unit_attack_resolved.emit(attacker, defender, result)
	if not result.destroyed:
		emit_signal("unit_selected", defender)
	_deploy_log("Attack rolled %d + %d: %s (%d HP remaining)" % [
		result.die_one,
		result.die_two,
		"hit" if result.hit else "miss",
		result.remaining_hp,
	])


func cancel_pending_action() -> void:
	if pending_action.is_empty():
		clear_action_highlights()
		return
	_deploy_log("%s target selection cancelled" % String(pending_action.get("type", "action")).capitalize())
	clear_action_highlights()
	pending_action.clear()
	pending_action_changed.emit(false, "")


func _show_action_highlights(action_type: String, unit: Node) -> void:
	var coordinates: Array[Vector2i] = []
	match action_type:
		"move":
			action_highlight_layer.modulate = MOVE_HIGHLIGHT_COLOR
			coordinates = troop_manager.get_valid_move_destinations(unit)
		"attack":
			action_highlight_layer.modulate = ATTACK_HIGHLIGHT_COLOR
			coordinates = troop_manager.get_valid_attack_targets(unit)
	for coordinate in coordinates:
		action_highlight_layer.set_cell(coordinate, 0, Vector2i.ZERO)
	action_highlights_changed.emit(action_type, coordinates)


func clear_action_highlights() -> void:
	action_highlight_layer.clear()
	action_highlights_changed.emit("", [])


func get_action_highlighted_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for coordinate in action_highlight_layer.get_used_cells():
		cells.append(coordinate)
	return cells


func _move_description(validation: Dictionary) -> String:
	if validation.valid:
		return "Move using the cheapest valid path"
	return "Move unavailable: %s" % String(validation.reason).replace("_", " ")

func _on_radial_placement_failed(reason: String, origin: Vector2i, unit_id: String):
	emit_signal("deploy_placement_failed", reason, origin, unit_id)
	_deploy_log("Placement failed (%s) for %s at %s" % [reason, unit_id, str(origin)])

func _on_radial_self_closed(reason: String):
	"""Single owner of radial teardown: the radial emits deploy_radial_closed
	whenever it closes (self-initiated or via _close_radial_menu)."""
	var was_deploy := _radial_is_deploy
	_dispose_radial_instance()
	if was_deploy:
		# Clear the deploy-hover preview from the shared info panel.
		emit_signal("deploy_preview_ended")
	emit_signal("deploy_radial_closed", reason)
	_deploy_log("Radial closed (%s)" % reason)

func _find_radial_unit(unit_id: String) -> Dictionary:
	for u in current_radial_units:
		if u.get("unit_id", "") == unit_id:
			return u
	return {}

func _close_radial_menu(reason: String):
	"""Request close; teardown + deploy_radial_closed happen in the handler."""
	if radial_menu_instance:
		radial_menu_instance.close(reason)

func _dispose_radial_instance():
	if radial_menu_instance:
		radial_menu_instance.queue_free()
		radial_menu_instance = null
	current_radial_units = []
	current_radial_unit_node = null
	radial_origin = Vector2i(-1, -1)
	_radial_is_deploy = false

# --- Unit data accessors (used by main.gd to drive the shared info panel) ---

func get_unit_type(unit_id: String) -> UnitType:
	return troop_manager.catalog.get(unit_id)

func get_unit_artwork(unit_id: String) -> Node:
	return troop_manager.get_unit_artwork(unit_id)

func _deploy_log(message: String) -> void:
	GameLog.debug("deployment.radial", message)

func get_player_essence() -> int:
	return resource_manager.get_essence(GameState.active_player_id) if resource_manager else 0
