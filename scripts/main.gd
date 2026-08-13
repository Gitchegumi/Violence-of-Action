extends Node

func _ready():
	var tile_map := $TileMapLayer
	$ResourceManager.essence_changed.connect(_on_essence_changed)
	$ResourceManager.objective_control_changed.connect(_on_objective_control_changed)
	$ResourceManager.objective_control_turns_changed.connect(_on_objective_control_turns_changed)
	_on_essence_changed(0, $ResourceManager.get_essence(0), 0, "initial")
	# Clicking a placed unit (or the Inspect action) shows its info.
	tile_map.unit_selected.connect($UnitInfoPanel.show_unit)
	# Deploy radial: preview the hovered unit in the same panel, and clear it
	# when the deploy radial closes (so it shows only while choosing).
	tile_map.deploy_unit_hovered.connect(_on_deploy_unit_hovered)
	tile_map.deploy_preview_ended.connect($UnitInfoPanel.hide_panel)
	tile_map.pending_action_changed.connect(_on_pending_action_changed)
	tile_map.unit_attack_resolved.connect(_on_unit_attack_resolved)
	tile_map.troop_manager.unit_destroyed.connect(_on_unit_destroyed)
	$AdvancePhaseButton.pressed.connect(_on_advance_phase_pressed)
	$CancelActionButton.pressed.connect(tile_map.cancel_pending_action)
	GameState.state_changed.connect(_on_state_changed)
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.turn_started.connect(_on_turn_started)
	GameState.turn_ended.connect(_on_turn_ended)
	_refresh_turn_ui()
	_refresh_objective_ui()

func _on_deploy_unit_hovered(unit_id: String) -> void:
	var data = $TileMapLayer.get_unit_type(unit_id)
	if data:
		$UnitInfoPanel.show_unit_type(data, $TileMapLayer.get_unit_artwork(unit_id))


func _on_essence_changed(player_id: int, total: int, _delta: int, _reason: String) -> void:
	if player_id == GameState.active_player_id:
		$EssenceLabel.text = "Player %d Essence: %d" % [player_id + 1, total]


func _on_objective_control_changed(_previous_player_id: int, _player_id: int) -> void:
	_refresh_objective_ui()


func _on_objective_control_turns_changed(_player_id: int, _turns: int) -> void:
	_refresh_objective_ui()


func _refresh_objective_ui() -> void:
	if $ResourceManager.objective_controller == ResourceManager.NO_PLAYER:
		$ObjectiveLabel.text = "Objective: Uncontrolled"
		return
	$ObjectiveLabel.text = "Objective: Player %d (%d/%d)" % [
		$ResourceManager.objective_controller + 1,
		$ResourceManager.objective_control_turns,
		ResourceManager.OBJECTIVE_TURNS_TO_WIN,
	]


func _on_advance_phase_pressed() -> void:
	if GameState.current_state == GameState.State.INITIAL_DEPLOYMENT:
		var player_id := GameState.active_player_id
		if $TileMapLayer.troop_manager.get_units_for_player(player_id).is_empty():
			$DeploymentAlert.dialog_text = (
				"Player %d must place at least one unit in their army before declaring Ready."
				% (player_id + 1)
			)
			$DeploymentAlert.popup_centered(Vector2i(480, 160))
			return
		GameState.mark_deployment_ready(GameState.active_player_id)
		if GameState.current_state == GameState.State.INITIAL_DEPLOYMENT:
			GameState.active_player_id = (GameState.active_player_id + 1) % GameState.player_count
			_refresh_turn_ui()
	elif GameState.current_state == GameState.State.PLAYING:
		GameState.advance_phase()


func _on_state_changed(previous, current) -> void:
	_refresh_turn_ui()
	if previous == GameState.State.INITIAL_DEPLOYMENT and current == GameState.State.PLAYING:
		_evaluate_elimination_victory()


func _on_phase_changed(_previous, _current, _player_id: int, _round_number: int) -> void:
	$TileMapLayer.cancel_pending_action()
	_refresh_turn_ui()


func _on_pending_action_changed(active: bool, action_type: String) -> void:
	$CancelActionButton.visible = active
	$CancelActionButton.text = "Cancel %s" % action_type.capitalize() if active else "Cancel Action"


func _on_unit_attack_resolved(_attacker: Node, _defender: Node, result: Dictionary) -> void:
	$CombatResultLabel.visible = true
	$CombatResultLabel.text = "Attack: %d + %d + %d vs %d - %s (%d HP)" % [
		result.die_one,
		result.die_two,
		result.attack_value,
		result.defense_target,
		"Hit" if result.hit else "Miss",
		result.remaining_hp,
	]


func _on_turn_started(player_id: int, _round_number: int) -> void:
	$TileMapLayer.troop_manager.start_turn(player_id)
	$ResourceManager.start_turn(player_id, $TileMapLayer.troop_manager.get_units_for_player(player_id))


func _on_turn_ended(player_id: int, _round_number: int) -> void:
	var objective_unit = $TileMapLayer.troop_manager.get_unit_at_map_coord($TileMapLayer.objective_position)
	if objective_unit != null:
		$ResourceManager.capture_objective(int(objective_unit.get("controller_player_id")))
	var objective_result: Dictionary = $ResourceManager.resolve_objective_turn(player_id)
	if bool(objective_result.victory):
		GameState.declare_game_over(player_id, "objective_control")


func _on_unit_destroyed(_unit: Node, _player_id: int, destruction_id: String) -> void:
	$ResourceManager.record_unit_destroyed(destruction_id)
	_evaluate_elimination_victory()


func _evaluate_elimination_victory() -> bool:
	if GameState.current_state != GameState.State.PLAYING:
		return false
	var surviving_players: Array[int] = []
	for player_id in range(GameState.player_count):
		if not $TileMapLayer.troop_manager.get_units_for_player(player_id).is_empty():
			surviving_players.append(player_id)
	if surviving_players.size() != 1:
		return false
	return GameState.declare_game_over(surviving_players[0], "elimination")


func _refresh_turn_ui() -> void:
	$PauseOverlay.visible = GameState.current_state == GameState.State.PAUSED
	$EssenceLabel.text = "Player %d Essence: %d" % [
		GameState.active_player_id + 1,
		$ResourceManager.get_essence(GameState.active_player_id),
	]
	match GameState.current_state:
		GameState.State.INITIAL_DEPLOYMENT:
			$TurnLabel.text = "Initial Deployment - Player %d" % (GameState.active_player_id + 1)
			$AdvancePhaseButton.text = "Ready Player %d" % (GameState.active_player_id + 1)
		GameState.State.PLAYING:
			$TurnLabel.text = "Round %d - Player %d - %s" % [
				GameState.round_number,
				GameState.active_player_id + 1,
				GameState.get_phase_name(),
			]
			$AdvancePhaseButton.text = "Complete Phase"
		GameState.State.PAUSED:
			$TurnLabel.text = "Paused"
		GameState.State.GAME_OVER:
			$TurnLabel.text = "Game Over - Player %d Wins (%s)" % [
				GameState.winner_player_id + 1,
				GameState.game_over_reason.capitalize(),
			]
	$AdvancePhaseButton.disabled = GameState.current_state not in [
		GameState.State.INITIAL_DEPLOYMENT,
		GameState.State.PLAYING,
	]
