extends Control

@onready var unit_viewport: SubViewport = get_node("Panel/UnitImageContainer/UnitImageViewport")
@onready var unit_name_label: Label = get_node("Panel/UnitNameLabel")
@onready var unit_role_label: Label = get_node("Panel/UnitRoleLabel")
@onready var unit_cost_label: Label = get_node("Panel/UnitCostLabel")
@onready var health_label: Label = get_node("Panel/HealthLabel")
@onready var attack_label: Label = get_node("Panel/AttackLabel")
@onready var range_label: Label = get_node("Panel/RangeLabel")
@onready var armor_label: Label = get_node("Panel/ArmorLabel")
@onready var speed_label: Label = get_node("Panel/SpeedLabel")
@onready var movement_label: Label = get_node("Panel/MovementLabel")

var current_unit: Node = null

func _ready():
	# Hide the panel by default
	hide_panel()

## Show a placed unit node (has get_unit_data() and optionally get_artwork_node()).
func show_unit(unit: Node):
	if not unit or not unit.has_method("get_unit_data"):
		print("show_unit called for invalid unit.")
		hide_panel()
		return

	var unit_data = unit.get_unit_data()
	if not unit_data:
		GameLog.error("Unit node does not have valid unit_data.")
		hide_panel()
		return

	var artwork: Node = null
	if unit.has_method("get_artwork_node"):
		artwork = unit.get_artwork_node()
	show_unit_type(unit_data, artwork)
	current_unit = unit
	refresh_current_unit()

## Show unit details directly from data (UnitType resource or a data dict),
## with optional artwork. Used by the deploy radial to preview an unplaced unit
## on hover, reusing this panel's look instead of a separate overlay.
func show_unit_type(unit_data, artwork: Node = null):
	if not unit_data:
		hide_panel()
		return
	current_unit = null

	# Populate labels
	unit_name_label.text = "Unit Name: " + str(unit_data.unit_name)
	unit_role_label.text = "Role: " + str(unit_data.unit_role)
	unit_cost_label.text = "Cost: " + str(unit_data.unit_cost)
	health_label.text = "Health: " + str(unit_data.stats_block.health)
	attack_label.text = "Attack: " + str(unit_data.stats_block.attack)
	range_label.text = "Range: " + str(unit_data.stats_block.range)
	armor_label.text = "Armor: " + str(unit_data.stats_block.armor)
	speed_label.text = "Speed: " + str(unit_data.stats_block.speed)
	movement_label.text = ""
	movement_label.visible = false

	# Set unit image
	for child in unit_viewport.get_children():
		child.queue_free()

	if artwork:
		unit_viewport.add_child(artwork)
		if artwork is Node2D:
			var viewport_size = unit_viewport.size
			artwork.position = Vector2(viewport_size.x / 2.0, viewport_size.y / 2.0)
			artwork.scale = Vector2(1.8, 1.8)

	visible = true


## Refresh values that belong to a live placed unit rather than its profile.
func refresh_current_unit() -> void:
	if current_unit == null or not is_instance_valid(current_unit):
		return
	var unit_data = current_unit.get_unit_data()
	if unit_data == null:
		return
	health_label.text = "Health: %d/%d" % [
		int(current_unit.get("current_hp")),
		int(current_unit.get("maximum_hp")),
	]
	movement_label.text = "Movement: %d/%d" % [
		int(current_unit.get("movement_remaining")),
		int(unit_data.stats_block.get("speed", 0)),
	]
	movement_label.visible = true

## Hides the unit information panel and clears its contents.
func hide_panel():
	print("hide_panel called.")
	current_unit = null
	visible = false
	# Optionally clear labels when hidden
	unit_name_label.text = "Unit Name: "
	unit_role_label.text = "Role: "
	unit_cost_label.text = "Cost: "
	health_label.text = "Health: "
	attack_label.text = "Attack: "
	range_label.text = "Range: "
	armor_label.text = "Armor: "
	speed_label.text = "Speed: "
	movement_label.text = ""
	movement_label.visible = false
	for child in unit_viewport.get_children():
		child.queue_free()
