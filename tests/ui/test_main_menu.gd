extends GutTest

var MainMenuScene = preload("res://scenes/ui/main_menu.tscn")
var TileMapScene = preload("res://scenes/tileMap.tscn")
var menu = null


func before_each():
	GameSession.clear_match_config()
	menu = MainMenuScene.instantiate()
	add_child_autofree(menu)


func after_each():
	GameSession.clear_match_config()


func _configure_player_identities(player_count: int) -> void:
	var colors := [Color(0.3, 0.7, 1.0), Color(1.0, 0.3, 0.3), Color(0.4, 1.0, 0.4)]
	for player_id in range(player_count):
		menu.player_name_inputs[player_id].text = "Commander %d" % (player_id + 1)
		menu.player_color_inputs[player_id].color_changed.emit(colors[player_id])


func _joy_button(button: JoyButton, pressed := true, device := -1) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = pressed
	return event


func test_menu_exposes_required_options():
	assert_eq(menu.start_button.text, "Start Game")
	assert_eq(menu.rules_button.text, "Rules")
	assert_eq(menu.quit_button.text, "Quit")


func test_controller_face_buttons_are_native_ui_actions() -> void:
	var expected := {
		"ui_accept": JOY_BUTTON_A,
		"ui_cancel": JOY_BUTTON_B,
	}
	for action_name: String in expected:
		var buttons: Array[int] = []
		for event in InputMap.action_get_events(action_name):
			if event is InputEventJoypadButton:
				buttons.append(event.button_index)
		assert_has(buttons, expected[action_name])


func test_physical_primary_button_activates_focused_main_menu_button() -> void:
	assert_null(menu.controller_keyboard, "hidden keyboard window is not created during menu focus")
	menu.start_button.grab_focus()
	Input.parse_input_event(_joy_button(JOY_BUTTON_A))
	await get_tree().process_frame
	Input.parse_input_event(_joy_button(JOY_BUTTON_A, false))
	await get_tree().process_frame
	assert_true(menu.setup_dialog.visible)
	assert_true(menu.player_count_option.has_focus())


func test_primary_button_opens_qwerty_keyboard_for_focused_name() -> void:
	menu.open_setup_dialog()
	menu.player_name_inputs[0].grab_focus()
	assert_true(menu._handle_controller_setup_input(_joy_button(JOY_BUTTON_A)))
	assert_not_null(menu.controller_keyboard)
	assert_true(menu.controller_keyboard.visible)
	assert_same(menu.controller_keyboard.target_input, menu.player_name_inputs[0])


func test_live_device_zero_primary_press_opens_keyboard_without_committing() -> void:
	await _assert_live_primary_press_opens_keyboard(0)


func test_live_nonzero_device_primary_press_opens_keyboard_without_committing() -> void:
	await _assert_live_primary_press_opens_keyboard(1)
	var keyboard = menu.controller_keyboard
	assert_false(keyboard._first_button.disabled, "opening release enables keyboard navigation")
	Input.parse_input_event(_joy_button(JOY_BUTTON_DPAD_RIGHT, true, 1))
	await get_tree().process_frame
	Input.parse_input_event(_joy_button(JOY_BUTTON_DPAD_RIGHT, false, 1))
	await get_tree().process_frame
	var focused: Control = keyboard.get_viewport().gui_get_focus_owner()
	assert_not_null(focused)
	assert_eq(focused.text, "2", "D-pad selects a non-default first key")
	Input.parse_input_event(_joy_button(JOY_BUTTON_A, true, 1))
	await get_tree().process_frame
	Input.parse_input_event(_joy_button(JOY_BUTTON_A, false, 1))
	await get_tree().process_frame
	assert_eq(keyboard._preview.text, "2", "intentional A enters the navigated-to first character")
	var space_button: Button = keyboard._key_buttons.filter(
		func(button: Button): return button.text == "Space"
	)[0]
	space_button.grab_focus()
	Input.parse_input_event(_joy_button(JOY_BUTTON_DPAD_DOWN, true, 1))
	await get_tree().process_frame
	Input.parse_input_event(_joy_button(JOY_BUTTON_DPAD_DOWN, false, 1))
	await get_tree().process_frame
	assert_same(
		keyboard.get_viewport().gui_get_focus_owner(),
		keyboard.get_ok_button(),
		"D-pad reaches Done from the onscreen keyboard controls"
	)
	Input.parse_input_event(_joy_button(JOY_BUTTON_A, true, 1))
	await get_tree().process_frame
	Input.parse_input_event(_joy_button(JOY_BUTTON_A, false, 1))
	await get_tree().process_frame
	assert_false(keyboard.visible, "Done closes the onscreen keyboard")
	assert_eq(menu.player_name_inputs[0].text, "2", "Done commits the controller-entered name")


func _assert_live_primary_press_opens_keyboard(device: int) -> void:
	menu.open_setup_dialog()
	await get_tree().process_frame
	menu.player_name_inputs[0].grab_focus()
	await get_tree().process_frame
	assert_true(menu.player_name_inputs[0].has_focus(), "device %d name input has focus" % device)
	Input.parse_input_event(_joy_button(JOY_BUTTON_A, true, device))
	await get_tree().process_frame
	Input.parse_input_event(_joy_button(JOY_BUTTON_A, false, device))
	await get_tree().process_frame
	assert_true(menu.controller_keyboard.visible, "device %d leaves keyboard open" % device)
	assert_same(
		menu.controller_keyboard.target_input,
		menu.player_name_inputs[0],
		"device %d keeps name entry active" % device
	)


func test_primary_button_opens_native_full_picker_for_focused_color() -> void:
	menu.open_setup_dialog()
	menu.player_color_inputs[0].grab_focus()
	assert_true(menu._handle_controller_setup_input(_joy_button(JOY_BUTTON_A)))
	assert_true(menu.player_color_inputs[0].get_popup().visible)
	assert_true(menu.controller_color_picker.is_active())


func test_live_color_cancel_restores_unselected_transparent_sentinel() -> void:
	for device in [0, 1]:
		var original: Color = menu.player_color_inputs[0].color
		assert_false(menu.player_color_selected[0])
		menu.open_setup_dialog()
		await get_tree().process_frame
		menu.player_color_inputs[0].grab_focus()
		await get_tree().process_frame
		assert_true(menu.player_color_inputs[0].has_focus(), "device %d color input has focus" % device)
		Input.parse_input_event(_joy_button(JOY_BUTTON_A, true, device))
		await get_tree().process_frame
		Input.parse_input_event(_joy_button(JOY_BUTTON_A, false, device))
		await get_tree().process_frame
		assert_true(menu.controller_color_picker.is_active(), "device %d opens color input" % device)
		assert_eq(menu.controller_color_picker._initial_color, original)
		Input.parse_input_event(_joy_button(JOY_BUTTON_B, true, device))
		await get_tree().process_frame
		assert_false(menu.controller_color_picker.is_active(), "device %d cancel press closes color input" % device)
		Input.parse_input_event(_joy_button(JOY_BUTTON_B, false, device))
		await get_tree().process_frame
		assert_eq(menu.player_color_inputs[0].color, original)
		assert_false(menu.player_color_selected[0])


func test_two_and_three_player_configs_preserve_seed():
	assert_eq(menu.build_match_config(2, "12345", 99), {"player_count": 2, "seed": 12345})
	assert_eq(menu.build_match_config(3, "67890", 99), {"player_count": 3, "seed": 67890})


func test_blank_seed_uses_resolved_random_fallback():
	assert_eq(menu.build_match_config(2, "", 24680), {"player_count": 2, "seed": 24680})


func test_explicit_zero_seed_is_preserved():
	assert_eq(menu.build_match_config(2, "0", 24680), {"player_count": 2, "seed": 0})


func test_setup_submission_emits_and_stores_match_config():
	watch_signals(menu)
	menu.player_count_option.select(1)
	_configure_player_identities(3)
	menu.seed_input.text = "13579"
	var config: Dictionary = menu.submit_setup(false)
	assert_eq(config.player_count, 3)
	assert_eq(config.seed, 13579)
	assert_eq(config.players.size(), 3)
	assert_eq(config.players[0].name, "Commander 1")
	assert_eq(config.players[2].color, Color(0.4, 1.0, 0.4))
	assert_eq(GameSession.match_config, config)
	assert_signal_emitted_with_parameters(menu, "match_config_created", [config])


func test_setup_requires_names_and_unique_selected_colors():
	menu.player_count_option.select(0)
	assert_true(menu.submit_setup(false).is_empty())
	assert_true(menu.setup_error.text.contains("enter a name"))
	menu.player_name_inputs[0].text = "Alpha"
	menu.player_name_inputs[1].text = "Bravo"
	menu.player_color_inputs[0].color_changed.emit(Color(1, 0, 0, 0))
	menu.player_color_inputs[1].color_changed.emit(Color(1, 0, 0, 0))
	assert_eq(menu.player_color_inputs[0].color.a, 1.0, "picker selection becomes opaque")
	assert_true(menu.player_color_selected[0], "picker signal records an explicit selection")
	assert_true(menu.submit_setup(false).is_empty())
	assert_true(menu.setup_error.text.contains("different color"))
	menu.player_color_inputs[1].color_changed.emit(Color(0, 0, 1, 0))
	assert_false(menu.submit_setup(false).is_empty())


func test_player_count_controls_visible_identity_prompts():
	menu._on_player_count_selected(0)
	assert_true(menu.identity_rows[0].visible)
	assert_true(menu.identity_rows[1].visible)
	assert_false(menu.identity_rows[2].visible)
	menu._on_player_count_selected(1)
	assert_true(menu.identity_rows[2].visible)


func test_gameplay_tile_map_consumes_session_config_on_ready():
	GameSession.set_match_config({"player_count": 3, "seed": 13579})
	var tile_map = TileMapScene.instantiate()
	add_child_autofree(tile_map)
	assert_eq(tile_map.player_count, 3)
	assert_eq(tile_map.map_seed, 13579)
	assert_eq(tile_map.deployment_zones_data.size(), 3)


func test_zero_seed_is_applied_by_gameplay_map():
	GameSession.set_match_config({"player_count": 2, "seed": 0})
	var tile_map = TileMapScene.instantiate()
	add_child_autofree(tile_map)
	assert_eq(tile_map.map_seed, 0)
	assert_eq(tile_map.map_rng.seed, 0)


func test_equal_seeds_generate_identical_complete_maps():
	GameSession.set_match_config({"player_count": 2, "seed": 424242})
	var first_map = TileMapScene.instantiate()
	add_child_autofree(first_map)
	var first_snapshot := _terrain_snapshot(first_map)

	var second_map = TileMapScene.instantiate()
	add_child_autofree(second_map)
	var second_snapshot := _terrain_snapshot(second_map)
	assert_eq(second_snapshot, first_snapshot, "equal seeds reproduce the complete repaired terrain map")


func _terrain_snapshot(tile_map) -> Array[String]:
	var coordinates: Array = tile_map.terrain_data_map.keys()
	coordinates.sort_custom(func(a: Vector2i, b: Vector2i):
		return a.x < b.x or (a.x == b.x and a.y < b.y)
	)
	var snapshot: Array[String] = []
	for coordinate in coordinates:
		var terrain: TerrainType = tile_map.terrain_data_map[coordinate]
		snapshot.append("%d,%d:%s" % [coordinate.x, coordinate.y, terrain.terrain_name])
	return snapshot


func test_only_one_popup_can_be_open():
	menu.open_setup_dialog()
	assert_eq(menu.get_open_popup_count(), 1)
	menu.open_rules_dialog()
	assert_eq(menu.get_open_popup_count(), 1)
	assert_false(menu.setup_dialog.visible)
	assert_true(menu.rules_dialog.visible)


func test_escape_closes_rules_without_quitting():
	menu.open_rules_dialog()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	menu._unhandled_key_input(escape)
	assert_false(menu.rules_dialog.visible)
	assert_true(menu.is_inside_tree(), "escape closes rules without exiting the scene tree")


func test_rules_summary_is_scrollable_and_covers_required_sections():
	var scroll = menu.get_node("RulesDialog/RulesScroll")
	var text: String = menu.get_node("RulesDialog/RulesScroll/RulesText").text
	assert_true(scroll is ScrollContainer)
	for section in [
		"Start and Deployment",
		"Controls",
		"Turn Phases",
		"Movement and Engagement",
		"Combat",
		"Objective",
		"Victory",
		"Essence",
	]:
		assert_true(text.contains(section), "rules include %s" % section)
	assert_true(text.contains("Each unit may attack once per turn"))
	assert_true(text.contains("Opponents' turns do not charge upkeep or advance it"))
