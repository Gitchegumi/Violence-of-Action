extends Node

var match_config: Dictionary = {}


func set_match_config(config: Dictionary) -> void:
	match_config = {
		"player_count": int(config.get("player_count", 2)),
		"seed": int(config.get("seed", 0)),
	}


func has_match_config() -> bool:
	return not match_config.is_empty()


func clear_match_config() -> void:
	match_config.clear()
