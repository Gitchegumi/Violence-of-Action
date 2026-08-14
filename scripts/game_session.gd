extends Node

var match_config: Dictionary = {}


func set_match_config(config: Dictionary) -> void:
	match_config = {
		"player_count": int(config.get("player_count", 2)),
		"seed": int(config.get("seed", 0)),
	}
	if config.has("players"):
		match_config["players"] = (config.get("players", []) as Array).duplicate(true)


func has_match_config() -> bool:
	return not match_config.is_empty()


func clear_match_config() -> void:
	match_config.clear()


func get_player_name(player_id: int) -> String:
	var players: Array = match_config.get("players", [])
	if player_id >= 0 and player_id < players.size():
		var configured_name := String((players[player_id] as Dictionary).get("name", "")).strip_edges()
		if not configured_name.is_empty():
			return configured_name
	return "Player %d" % (player_id + 1)


func get_player_color(player_id: int) -> Color:
	var players: Array = match_config.get("players", [])
	if player_id >= 0 and player_id < players.size():
		var configured_color = (players[player_id] as Dictionary).get("color", Color.WHITE)
		if configured_color is Color:
			return configured_color
	return Color.WHITE
