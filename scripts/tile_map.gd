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
# Emitted when a DEPLOY radial closes, so the shared info panel can hide its
# hover preview. (Action radials do not emit this — see _on_radial_self_closed.)
signal deploy_preview_ended

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
var current_radial_unit_node = null  # Occupied-tile unit when in action mode
var pending_action: Dictionary = {}  # Set when an action awaits target selection
var _radial_is_deploy: bool = false  # True while a DEPLOY radial is open

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
var selected_tile = Vector2i(-1, -1) # Off-map coordinate by default
var is_dragging = false

# This dictionary will be populated in _generate_map
var terrain_data_map: Dictionary = {}

func _unhandled_input(event):
	# Handle right-click button press/release for camera dragging
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
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

		if unit_on_tile:
			_deploy_log("Unit found at tile %s: %s" % [str(map_pos), unit_on_tile.name])
			_show_action_radial(map_pos, unit_on_tile)
			emit_signal("unit_selected", unit_on_tile)
		elif is_in_deployment_zone(map_pos, 0):  # Assuming player 0 for now
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
	
	# Press P to place a unit on the currently selected tile (if valid)
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		if selected_tile != Vector2i(-1, -1):
			if is_in_deployment_zone(selected_tile, 0):
				troop_manager.place_unit(selected_tile)
				get_viewport().set_input_as_handled()
			else:
				print("Cannot place unit outside of deployment zone.")

	# F recenters on the selected hex (including a selected unit's hex).
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		center_camera_on_tile(selected_tile)
		get_viewport().set_input_as_handled()
	
	# Debug keys for testing affordability (T018)
	if event is InputEventKey and event.pressed and event.keycode == KEY_1:
		set_player_essence(5)  # Low resources - some units unaffordable
	if event is InputEventKey and event.pressed and event.keycode == KEY_2:
		set_player_essence(10)  # Medium resources 
	if event is InputEventKey and event.pressed and event.keycode == KEY_3:
		set_player_essence(20)  # High resources - all affordable

# --- Radial Menu Functions ---

func _show_radial_menu(origin_tile: Vector2i):
	"""Show the DEPLOY radial at an empty deployment tile with real units."""
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
	"""Build the deployable-unit list from the real troop catalog.
	For now only the Shard Walker is fully implemented."""
	var units: Array = []
	var data: UnitType = troop_manager.catalog.get("shard_walker")
	if data:
		units.append(_unit_type_to_dict("shard_walker", data))
	else:
		_deploy_log("shard_walker missing from troop catalog")
	return units

func _unit_type_to_dict(id: String, data: UnitType) -> Dictionary:
	var cost := data.get_cost(0)
	return {
		"unit_id": id,
		"unit_name": data.unit_name,
		"unit_role": data.unit_role,
		"unit_cost": cost,
		"affordable": player_essence >= cost,
		"stats_block": data.stats_block,
		"abilities": data.special_abilities,
		"unit_description": data.unit_description,
	}

func _build_unit_actions(unit_node) -> Array:
	"""Action options for an occupied tile. Upgrade is enabled only when the
	unit has an upgrade target and the player can afford it."""
	var data: UnitType = null
	if unit_node and unit_node.has_method("get_unit_data"):
		data = unit_node.get_unit_data()
	var can_upgrade := data != null and data.can_upgrade \
		and data.upgrades_to != null and player_essence >= data.upgrade_cost
	return [
		{"action_id": "attack", "label": "Attack", "enabled": true, "description": "Attack a target"},
		{"action_id": "move", "label": "Move", "enabled": true, "description": "Move to another tile"},
		{"action_id": "upgrade", "label": "Upgrade", "enabled": can_upgrade, "description": "Upgrade this unit"},
		{"action_id": "inspect", "label": "Inspect", "enabled": true, "description": "View unit details"},
	]

func _build_placement_context() -> Dictionary:
	"""Supply the radial menu with current validation context (T024)."""
	return {
		"resources": player_essence,
		"tile_valid": is_in_deployment_zone(radial_origin, 0),
		"tile_occupied": troop_manager.get_unit_at_map_coord(radial_origin) != null,
		"now_ms": Time.get_ticks_msec(),
	}

func _on_radial_unit_hovered(unit_id: String):
	emit_signal("deploy_unit_hovered", unit_id)

func _on_radial_unit_unhovered():
	# Mouse left a deploy icon -> hide the shared info-panel preview.
	emit_signal("deploy_preview_ended")

func _on_radial_unit_selected(unit_id: String, origin: Vector2i):
	"""Successful placement: spawn the real unit via troop_manager, deduct
	essence, re-validate affordability, then close the radial as 'placed'."""
	var unit := _find_radial_unit(unit_id)
	var cost := int(unit.get("unit_cost", 0)) if not unit.is_empty() else 0
	troop_manager.set_current_unit(unit_id)
	if troop_manager.place_unit(origin):
		player_essence = maxi(0, player_essence - cost)
		_deploy_log("Placed %s at %s (essence=%d)" % [unit_id, str(origin), player_essence])
	else:
		_deploy_log("troop_manager rejected placement of %s at %s" % [unit_id, str(origin)])
	if radial_menu_instance:
		radial_menu_instance.revalidate_affordability(player_essence)
	emit_signal("deploy_unit_selected", unit_id, origin)
	_close_radial_menu("placed")

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
	if player_essence < data.upgrade_cost:
		_deploy_log("Not enough essence to upgrade at %s" % str(origin))
		return
	player_essence -= data.upgrade_cost
	unit_node.data = data.upgrades_to
	_deploy_log("Upgraded unit at %s to %s (essence=%d)" % [str(origin), data.upgrades_to.unit_name, player_essence])

func _begin_pending_action(kind: String, unit_node, origin: Vector2i):
	# Move/Attack need a follow-up target-selection step. For now we record the
	# pending action and log intent; the target picker is a future task.
	pending_action = {"type": kind, "unit": unit_node, "origin": origin}
	_deploy_log("%s requested for unit at %s (awaiting target tile)" % [kind.capitalize(), str(origin)])

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

func set_player_essence(amount: int):
	"""Set player essence for testing affordability (temporary for T018)"""
	player_essence = amount
	_deploy_log("Player essence set to: %d" % player_essence)

func get_player_essence() -> int:
	"""Get current player essence"""
	return player_essence
