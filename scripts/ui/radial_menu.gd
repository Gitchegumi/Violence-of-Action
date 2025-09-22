extends Control

# Re-emit signals from the tile_map or deployment_controller
signal deploy_unit_hovered(unit_id)
signal deploy_unit_selected(unit_id, origin)
signal deploy_radial_closed(reason)

var current_units: Array = []
var origin_position: Vector2i
var unit_icons: Array = []  # Store references to created unit icons

func open(origin_tile: Vector2i, units: Array):
	"""Open radial menu with units, applying affordability visual states"""
	current_units = units
	origin_position = origin_tile
	
	# Clear existing UI
	_clear_ui()
	
	# Create unit icons with affordability states
	_create_unit_icons()
	
	# Show the menu
	show()

func close(reason: String):
	"""Close radial menu and cleanup"""
	_clear_ui()
	hide()
	emit_signal("deploy_radial_closed", reason)

func _clear_ui():
	"""Clear all UI elements"""
	for icon in unit_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	unit_icons.clear()

func _create_unit_icons():
	"""Create unit icon UI elements with affordability visual states"""
	var radius = 80  # Distance from center
	var angle_step = 2 * PI / max(1, current_units.size())
	
	for i in range(current_units.size()):
		var unit = current_units[i]
		var angle = i * angle_step
		
		# Create icon button (basic approach)
		var icon_button = Button.new()
		icon_button.text = unit.unit_name
		icon_button.custom_minimum_size = Vector2(60, 60)
		
		# Position in circle
		var pos = Vector2(
			radius * cos(angle),
			radius * sin(angle)
		)
		icon_button.position = pos + size / 2 - icon_button.custom_minimum_size / 2
		
		# Apply affordability visual state
		if not unit.get("affordable", true):
			# Disabled visual state: gray modulation and reduced alpha
			icon_button.modulate = Color(0.5, 0.5, 0.5, 0.6)
			icon_button.disabled = true
		else:
			# Normal state
			icon_button.modulate = Color.WHITE
			icon_button.disabled = false
		
		# Connect signals for interaction (for future tasks)
		if not icon_button.disabled:
			icon_button.pressed.connect(_on_unit_selected.bind(unit.unit_id))
		
		# Add to scene and track
		add_child(icon_button)
		unit_icons.append(icon_button)

func _on_unit_selected(unit_id: String):
	"""Handle unit selection"""
	emit_signal("deploy_unit_selected", unit_id, origin_position)

func update_affordability(units: Array):
	"""Update affordability states for existing units (for future use)"""
	current_units = units
	
	# Update visual states of existing icons
	for i in range(min(unit_icons.size(), current_units.size())):
		var icon = unit_icons[i]
		var unit = current_units[i]
		
		if is_instance_valid(icon) and icon is Button:
			if not unit.get("affordable", true):
				# Disabled visual state
				icon.modulate = Color(0.5, 0.5, 0.5, 0.6)
				icon.disabled = true
			else:
				# Normal state
				icon.modulate = Color.WHITE
				icon.disabled = false
