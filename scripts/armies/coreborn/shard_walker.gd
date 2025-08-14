extends Node2D
class_name ShardWalker

@export var data: UnitType
var map_pos: Vector2i

signal selected(unit: ShardWalker)
signal moved(unit: ShardWalker, from: Vector2i, to: Vector2i)

func _ready():
	if data == null:
		push_error("Unit spawned without data.")
		return
	
	# Apply art
	if $Sprite and data.texture:
		$Sprite.texture = data.texture

	# Click to select
	if $ClickArea:
		$ClickArea.input_pickable = true
		$ClickArea.input_event.connect(_on_input)

func _on_input(_vp, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("selected", self)

func set_selected(on: bool) -> void:
	if has_node("SelectionRing"):
		$SelectionRing.visible = on
