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

func _ready():
	# Hide the panel by default
	hide_panel()

func show_unit(unit: Node):
	if not unit or not unit.has_method("get_unit_data"):
		print("show_unit called for invalid unit.")
		hide_panel()
		return

	var unit_data = unit.get_unit_data() # Assuming unit has a method to get its data
	if not unit_data:
		GameLog.error("Unit node does not have valid unit_data.")
		hide_panel()
		return

	# Populate labels
	unit_name_label.text = "Unit Name: " + unit_data.unit_name
	unit_role_label.text = "Role: " + unit_data.unit_role
	unit_cost_label.text = "Cost: " + str(unit_data.unit_cost) # Assuming unit_cost is an int
	health_label.text = "Health: " + str(unit_data.stats_block.health)
	attack_label.text = "Attack: " + str(unit_data.stats_block.attack)
	range_label.text = "Range: " + str(unit_data.stats_block.range)
	armor_label.text = "Armor: " + str(unit_data.stats_block.armor)
	speed_label.text = "Speed: " + str(unit_data.stats_block.speed)

	# Set unit image
	for child in unit_viewport.get_children():
		child.queue_free()

	if unit.has_method("get_artwork_node"):
		var artwork_node = unit.get_artwork_node()
		if artwork_node:
			unit_viewport.add_child(artwork_node)
			# Center the artwork within the viewport
			if artwork_node is Node2D:
				var viewport_size = unit_viewport.size
				var center_x = viewport_size.x / 2.0
				var center_y = viewport_size.y / 2.0
				artwork_node.position = Vector2(center_x, center_y)
				artwork_node.scale = Vector2(1.8, 1.8)
		else:
			GameLog.info("Unit's get_artwork_node() returned null.")
	else:
		GameLog.info("Unit does not have a get_artwork_node() method.")

	visible = true
	print("UnitInfoPanel visible set to true.")

## Hides the unit information panel and clears its contents.
func hide_panel():
	print("hide_panel called.")
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
	for child in unit_viewport.get_children():
		child.queue_free()
	for child in unit_viewport.get_children():
		child.queue_free()
