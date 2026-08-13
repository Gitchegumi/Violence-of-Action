extends Node
class_name ResourceManager

signal essence_changed(player_id: int, total: int, delta: int, reason: String)
signal objective_control_changed(previous_player_id: int, player_id: int)

const INITIAL_ESSENCE := 12
const SCAVENGER_REWARD_PER_DESTRUCTION := 3
const OBJECTIVE_CAPTURE_BONUS := 6
const OBJECTIVE_UPKEEP := 3
const NO_PLAYER := -1

var balances: Dictionary = {}
var pending_destructions: Dictionary = {}
var upgraded_units_this_turn: Dictionary = {}
var objective_controller := NO_PLAYER
var _destruction_serial := 0


func _ready() -> void:
	var configured_players := 2
	if GameSession.has_match_config():
		configured_players = int(GameSession.match_config.get("player_count", 2))
	configure_players(configured_players)


func configure_players(player_count: int, initial_essence: int = INITIAL_ESSENCE) -> void:
	balances.clear()
	pending_destructions.clear()
	upgraded_units_this_turn.clear()
	objective_controller = NO_PLAYER
	for player_id in range(clampi(player_count, 2, 3)):
		balances[player_id] = maxi(0, initial_essence)
		pending_destructions[player_id] = {}
		upgraded_units_this_turn[player_id] = {}


func get_essence(player_id: int) -> int:
	return int(balances.get(player_id, 0))


func set_essence(player_id: int, amount: int, reason: String = "set") -> void:
	var previous := get_essence(player_id)
	balances[player_id] = maxi(0, amount)
	_emit_essence_change(player_id, get_essence(player_id) - previous, reason)


func can_afford(player_id: int, cost: int) -> bool:
	return cost >= 0 and get_essence(player_id) >= cost


func try_spend(player_id: int, cost: int, reason: String) -> bool:
	if not can_afford(player_id, cost):
		return false
	balances[player_id] = get_essence(player_id) - cost
	_emit_essence_change(player_id, -cost, reason)
	return true


func add_essence(player_id: int, amount: int, reason: String) -> int:
	if amount <= 0:
		return get_essence(player_id)
	balances[player_id] = get_essence(player_id) + amount
	_emit_essence_change(player_id, amount, reason)
	return get_essence(player_id)


func start_turn(player_id: int, active_units: Array) -> int:
	upgraded_units_this_turn[player_id] = {}
	var income := calculate_diversity_income(active_units)
	if _contains_scavenger(active_units):
		income += SCAVENGER_REWARD_PER_DESTRUCTION * pending_destructions.get(player_id, {}).size()
	pending_destructions[player_id] = {}
	if income > 0:
		add_essence(player_id, income, "start_turn_income")
	return income


func record_unit_destroyed(destruction_id: String = "") -> String:
	var resolved_id := destruction_id
	if resolved_id.is_empty():
		_destruction_serial += 1
		resolved_id = "destroyed_%d" % _destruction_serial
	for player_id in pending_destructions:
		pending_destructions[player_id][resolved_id] = true
	return resolved_id


func try_purchase_upgrade(
	player_id: int,
	unit_id: String,
	cost: int,
	is_engaged: bool,
	is_adjacent_to_enemy: bool
) -> bool:
	if unit_id.is_empty() or is_engaged or is_adjacent_to_enemy:
		return false
	if upgraded_units_this_turn.get(player_id, {}).has(unit_id):
		return false
	if not try_spend(player_id, cost, "upgrade:%s" % unit_id):
		return false
	upgraded_units_this_turn[player_id][unit_id] = true
	return true


func capture_objective(player_id: int) -> bool:
	if objective_controller == player_id:
		return false
	var previous := objective_controller
	objective_controller = player_id
	add_essence(player_id, OBJECTIVE_CAPTURE_BONUS, "objective_capture")
	objective_control_changed.emit(previous, player_id)
	return true


func resolve_objective_upkeep(player_id: int) -> bool:
	if objective_controller != player_id:
		return true
	if try_spend(player_id, OBJECTIVE_UPKEEP, "objective_upkeep"):
		return true
	var previous := objective_controller
	objective_controller = NO_PLAYER
	objective_control_changed.emit(previous, NO_PLAYER)
	return false


static func calculate_diversity_income(active_units: Array) -> int:
	var counted_types: Dictionary = {}
	var income := 0
	for unit in active_units:
		var data = unit.get_unit_data() if unit is Node and unit.has_method("get_unit_data") else unit
		if data == null or _is_scavenger(data):
			continue
		var type_id := _unit_type_id(data)
		if counted_types.has(type_id):
			continue
		counted_types[type_id] = true
		income += floori(_unit_cost(data) / 2.0)
	return income


static func _contains_scavenger(active_units: Array) -> bool:
	for unit in active_units:
		var data = unit.get_unit_data() if unit is Node and unit.has_method("get_unit_data") else unit
		if data != null and _is_scavenger(data):
			return true
	return false


static func _is_scavenger(data) -> bool:
	return _unit_name(data).to_lower() == "battlefield scavenger"


static func _unit_type_id(data) -> String:
	if data is Resource and not data.resource_path.is_empty():
		return data.resource_path
	return _unit_name(data).to_lower()


static func _unit_name(data) -> String:
	if data is Dictionary:
		return str(data.get("unit_name", ""))
	return str(data.unit_name)


static func _unit_cost(data) -> int:
	if data is Dictionary:
		return int(data.get("unit_cost", 0))
	return int(data.unit_cost)


func _emit_essence_change(player_id: int, delta: int, reason: String) -> void:
	essence_changed.emit(player_id, get_essence(player_id), delta, reason)
	GameLog.debug("economy", "Player %d essence %s%d => %d (%s)" % [
		player_id + 1,
		"+" if delta >= 0 else "",
		delta,
		get_essence(player_id),
		reason,
	])
