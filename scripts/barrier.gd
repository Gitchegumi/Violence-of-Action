extends Node2D
class_name TacticalBarrier

const MAXIMUM_HP := 1
const ARMOR := 2
const OWNER_TURNS := 3

var map_pos := Vector2i.ZERO
var owner_player_id := -1
var source_fluxsmith_id := 0
var current_hp := MAXIMUM_HP
var owner_turns_remaining := OWNER_TURNS
var display_color := Color.WHITE


func configure(position_on_map: Vector2i, player_id: int, source_id: int, color: Color) -> void:
	map_pos = position_on_map
	owner_player_id = player_id
	source_fluxsmith_id = source_id
	display_color = color
	queue_redraw()


func get_unit_data() -> Dictionary:
	return {"stats_block": {"armor": ARMOR}}


func _draw() -> void:
	# Functional placeholder presentation until the creative barrier asset exists.
	var points := PackedVector2Array([
		Vector2(-24, -18), Vector2(24, -18), Vector2(30, 0),
		Vector2(24, 18), Vector2(-24, 18), Vector2(-30, 0),
	])
	var fill := display_color
	fill.a = 0.38
	draw_colored_polygon(points, fill)
	draw_polyline(PackedVector2Array(Array(points) + [points[0]]), display_color, 4.0, true)
