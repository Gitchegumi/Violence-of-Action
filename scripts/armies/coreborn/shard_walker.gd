extends Node2D
class_name ShardWalker

@export var data: UnitType
var map_pos: Vector2i
var controller_player_id := 0
var movement_remaining := 0
var took_non_movement_action := false
var disengaged_this_turn := false
var post_combat_movement_unlocked := false
var entered_engagement_this_turn := false
var maximum_hp := 0
var current_hp := 0
var attacked_this_turn := false

signal selected(unit: ShardWalker)

func _ready():
	if data == null:
		push_error("Unit spawned without data.")
		return
	initialize_combat_state()

	# Apply art
	if $UnitArtwork and data.artwork_region.has_area():
		$UnitArtwork.region_enabled = true
		$UnitArtwork.region_rect = data.artwork_region

	# C	if $UnitSelection:
		$UnitSelection.input_pickable = true
		$UnitSelection.input_event.connect(_on_input)

func _on_input(_vp, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("selected", self)
		get_viewport().set_input_as_handled()

func set_selected(on: bool) -> void:
	if has_node("SelectionRing"):
		$SelectionRing.visible = on

func get_unit_data() -> UnitType:
	return data


func reset_turn_state() -> void:
	if maximum_hp <= 0:
		initialize_combat_state()
	movement_remaining = int(data.stats_block.get("speed", 0)) if data else 0
	took_non_movement_action = false
	disengaged_this_turn = false
	post_combat_movement_unlocked = false
	entered_engagement_this_turn = false
	attacked_this_turn = false


func initialize_combat_state() -> void:
	maximum_hp = int(data.stats_block.get("health", 0)) if data else 0
	current_hp = maximum_hp


func record_non_movement_action() -> bool:
	if disengaged_this_turn:
		return false
	took_non_movement_action = true
	return true

func get_artwork_node() -> Node:
	if $UnitArtwork:
		var artwork := $UnitArtwork.duplicate()
		if data != null and data.artwork_region.has_area():
			artwork.region_enabled = true
			artwork.region_rect = data.artwork_region
		return artwork
	return null
