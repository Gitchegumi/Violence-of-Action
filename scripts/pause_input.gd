extends Node


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_ESCAPE:
		return
	if GameState.current_state in [GameState.State.INITIAL_DEPLOYMENT, GameState.State.PLAYING]:
		GameState.pause_game()
	elif GameState.current_state == GameState.State.PAUSED:
		GameState.resume_game()
	get_viewport().set_input_as_handled()
