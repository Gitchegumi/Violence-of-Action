extends GutTest

var RadialScene = preload("res://scenes/ui/radial_menu.tscn")
var menu = null


func _units(count: int, disabled_indices: Array[int] = []) -> Array:
	var units: Array = []
	for index in range(count):
		units.append({
			"unit_id": "u%d" % index,
			"unit_name": "Unit %d" % index,
			"unit_cost": index + 1,
			"affordable": index not in disabled_indices,
		})
	return units


func _action_event(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _joy_motion(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event


func before_each() -> void:
	menu = RadialScene.instantiate()
	menu.size = Vector2(400, 400)
	add_child_autofree(menu)


func test_project_defines_vendor_neutral_radial_actions() -> void:
	var expected_actions := {
		"radial_cycle_previous": JOY_BUTTON_LEFT_SHOULDER,
		"radial_cycle_next": JOY_BUTTON_RIGHT_SHOULDER,
		"radial_page_previous": JOY_BUTTON_LEFT_STICK,
		"radial_page_next": JOY_BUTTON_RIGHT_STICK,
	}
	for action_name: String in expected_actions:
		assert_true(InputMap.has_action(action_name), "%s is defined" % action_name)
		var mapped_buttons: Array[int] = []
		for event in InputMap.action_get_events(action_name):
			if event is InputEventJoypadButton:
				mapped_buttons.append(event.button_index)
				assert_eq(event.device, -1, "%s accepts every connected joypad" % action_name)
		assert_has(mapped_buttons, expected_actions[action_name],
			"%s uses a standard Godot joypad button" % action_name)


func test_project_defines_vendor_neutral_gameplay_buttons() -> void:
	var expected_actions := {
		"gamepad_primary_action": JOY_BUTTON_A,
		"gamepad_cancel_action": JOY_BUTTON_B,
	}
	for action_name: String in expected_actions:
		assert_true(InputMap.has_action(action_name), "%s is defined" % action_name)
		var mapped_buttons: Array[int] = []
		for mapped_event in InputMap.action_get_events(action_name):
			if mapped_event is InputEventJoypadButton:
				mapped_buttons.append(mapped_event.button_index)
				assert_eq(mapped_event.device, -1,
					"%s accepts every connected joypad" % action_name)
		assert_has(mapped_buttons, expected_actions[action_name],
			"%s uses a standard Godot joypad button" % action_name)


func test_nonzero_device_shoulder_dispatches_through_input_map() -> void:
	menu.open(Vector2i.ZERO, _units(3))
	var event := _joy_button(JOY_BUTTON_RIGHT_SHOULDER)
	event.device = 1
	Input.parse_input_event(event)
	await get_tree().process_frame
	assert_eq(menu.focus_index, 1, "device 1 reaches the mapped cycle action")
	event.pressed = false
	Input.parse_input_event(event)
	await get_tree().process_frame


func test_left_stick_routes_live_input_to_nearest_enabled_item() -> void:
	menu.open(Vector2i.ZERO, _units(4, [1]))
	menu._unhandled_input(_joy_motion(JOY_AXIS_LEFT_Y, 1.0))
	assert_eq(menu.focus_index, 0,
		"downward stick skips the disabled lower item and chooses a deterministic nearest enabled item")


func test_stick_deadzone_does_not_change_focus() -> void:
	menu.open(Vector2i.ZERO, _units(4))
	menu.focus_index = 2
	menu._unhandled_input(_joy_motion(JOY_AXIS_LEFT_X, 0.2))
	assert_eq(menu.focus_index, 2)


func test_dpad_routes_as_angular_navigation() -> void:
	menu.open(Vector2i.ZERO, _units(4))
	menu._unhandled_input(_joy_button(JOY_BUTTON_DPAD_UP))
	assert_eq(menu.focus_index, 3, "up selects the upper radial sector")
	menu._unhandled_input(_joy_button(JOY_BUTTON_DPAD_RIGHT))
	assert_eq(menu.focus_index, 0, "right selects the right radial sector")


func test_controller_cycle_actions_preserve_wraparound() -> void:
	menu.open(Vector2i.ZERO, _units(3))
	menu.focus_index = 2
	menu._unhandled_input(_action_event("radial_cycle_next"))
	assert_eq(menu.focus_index, 0)
	menu._unhandled_input(_action_event("radial_cycle_previous"))
	assert_eq(menu.focus_index, 2)


func test_controller_confirm_works_in_deploy_and_action_modes() -> void:
	menu.open(Vector2i(2, 3), _units(2))
	watch_signals(menu)
	menu._unhandled_input(_action_event("ui_accept"))
	assert_signal_emitted_with_parameters(menu, "deploy_unit_selected", ["u0", Vector2i(2, 3)])

	menu.open_actions(Vector2i(4, 5), [
		{"action_id": "move", "label": "Move", "enabled": true},
	])
	menu._unhandled_input(_action_event("ui_accept"))
	assert_signal_emitted_with_parameters(menu, "deploy_action_selected", ["move", Vector2i(4, 5)])


func test_physical_primary_button_confirms_radial_option() -> void:
	menu.open(Vector2i(2, 3), _units(2))
	watch_signals(menu)
	menu._unhandled_input(_joy_button(JOY_BUTTON_A))
	assert_signal_emitted_with_parameters(menu, "deploy_unit_selected", ["u0", Vector2i(2, 3)])


func test_controller_cancel_closes_menu() -> void:
	menu.open(Vector2i.ZERO, _units(2))
	watch_signals(menu)
	menu._unhandled_input(_action_event("ui_cancel"))
	assert_signal_emitted_with_parameters(menu, "deploy_radial_closed", ["cancel"])
	assert_false(menu.active)


func test_physical_cancel_button_closes_menu() -> void:
	menu.open(Vector2i.ZERO, _units(2))
	watch_signals(menu)
	menu._unhandled_input(_joy_button(JOY_BUTTON_B))
	assert_signal_emitted_with_parameters(menu, "deploy_radial_closed", ["cancel"])
	assert_false(menu.active)


func test_controller_page_actions_change_pages_without_confirming() -> void:
	menu.open(Vector2i.ZERO, _units(13))
	watch_signals(menu)
	menu._unhandled_input(_action_event("radial_page_next"))
	assert_eq(menu.page_index, 1)
	assert_signal_not_emitted(menu, "deploy_unit_selected")
	menu._unhandled_input(_action_event("radial_page_previous"))
	assert_eq(menu.page_index, 0)
