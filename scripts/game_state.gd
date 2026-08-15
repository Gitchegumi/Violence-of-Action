extends Node

signal state_changed(previous: State, current: State)
signal phase_changed(previous: TurnPhase, current: TurnPhase, player_id: int, round_number: int)
signal turn_started(player_id: int, round_number: int)
signal turn_ended(player_id: int, round_number: int)
signal game_over_declared(winner_player_id: int, reason: String)

enum State {
	MENU,
	INITIAL_DEPLOYMENT,
	PLAYING,
	PAUSED,
	GAME_OVER,
}

enum TurnPhase {
	START_TURN,
	MARSHAL_TROOPS,
	MOVEMENT,
	COMBAT,
	RESOLVE,
	CLEAN_UP,
}

const PHASE_ORDER: Array[TurnPhase] = [
	TurnPhase.START_TURN,
	TurnPhase.MARSHAL_TROOPS,
	TurnPhase.MOVEMENT,
	TurnPhase.COMBAT,
	TurnPhase.RESOLVE,
	TurnPhase.CLEAN_UP,
]

var current_state := State.MENU
var current_phase := TurnPhase.START_TURN
var player_count := 2
var active_player_id := 0
var starting_player_id := 0
var round_number := 0
var deployment_ready: Dictionary = {}
var winner_player_id := -1
var game_over_reason := ""
var _state_before_pause := State.PLAYING


func begin_match(config: Dictionary) -> void:
	player_count = clampi(int(config.get("player_count", 2)), 2, 3)
	var starting_player_rng := RandomNumberGenerator.new()
	starting_player_rng.seed = int(config.get("seed", 0))
	starting_player_id = starting_player_rng.randi_range(0, player_count - 1)
	active_player_id = 0
	round_number = 0
	current_phase = TurnPhase.START_TURN
	deployment_ready.clear()
	for player_id in range(player_count):
		deployment_ready[player_id] = false
	winner_player_id = -1
	game_over_reason = ""
	_change_state(State.INITIAL_DEPLOYMENT)


func mark_deployment_ready(player_id: int) -> bool:
	if current_state != State.INITIAL_DEPLOYMENT or not deployment_ready.has(player_id):
		return false
	deployment_ready[player_id] = true
	for is_ready in deployment_ready.values():
		if not is_ready:
			return false
	_start_playing()
	return true


func start_playing_for_test(configured_player_count: int = 2) -> void:
	player_count = clampi(configured_player_count, 2, 3)
	starting_player_id = 0
	active_player_id = 0
	round_number = 1
	current_phase = TurnPhase.START_TURN
	_change_state(State.PLAYING)
	if current_state != State.PLAYING:
		return
	turn_started.emit(active_player_id, round_number)
	phase_changed.emit(TurnPhase.CLEAN_UP, current_phase, active_player_id, round_number)


func advance_phase() -> bool:
	if current_state != State.PLAYING:
		return false
	var phase_index := PHASE_ORDER.find(current_phase)
	var previous_phase := current_phase
	if phase_index < PHASE_ORDER.size() - 1:
		current_phase = PHASE_ORDER[phase_index + 1]
		phase_changed.emit(previous_phase, current_phase, active_player_id, round_number)
		return true
	var ending_player := active_player_id
	turn_ended.emit(ending_player, round_number)
	if current_state != State.PLAYING:
		return true
	active_player_id = (active_player_id + 1) % player_count
	if active_player_id == starting_player_id:
		round_number += 1
	current_phase = TurnPhase.START_TURN
	turn_started.emit(active_player_id, round_number)
	phase_changed.emit(previous_phase, current_phase, active_player_id, round_number)
	return true


func pause_game() -> bool:
	if current_state not in [State.INITIAL_DEPLOYMENT, State.PLAYING]:
		return false
	_state_before_pause = current_state
	_change_state(State.PAUSED)
	get_tree().paused = true
	return true


func resume_game() -> bool:
	if current_state != State.PAUSED:
		return false
	get_tree().paused = false
	_change_state(_state_before_pause)
	return true


func declare_game_over(player_id: int, reason: String) -> bool:
	if current_state not in [State.PLAYING, State.PAUSED]:
		return false
	get_tree().paused = false
	winner_player_id = player_id
	game_over_reason = reason
	_change_state(State.GAME_OVER)
	game_over_declared.emit(player_id, reason)
	return true


func return_to_menu() -> void:
	get_tree().paused = false
	_change_state(State.MENU)


func get_state_name() -> String:
	return State.keys()[current_state].capitalize()


func get_phase_name() -> String:
	return TurnPhase.keys()[current_phase].capitalize()


func _start_playing() -> void:
	round_number = 1
	active_player_id = starting_player_id
	current_phase = TurnPhase.START_TURN
	_change_state(State.PLAYING)
	if current_state != State.PLAYING:
		return
	turn_started.emit(active_player_id, round_number)
	phase_changed.emit(TurnPhase.CLEAN_UP, current_phase, active_player_id, round_number)


func _change_state(next_state: State) -> void:
	if current_state == next_state:
		return
	var previous := current_state
	current_state = next_state
	state_changed.emit(previous, current_state)
