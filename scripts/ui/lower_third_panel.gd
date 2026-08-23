extends PanelContainer
class_name LowerThirdPanel

const PANEL_HEIGHT := 220.0

var focused_coordinate := Vector2i(-1, -1)
var current_unit: Node = null
var showing_catalog_preview := false

var terrain_coordinate_label: Label
var terrain_name_label: Label
var terrain_movement_label: Label
var terrain_passability_label: Label
var terrain_upkeep_label: Label

var unit_viewport: SubViewport
var unit_name_label: Label
var unit_role_label: Label
var unit_cost_label: Label
var health_label: Label
var attack_label: Label
var range_label: Label
var armor_label: Label
var speed_label: Label
var movement_label: Label
var combat_result_label: Label

var turn_label: Label
var objective_label: Label
var essence_label: Label
var income_label: Label
var advance_phase_button: Button
var cancel_action_button: Button
var return_to_menu_button: Button


func _init() -> void:
	name = "LowerThirdPanel"
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -PANEL_HEIGHT
	offset_bottom = 0.0
	custom_minimum_size = Vector2(0.0, PANEL_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_panel()


func _build_panel() -> void:
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var regions := HBoxContainer.new()
	regions.name = "Regions"
	regions.add_theme_constant_override("separation", 8)
	margin.add_child(regions)

	regions.add_child(_build_terrain_region())
	regions.add_child(_build_unit_combat_region())
	regions.add_child(_build_match_region())


func _build_terrain_region() -> Control:
	var region := _region("TerrainRegion", 0.27)
	var content := _region_content(region)
	content.add_child(_heading("Terrain"))
	terrain_coordinate_label = _label("Coordinate: —")
	terrain_name_label = _label("Terrain: No tile focused")
	terrain_movement_label = _label("Base movement cost: —")
	terrain_passability_label = _label("Passable by: —")
	terrain_upkeep_label = _label("Hold cost: —")
	content.add_child(terrain_coordinate_label)
	content.add_child(terrain_name_label)
	content.add_child(terrain_movement_label)
	content.add_child(terrain_passability_label)
	content.add_child(terrain_upkeep_label)
	return region


func _build_unit_combat_region() -> Control:
	var region := _region("UnitCombatRegion", 0.46)
	var content := _region_content(region)
	content.add_child(_heading("Unit and latest result"))

	var unit_row := HBoxContainer.new()
	unit_row.add_theme_constant_override("separation", 8)
	content.add_child(unit_row)

	var image_container := SubViewportContainer.new()
	image_container.name = "UnitImageContainer"
	image_container.custom_minimum_size = Vector2(86.0, 86.0)
	image_container.stretch = true
	image_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unit_row.add_child(image_container)
	unit_viewport = SubViewport.new()
	unit_viewport.name = "UnitImageViewport"
	unit_viewport.size = Vector2i(512, 512)
	unit_viewport.transparent_bg = true
	unit_viewport.handle_input_locally = false
	unit_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	image_container.add_child(unit_viewport)

	var details := VBoxContainer.new()
	details.name = "UnitDetails"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit_row.add_child(details)
	unit_name_label = _label("Unit: Empty")
	unit_role_label = _label("Role: —")
	unit_cost_label = _label("Cost: —")
	var profile_row := HBoxContainer.new()
	profile_row.add_theme_constant_override("separation", 12)
	health_label = _label("Health: —")
	attack_label = _label("Attack: —")
	range_label = _label("Range: —")
	armor_label = _label("Armor: —")
	speed_label = _label("Speed: —")
	movement_label = _label("Movement: —")
	details.add_child(unit_name_label)
	details.add_child(unit_role_label)
	details.add_child(unit_cost_label)
	profile_row.add_child(health_label)
	profile_row.add_child(attack_label)
	profile_row.add_child(range_label)
	profile_row.add_child(armor_label)
	profile_row.add_child(speed_label)
	details.add_child(profile_row)
	details.add_child(movement_label)

	combat_result_label = _label("Latest result: None")
	combat_result_label.name = "CombatResultLabel"
	combat_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(combat_result_label)
	show_empty_unit()
	return region


func _build_match_region() -> Control:
	var region := _region("MatchRegion", 0.27)
	var content := _region_content(region)
	content.add_child(_heading("Match status"))
	turn_label = _label("Initial Deployment")
	objective_label = _label("Objective: Uncontrolled")
	essence_label = _label("Player 1 Essence: 12")
	income_label = _label("Latest income: —")
	content.add_child(turn_label)
	content.add_child(objective_label)
	content.add_child(essence_label)
	content.add_child(income_label)

	var actions := HBoxContainer.new()
	actions.name = "Actions"
	actions.add_theme_constant_override("separation", 6)
	content.add_child(actions)
	advance_phase_button = Button.new()
	advance_phase_button.name = "AdvancePhaseButton"
	advance_phase_button.text = "Ready Player 1"
	advance_phase_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(advance_phase_button)
	cancel_action_button = Button.new()
	cancel_action_button.name = "CancelActionButton"
	cancel_action_button.text = "Cancel Action"
	cancel_action_button.visible = false
	actions.add_child(cancel_action_button)
	return_to_menu_button = Button.new()
	return_to_menu_button.name = "ReturnToMenuButton"
	return_to_menu_button.text = "Return to Main Menu"
	return_to_menu_button.visible = false
	content.add_child(return_to_menu_button)
	return region


func _region(region_name: String, ratio: float) -> PanelContainer:
	var region := PanelContainer.new()
	region.name = region_name
	region.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	region.size_flags_stretch_ratio = ratio
	return region


func _region_content(region: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	region.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	margin.add_child(content)
	return content


func _heading(text_value: String) -> Label:
	var result := _label(text_value)
	result.add_theme_font_size_override("font_size", 18)
	return result


func _label(text_value: String) -> Label:
	var result := Label.new()
	result.text = text_value
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


func show_terrain(coordinate: Vector2i, terrain: TerrainType) -> void:
	focused_coordinate = coordinate
	if terrain == null:
		terrain_coordinate_label.text = "Coordinate: —"
		terrain_name_label.text = "Terrain: No tile focused"
		terrain_movement_label.text = "Base movement cost: —"
		terrain_passability_label.text = "Passable by: —"
		terrain_upkeep_label.text = "Hold cost: —"
		return
	terrain_coordinate_label.text = "Coordinate: %s" % str(coordinate)
	terrain_name_label.text = "Terrain: %s" % terrain.terrain_name
	terrain_movement_label.text = "Base movement cost: %d" % terrain.move_cost
	terrain_passability_label.text = "Passable by: %s" % terrain.passable_by.capitalize()
	terrain_upkeep_label.text = "Hold cost: %d Essence" % terrain.essence_cost_to_hold


func show_unit(unit: Node) -> void:
	if unit == null or not is_instance_valid(unit) or not unit.has_method("get_unit_data"):
		show_empty_unit()
		return
	var unit_data = unit.get_unit_data()
	if unit_data == null:
		show_empty_unit()
		return
	current_unit = unit
	showing_catalog_preview = false
	_bind_unit_profile(unit_data, unit.get_artwork_node() if unit.has_method("get_artwork_node") else null)
	refresh_current_unit()


func show_unit_type(unit_data, artwork: Node = null) -> void:
	if unit_data == null:
		show_empty_unit()
		return
	current_unit = null
	showing_catalog_preview = true
	_bind_unit_profile(unit_data, artwork)
	unit_name_label.text = "Unit preview: %s" % _value(unit_data, "unit_name", "Unknown")
	movement_label.text = "Movement: Profile only"
	movement_label.visible = true


func _bind_unit_profile(unit_data, artwork: Node) -> void:
	var stats = _value(unit_data, "stats_block", {})
	unit_name_label.text = "Unit: %s" % _value(unit_data, "unit_name", "Unknown")
	unit_role_label.text = "Role: %s" % _value(unit_data, "unit_role", "—")
	unit_cost_label.text = "Cost: %s" % str(_value(unit_data, "unit_cost", "—"))
	health_label.text = "Health: %s" % str(_value(stats, "health", "—"))
	attack_label.text = "Attack: %s" % str(_value(stats, "attack", "—"))
	range_label.text = "Range: %s" % str(_value(stats, "range", "—"))
	armor_label.text = "Armor: %s" % str(_value(stats, "armor", "—"))
	speed_label.text = "Speed: %s" % str(_value(stats, "speed", "—"))
	_set_artwork(artwork)


func refresh_current_unit() -> void:
	if current_unit == null or not is_instance_valid(current_unit):
		return
	var unit_data = current_unit.get_unit_data()
	if unit_data == null:
		return
	var stats = _value(unit_data, "stats_block", {})
	health_label.text = "Health: %d/%d" % [
		int(current_unit.get("current_hp")),
		int(current_unit.get("maximum_hp")),
	]
	movement_label.text = "Movement: %d/%d" % [
		int(current_unit.get("movement_remaining")),
		int(_value(stats, "speed", 0)),
	]
	movement_label.visible = true


func show_empty_unit() -> void:
	current_unit = null
	showing_catalog_preview = false
	unit_name_label.text = "Unit: Empty"
	unit_role_label.text = "Role: —"
	unit_cost_label.text = "Cost: —"
	health_label.text = "Health: —"
	attack_label.text = "Attack: —"
	range_label.text = "Range: —"
	armor_label.text = "Armor: —"
	speed_label.text = "Speed: —"
	movement_label.text = "Movement: —"
	movement_label.visible = false
	_set_artwork(null)


func set_combat_result(text_value: String) -> void:
	combat_result_label.text = "Latest result: %s" % text_value


func _set_artwork(artwork: Node) -> void:
	for child in unit_viewport.get_children():
		unit_viewport.remove_child(child)
		child.queue_free()
	if artwork == null:
		return
	unit_viewport.add_child(artwork)
	if artwork is Node2D:
		artwork.position = Vector2(unit_viewport.size) / 2.0
		artwork.scale = Vector2(1.8, 1.8)


func _value(source, property_name: String, default_value):
	if source is Dictionary:
		return source.get(property_name, default_value)
	if source is Object:
		var value = source.get(property_name)
		return default_value if value == null else value
	return default_value
