extends Node

signal unit_destroyed(unit: Node, player_id: int, destruction_id: String)
signal attack_resolved(attacker: Node, defender: Node, result: Dictionary)

const CombatResolverScript = preload("res://scripts/systems/combat_resolver.gd")

# TroopManager is responsible for handling the placement of units on the map.
# Keep mechanics out of main.gd; this node is created/owned by the TileMap scene.

@export var tile_map: TileMapLayer
@export var shardwalker_scene: PackedScene = preload("res://scenes/armies/coreborn/ShardWalker.tscn")

# Where your .tres live (adjust to your layout)
@export var units_dirs: Array[String] = [
	"res://assets/data/armies/TheCoreborn/tier-1",
	"res://assets/data/armies/TheCoreborn/tier-2",
	"res://assets/data/armies/TheCoreborn/tier-3",
]

# id -> UnitData
var catalog: Dictionary = {}
var current_unit_id: String = ""

# map_pos (Vector2i) -> Unit
var units_on_map: Dictionary = {}

func _ready():
	_load_unit_catalog()

func _load_unit_catalog():
	catalog.clear()
	for dir_path in units_dirs:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			push_warning("TroopManager: could not open " + dir_path)
			continue
		dir.list_dir_begin()
		while true:
			var f = dir.get_next()
			if f == "": break
			if dir.current_is_dir(): continue
			if f.ends_with(".tres"):
				var res: Resource = ResourceLoader.load(dir_path + "/" + f)
				if res and res is UnitType:
					catalog[f.get_basename()] = res
		dir.list_dir_end()

	# Pick a default unit if none selected
	if current_unit_id == "" and catalog.size() > 0:
		current_unit_id = catalog.keys()[0]

func set_current_unit(id: String) -> void:
	if catalog.has(id):
		current_unit_id = id
	else:
		push_warning("Unknown unit id: " + id)

func place_unit(map_pos: Vector2i, player_id: int) -> bool:
	if tile_map == null: return false
	if units_on_map.has(map_pos): return false
	if current_unit_id == "" or not catalog.has(current_unit_id):
		push_warning("No unit selected for placement.")
		return false

	# Example passability gate: only land for now
	var terrain: TerrainType = tile_map.terrain_data_map.get(map_pos)
	if terrain == null or terrain.passable_by != "land":
		return false

	var u: ShardWalker = shardwalker_scene.instantiate()
	u.data = catalog[current_unit_id]
	u.map_pos = map_pos
	u.controller_player_id = player_id
	u.position = _center_of_tile(map_pos)
	# Scale the unit down for tile map placement
	u.scale = Vector2(0.15, 0.15)
	u.reset_turn_state()
	tile_map.add_child(u)
	units_on_map[map_pos] = u
	u.selected.connect(_on_unit_selected)
	return true


func start_turn(player_id: int) -> void:
	for unit in get_units_for_player(player_id):
		if unit.has_method("reset_turn_state"):
			unit.reset_turn_state()


func move_unit(unit: Node, destination: Vector2i) -> Dictionary:
	var validation := get_move_validation(unit)
	if not validation.valid:
		return {"success": false, "reason": validation.reason, "path": [], "cost": 0}
	var path_result := find_cheapest_path(unit, destination)
	if not path_result.success:
		return path_result
	var origin: Vector2i = unit.map_pos
	units_on_map.erase(origin)
	units_on_map[destination] = unit
	unit.map_pos = destination
	unit.position = _center_of_tile(destination)
	unit.movement_remaining -= int(path_result.cost)
	if int(validation.adjacent_enemies) == 1:
		unit.disengaged_this_turn = true
	elif get_adjacent_enemies(unit).size() > 0:
		unit.entered_engagement_this_turn = true
	return path_result


func get_move_validation(unit: Node) -> Dictionary:
	var movement_phase := GameState.current_phase == GameState.TurnPhase.MOVEMENT
	var unlocked_after_combat := GameState.current_phase == GameState.TurnPhase.COMBAT \
		and unit != null and bool(unit.get("post_combat_movement_unlocked"))
	if GameState.current_state != GameState.State.PLAYING \
		or not (movement_phase or unlocked_after_combat):
		return {"valid": false, "reason": "not_movement_phase", "adjacent_enemies": 0}
	if unit == null or int(unit.get("controller_player_id")) != GameState.active_player_id:
		return {"valid": false, "reason": "not_active_player", "adjacent_enemies": 0}
	if int(unit.get("movement_remaining")) <= 0:
		return {"valid": false, "reason": "no_movement_remaining", "adjacent_enemies": 0}
	if bool(unit.get("disengaged_this_turn")):
		return {"valid": false, "reason": "disengagement_complete", "adjacent_enemies": 0}
	var adjacent_enemies := get_adjacent_enemies(unit).size()
	if adjacent_enemies > 1:
		return {"valid": false, "reason": "pinned", "adjacent_enemies": adjacent_enemies}
	if adjacent_enemies == 1 and (
		bool(unit.get("took_non_movement_action")) \
		or bool(unit.get("entered_engagement_this_turn"))
	):
		return {"valid": false, "reason": "engaged_after_action", "adjacent_enemies": adjacent_enemies}
	return {"valid": true, "reason": "", "adjacent_enemies": adjacent_enemies}


func find_cheapest_path(unit: Node, destination: Vector2i) -> Dictionary:
	var origin: Vector2i = unit.map_pos
	var origin_enemy_ids := _adjacent_enemy_ids(unit, origin)
	if destination == origin:
		return {"success": false, "reason": "same_tile", "path": [], "cost": 0}
	if not tile_map.terrain_data_map.has(destination):
		return {"success": false, "reason": "off_map", "path": [], "cost": 0}
	if units_on_map.has(destination):
		return {"success": false, "reason": "destination_occupied", "path": [], "cost": 0}
	var frontier: Array = [{"coord": origin, "cost": 0}]
	var costs := {origin: 0}
	var came_from: Dictionary = {}
	var budget: int = int(unit.get("movement_remaining"))
	while not frontier.is_empty():
		frontier.sort_custom(func(a, b):
			if a.cost == b.cost:
				return a.coord.x < b.coord.x or (a.coord.x == b.coord.x and a.coord.y < b.coord.y)
			return a.cost < b.cost
		)
		var current: Dictionary = frontier.pop_front()
		var current_coord: Vector2i = current.coord
		if current.cost != costs.get(current_coord):
			continue
		if current_coord == destination:
			break
		if current_coord != origin and _has_new_enemy_engagement(unit, current_coord, origin_enemy_ids):
			continue
		for neighbor in tile_map._get_neighbors(current_coord):
			var step_cost := _movement_cost(unit, neighbor)
			if step_cost < 0 or _is_enemy_occupied(unit, neighbor):
				continue
			var candidate: int = int(current.cost) + step_cost
			if candidate > budget or (costs.has(neighbor) and candidate >= int(costs[neighbor])):
				continue
			costs[neighbor] = candidate
			came_from[neighbor] = current_coord
			frontier.append({"coord": neighbor, "cost": candidate})
	if not costs.has(destination):
		return {"success": false, "reason": "unreachable", "path": [], "cost": 0}
	var path: Array[Vector2i] = [destination]
	var cursor := destination
	while cursor != origin:
		cursor = came_from[cursor]
		path.push_front(cursor)
	return {"success": true, "reason": "", "path": path, "cost": int(costs[destination])}


func get_adjacent_enemies(unit: Node) -> Array:
	return _get_enemies_adjacent_to(unit, unit.map_pos)


func _get_enemies_adjacent_to(unit: Node, coord: Vector2i) -> Array:
	var enemies: Array = []
	for neighbor in tile_map._get_neighbors(coord):
		var occupant = get_unit_at_map_coord(neighbor)
		if occupant != null and int(occupant.get("controller_player_id")) != int(unit.get("controller_player_id")):
			enemies.append(occupant)
	return enemies


func _adjacent_enemy_ids(unit: Node, coord: Vector2i) -> Dictionary:
	var enemy_ids: Dictionary = {}
	for enemy in _get_enemies_adjacent_to(unit, coord):
		enemy_ids[enemy.get_instance_id()] = true
	return enemy_ids


func _has_new_enemy_engagement(unit: Node, coord: Vector2i, origin_enemy_ids: Dictionary) -> bool:
	for enemy in _get_enemies_adjacent_to(unit, coord):
		if not origin_enemy_ids.has(enemy.get_instance_id()):
			return true
	return false


func can_record_non_movement_action(unit: Node) -> bool:
	return unit != null and not bool(unit.get("disengaged_this_turn"))


func record_non_movement_action(unit: Node) -> bool:
	if not can_record_non_movement_action(unit):
		return false
	if unit.has_method("record_non_movement_action"):
		return unit.record_non_movement_action()
	unit.set("took_non_movement_action", true)
	return true


func record_attack_resolution(unit: Node, destroyed_enemy: bool, was_decisively_engaged: bool) -> bool:
	if not record_non_movement_action(unit):
		return false
	unit.set(
		"post_combat_movement_unlocked",
		was_decisively_engaged and destroyed_enemy and get_adjacent_enemies(unit).is_empty()
	)
	return true


func get_attack_validation(attacker: Node, defender: Node) -> Dictionary:
	var start_validation := get_attack_start_validation(attacker)
	if not start_validation.valid:
		return start_validation
	if not _is_live_unit(defender):
		return {"valid": false, "reason": "invalid_target"}
	if int(attacker.controller_player_id) == int(defender.controller_player_id):
		return {"valid": false, "reason": "friendly_target"}
	if _hex_distance(attacker.map_pos, defender.map_pos) > _unit_stat(attacker, "range"):
		return {"valid": false, "reason": "out_of_range"}
	if not tile_map.has_line_of_sight(attacker.map_pos, defender.map_pos):
		return {"valid": false, "reason": "line_of_sight_blocked"}
	return {"valid": true, "reason": ""}


func get_attack_start_validation(attacker: Node) -> Dictionary:
	if GameState.current_state != GameState.State.PLAYING \
		or GameState.current_phase not in [GameState.TurnPhase.COMBAT, GameState.TurnPhase.RESOLVE]:
		return {"valid": false, "reason": "not_combat_phase"}
	if not _is_live_unit(attacker):
		return {"valid": false, "reason": "invalid_attacker"}
	if int(attacker.controller_player_id) != GameState.active_player_id:
		return {"valid": false, "reason": "not_active_player"}
	if bool(attacker.get("attacked_this_turn")):
		return {"valid": false, "reason": "attack_already_used"}
	if bool(attacker.get("disengaged_this_turn")):
		return {"valid": false, "reason": "disengaged_this_turn"}
	return {"valid": true, "reason": ""}


func resolve_attack(attacker: Node, defender: Node, die_one: int, die_two: int) -> Dictionary:
	var validation := get_attack_validation(attacker, defender)
	if not validation.valid:
		return {"success": false, "reason": validation.reason}
	var was_decisively_engaged := get_adjacent_enemies(attacker).size() == 1
	var result: Dictionary = CombatResolverScript.resolve_attack(
		attacker,
		defender,
		die_one,
		die_two,
		_defense_terrain_modifier(defender.map_pos),
	)
	attacker.attacked_this_turn = true
	if bool(result.destroyed):
		destroy_unit(defender)
	record_attack_resolution(attacker, bool(result.destroyed), was_decisively_engaged)
	result["success"] = true
	result["reason"] = ""
	attack_resolved.emit(attacker, defender, result)
	return result


func roll_attack(attacker: Node, defender: Node, rng: RandomNumberGenerator) -> Dictionary:
	var validation := get_attack_validation(attacker, defender)
	if not validation.valid:
		return {"success": false, "reason": validation.reason}
	return resolve_attack(attacker, defender, rng.randi_range(1, 6), rng.randi_range(1, 6))


func _is_live_unit(unit: Node) -> bool:
	return is_instance_valid(unit) and int(unit.get("current_hp")) > 0 \
		and units_on_map.get(unit.map_pos) == unit


func _unit_stat(unit: Node, stat_name: String) -> int:
	var data = unit.get_unit_data() if unit != null and unit.has_method("get_unit_data") else null
	return int(data.stats_block.get(stat_name, 0)) if data != null else 0


func _defense_terrain_modifier(coord: Vector2i) -> int:
	var terrain: TerrainType = tile_map.terrain_data_map.get(coord)
	return 1 if terrain != null and terrain.terrain_name.to_lower() == "forest" else 0


func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	var delta := a - b
	return maxi(maxi(abs(delta.x), abs(delta.y)), abs(delta.x + delta.y))


func _movement_cost(unit: Node, coord: Vector2i) -> int:
	var terrain: TerrainType = tile_map.terrain_data_map.get(coord)
	if terrain == null:
		return -1
	var terrain_key := terrain.terrain_name.to_lower()
	if terrain_key == "objective":
		return maxi(1, terrain.move_cost)
	var data: UnitType = unit.get_unit_data() if unit.has_method("get_unit_data") else null
	if data == null:
		return -1
	return int(data.terrain_type_matrix.get(terrain_key, -1))


func _is_enemy_occupied(unit: Node, coord: Vector2i) -> bool:
	var occupant = get_unit_at_map_coord(coord)
	return occupant != null \
		and int(occupant.get("controller_player_id")) != int(unit.get("controller_player_id"))

func count_units(unit_id: String, player_id: int) -> int:
	var expected: UnitType = catalog.get(unit_id)
	if expected == null:
		return 0
	var count := 0
	for unit in units_on_map.values():
		if unit == null or not unit.has_method("get_unit_data"):
			continue
		if int(unit.get("controller_player_id")) != player_id:
			continue
		var actual: UnitType = unit.get_unit_data()
		if actual == expected or (
			actual != null
			and not actual.resource_path.is_empty()
			and actual.resource_path == expected.resource_path
		):
			count += 1
	return count

func get_units_for_player(player_id: int) -> Array:
	var result: Array = []
	for unit in units_on_map.values():
		if unit != null and int(unit.get("controller_player_id")) == player_id:
			result.append(unit)
	return result

func get_unit_at_map_coord(map_pos: Vector2i) -> Node:
	if units_on_map.has(map_pos):
		return units_on_map[map_pos]
	return null


func destroy_unit(unit: Node, destruction_id: String = "") -> bool:
	if unit == null or not units_on_map.has(unit.map_pos) or units_on_map[unit.map_pos] != unit:
		return false
	var player_id := int(unit.get("controller_player_id"))
	var resolved_id := destruction_id
	if resolved_id.is_empty():
		resolved_id = "unit_%d" % unit.get_instance_id()
	units_on_map.erase(unit.map_pos)
	unit_destroyed.emit(unit, player_id, resolved_id)
	unit.queue_free()
	return true

# Returns a standalone artwork node for a unit type (for info-panel previews of
# not-yet-placed units). get_artwork_node() returns a duplicate, so freeing the
# temporary scene instance is safe.
func get_unit_artwork(unit_id: String) -> Node:
	var scene := _scene_for_unit_id(unit_id)
	if scene == null:
		return null
	var inst := scene.instantiate()
	var artwork: Node = null
	if inst.has_method("get_artwork_node"):
		artwork = inst.get_artwork_node()
	inst.free()
	return artwork

func _scene_for_unit_id(unit_id: String) -> PackedScene:
	# Only the Shard Walker has a scene wired up so far.
	if unit_id == "shard_walker":
		return shardwalker_scene
	return null

func _center_of_tile(map_pos: Vector2i) -> Vector2:
	# For hex stairs right layout, Godot's map_to_local returns the center
	return tile_map.map_to_local(map_pos)

func _on_unit_selected(unit: ShardWalker):
	print("Selected: ", unit.data.unit_name, " @ ", unit.map_pos)
