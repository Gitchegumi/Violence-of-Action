extends Node2D

var unit_data = null
var map_pos := Vector2i.ZERO
var controller_player_id := 0
var movement_remaining := 0
var took_non_movement_action := false
var disengaged_this_turn := false
var post_combat_movement_unlocked := false
var entered_engagement_this_turn := false
var maximum_hp := 0
var current_hp := 0
var attacked_this_turn := false

func get_unit_data():
	return unit_data


func reset_turn_state() -> void:
	if maximum_hp <= 0:
		initialize_combat_state()
	movement_remaining = int(unit_data.stats_block.get("speed", 0)) if unit_data else 0
	took_non_movement_action = false
	disengaged_this_turn = false
	post_combat_movement_unlocked = false
	entered_engagement_this_turn = false
	attacked_this_turn = false


func initialize_combat_state() -> void:
	maximum_hp = int(unit_data.stats_block.get("health", 0)) if unit_data else 0
	current_hp = maximum_hp


func record_non_movement_action() -> bool:
	if disengaged_this_turn:
		return false
	took_non_movement_action = true
	return true
