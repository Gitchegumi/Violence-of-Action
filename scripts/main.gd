extends Node

func _ready():
	var tile_map := $TileMapLayer
	$ResourceManager.essence_changed.connect(_on_essence_changed)
	_on_essence_changed(0, $ResourceManager.get_essence(0), 0, "initial")
	# Clicking a placed unit (or the Inspect action) shows its info.
	tile_map.unit_selected.connect($UnitInfoPanel.show_unit)
	# Deploy radial: preview the hovered unit in the same panel, and clear it
	# when the deploy radial closes (so it shows only while choosing).
	tile_map.deploy_unit_hovered.connect(_on_deploy_unit_hovered)
	tile_map.deploy_preview_ended.connect($UnitInfoPanel.hide_panel)
	$AdvancePhaseButton.pressed.connect(_on_advance_phase_pressed)
	GameState.state_changed.connect(_on_state_changed)
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.turn_started.connect(_on_turn_started)
	GameState.turn_ended.connect(_on_turn_ended)
	_refresh_turn_ui()

func _on_deploy_unit_hovered(unit_id: String) -> void:
	var data = $TileMapLayer.get_unit_type(unit_id)
	if data:
		$UnitInfoPanel.show_unit_type(data, $TileMapLayer.get_unit_artwork(unit_id))


func _on_essence_changed(player_id: int, total: int, _delta: int, _reason: String) -> void:
	if player_id == GameState.active_player_id:
		$EssenceLabel.text = "Player %d Essence: %d" % [player_id + 1, total]


func _on_advance_phase_pressed() -> void:
	if GameState.current_state == GameState.State.INITIAL_DEPLOYMENT:
		GameState.mark_deployment_ready(GameState.active_player_id)
		if GameState.current_state == GameState.State.INITIAL_DEPLOYMENT:
			GameState.active_player_id = (GameState.active_player_id + 1) % GameState.player_count
			_refresh_turn_ui()
	elif GameState.current_state == GameState.State.PLAYING:
		GameState.advance_phase()


func _on_state_changed(_previous, _current) -> void:
	_refresh_turn_ui()


func _on_phase_changed(_previous, _current, _player_id: int, _round_number: int) -> void:
	_refresh_turn_ui()


func _on_turn_started(player_id: int, _round_number: int) -> void:
	$TileMapLayer.troop_manager.start_turn(player_id)
	$ResourceManager.start_turn(player_id, $TileMapLayer.troop_manager.get_units_for_player(player_id))


func _on_turn_ended(player_id: int, _round_number: int) -> void:
	$ResourceManager.resolve_objective_upkeep(player_id)


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
			$TurnLabel.text = "Game Over"
	$AdvancePhaseButton.disabled = GameState.current_state not in [
		GameState.State.INITIAL_DEPLOYMENT,
		GameState.State.PLAYING,
	]
