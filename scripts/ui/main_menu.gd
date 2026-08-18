extends Control

signal match_config_created(config: Dictionary)

const GAMEPLAY_SCENE := "res://scenes/main.tscn"
const ControllerKeyboard = preload("res://scripts/ui/controller_keyboard.gd")
const ControllerColorPicker = preload("res://scripts/ui/controller_color_picker.gd")

@onready var start_button: Button = $Center/Menu/StartButton
@onready var rules_button: Button = $Center/Menu/RulesButton
@onready var quit_button: Button = $Center/Menu/QuitButton
@onready var setup_dialog: ConfirmationDialog = $SetupDialog
@onready var player_count_option: OptionButton = $SetupDialog/SetupFields/PlayerCountOption
@onready var seed_input: LineEdit = $SetupDialog/SetupFields/SeedInput
@onready var identity_rows: Array[HBoxContainer] = [
	$SetupDialog/SetupFields/Player1Identity,
	$SetupDialog/SetupFields/Player2Identity,
	$SetupDialog/SetupFields/Player3Identity,
]
@onready var player_name_inputs: Array[LineEdit] = [
	$SetupDialog/SetupFields/Player1Identity/NameInput,
	$SetupDialog/SetupFields/Player2Identity/NameInput,
	$SetupDialog/SetupFields/Player3Identity/NameInput,
]
@onready var player_color_inputs: Array[ColorPickerButton] = [
	$SetupDialog/SetupFields/Player1Identity/ColorInput,
	$SetupDialog/SetupFields/Player2Identity/ColorInput,
	$SetupDialog/SetupFields/Player3Identity/ColorInput,
]
@onready var setup_error: Label = $SetupDialog/SetupFields/SetupError
@onready var rules_dialog: AcceptDialog = $RulesDialog
var player_color_selected: Array[bool] = [false, false, false]
var controller_keyboard = null
var controller_color_picker = null
var _controller_popup_open_pending := false


func _ready() -> void:
	GameState.return_to_menu()
	controller_color_picker = ControllerColorPicker.new()
	add_child(controller_color_picker)
	controller_color_picker.color_changed.connect(_on_controller_color_changed)
	controller_color_picker.color_committed.connect(_on_controller_color_committed)
	controller_color_picker.selection_restored.connect(_on_controller_color_selection_restored)
	start_button.pressed.connect(open_setup_dialog)
	rules_button.pressed.connect(open_rules_dialog)
	quit_button.pressed.connect(_quit_game)
	setup_dialog.confirmed.connect(_start_game)
	setup_dialog.canceled.connect(_focus_start_button)
	setup_dialog.window_input.connect(_on_setup_dialog_input)
	rules_dialog.confirmed.connect(_focus_rules_button)
	player_count_option.item_selected.connect(_on_player_count_selected)
	for player_id in range(player_color_inputs.size()):
		player_color_inputs[player_id].color_changed.connect(_on_player_color_changed.bind(player_id))
	player_count_option.select(0)
	_refresh_player_identity_rows(2)
	start_button.grab_focus()


func _input(event: InputEvent) -> void:
	if setup_dialog.visible:
		return
	if _handle_controller_setup_input(event):
		get_viewport().set_input_as_handled()


func _on_setup_dialog_input(event: InputEvent) -> void:
	if _handle_setup_dialog_navigation(event) or _handle_controller_setup_input(event):
		setup_dialog.get_viewport().set_input_as_handled()


func _handle_setup_dialog_navigation(event: InputEvent) -> bool:
	if (controller_keyboard != null and controller_keyboard.visible) \
			or controller_color_picker.is_active() \
			or not event is InputEventJoypadButton or not event.pressed:
		return false
	var focused := setup_dialog.get_viewport().gui_get_focus_owner()
	if event.is_action_pressed("gamepad_primary_action") \
			and focused == setup_dialog.get_cancel_button():
		setup_dialog.hide()
		setup_dialog.canceled.emit()
		return true
	var next: Control = null
	match event.button_index:
		JOY_BUTTON_DPAD_DOWN:
			if focused == seed_input:
				next = setup_dialog.get_ok_button()
		JOY_BUTTON_DPAD_UP:
			if focused == setup_dialog.get_ok_button() \
					or focused == setup_dialog.get_cancel_button():
				next = seed_input
		JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT:
			if focused == setup_dialog.get_ok_button():
				next = setup_dialog.get_cancel_button()
			elif focused == setup_dialog.get_cancel_button():
				next = setup_dialog.get_ok_button()
	if next == null:
		return false
	next.grab_focus()
	return true


func _handle_controller_setup_input(event: InputEvent) -> bool:
	if _controller_popup_open_pending:
		return event is InputEventJoypadButton and event.pressed \
			and event.is_action_pressed("gamepad_primary_action")
	if (controller_keyboard != null and controller_keyboard.visible) \
			or controller_color_picker.is_active():
		return false
	if not event is InputEventJoypadButton or not event.pressed \
			or not event.is_action_pressed("gamepad_primary_action"):
		return false
	for input: LineEdit in player_name_inputs:
		if input.has_focus():
			_open_controller_keyboard(input, event.device)
			return true
	for player_id in range(player_color_inputs.size()):
		if player_color_inputs[player_id].has_focus():
			if event.device >= 0:
				_controller_popup_open_pending = true
				_begin_controller_color_picker_deferred.call_deferred(
					player_color_inputs[player_id],
					player_id,
					player_color_selected[player_id],
					event.device
				)
			else:
				controller_color_picker.begin(
					player_color_inputs[player_id],
					player_id,
					player_color_selected[player_id],
					event.device
				)
			return true
	return false


func _open_controller_keyboard(input: LineEdit, opening_device := -1) -> void:
	if controller_keyboard == null:
		controller_keyboard = ControllerKeyboard.new()
		add_child(controller_keyboard)
		controller_keyboard.entry_committed.connect(_on_controller_keyboard_committed)
	if opening_device >= 0:
		_controller_popup_open_pending = true
		_open_controller_keyboard_deferred.call_deferred(input, opening_device)
	else:
		controller_keyboard.open_for(input, opening_device)


func _open_controller_keyboard_deferred(input: LineEdit, opening_device: int) -> void:
	_controller_popup_open_pending = false
	controller_keyboard.open_for(input, opening_device)


func _begin_controller_color_picker_deferred(
	button: ColorPickerButton,
	player_id: int,
	was_selected: bool,
	opening_device: int,
) -> void:
	_controller_popup_open_pending = false
	controller_color_picker.begin(button, player_id, was_selected, opening_device)


func _on_controller_keyboard_committed(input: LineEdit) -> void:
	var player_id := player_name_inputs.find(input)
	if player_id >= 0:
		setup_dialog.grab_focus()
		player_color_inputs[player_id].grab_focus()


func open_setup_dialog() -> void:
	rules_dialog.hide()
	setup_error.text = ""
	setup_dialog.popup_centered(Vector2i(560, 440))
	player_count_option.grab_focus()
	player_count_option.grab_focus.call_deferred()


func open_rules_dialog() -> void:
	setup_dialog.hide()
	rules_dialog.popup_centered(Vector2i(720, 520))
	rules_dialog.get_ok_button().grab_focus()


func get_open_popup_count() -> int:
	return int(setup_dialog.visible) + int(rules_dialog.visible)


static func build_match_config(
	player_count: int,
	seed_text: String,
	fallback_seed: int = 0,
	players: Array = [],
) -> Dictionary:
	var resolved_player_count := clampi(player_count, 2, 3)
	var normalized_seed := seed_text.strip_edges()
	var resolved_seed := fallback_seed
	if not normalized_seed.is_empty():
		resolved_seed = int(normalized_seed)
	elif resolved_seed == 0:
		var random := RandomNumberGenerator.new()
		random.randomize()
		resolved_seed = random.randi()
	var config := {"player_count": resolved_player_count, "seed": resolved_seed}
	if not players.is_empty():
		config["players"] = players.duplicate(true)
	return config


func _start_game() -> void:
	submit_setup(true)


func submit_setup(transition_to_game: bool = true) -> Dictionary:
	var player_count := player_count_option.get_item_id(player_count_option.selected)
	_refresh_player_identity_rows(player_count)
	var validation_error := _get_identity_validation_error(player_count)
	if not validation_error.is_empty():
		setup_error.text = validation_error
		if transition_to_game:
			setup_dialog.popup_centered(Vector2i(560, 440))
		return {}
	setup_error.text = ""
	var players: Array = []
	for player_id in range(player_count):
		players.append({
			"name": player_name_inputs[player_id].text.strip_edges(),
			"color": player_color_inputs[player_id].color,
		})
	var config := build_match_config(player_count, seed_input.text, 0, players)
	GameSession.set_match_config(config)
	GameState.begin_match(config)
	match_config_created.emit(config)
	if transition_to_game:
		get_tree().change_scene_to_file(GAMEPLAY_SCENE)
	return config


func _on_player_count_selected(index: int) -> void:
	_refresh_player_identity_rows(player_count_option.get_item_id(index))


func _refresh_player_identity_rows(player_count: int) -> void:
	for player_id in range(identity_rows.size()):
		identity_rows[player_id].visible = player_id < player_count


func _on_player_color_changed(color: Color, player_id: int) -> void:
	player_color_selected[player_id] = true
	var opaque_color := color
	opaque_color.a = 1.0
	if not player_color_inputs[player_id].color.is_equal_approx(opaque_color):
		player_color_inputs[player_id].color = opaque_color


func _on_controller_color_changed(color: Color, player_id: int) -> void:
	_on_player_color_changed(color, player_id)


func _on_controller_color_committed(color: Color, player_id: int) -> void:
	_on_player_color_changed(color, player_id)


func _on_controller_color_selection_restored(player_id: int, was_selected: bool) -> void:
	player_color_selected[player_id] = was_selected


func _get_identity_validation_error(player_count: int) -> String:
	var selected_colors: Array[Color] = []
	for player_id in range(player_count):
		if player_name_inputs[player_id].text.strip_edges().is_empty():
			return "Player %d must enter a name." % (player_id + 1)
		if not player_color_selected[player_id]:
			return "Player %d must choose a color." % (player_id + 1)
		var color := player_color_inputs[player_id].color
		for selected_color in selected_colors:
			if color.is_equal_approx(selected_color):
				return "Each player must choose a different color."
		selected_colors.append(color)
	return ""


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if rules_dialog.visible:
			rules_dialog.hide()
			_focus_rules_button()
			get_viewport().set_input_as_handled()
		elif setup_dialog.visible:
			setup_dialog.hide()
			_focus_start_button()
			get_viewport().set_input_as_handled()


func _focus_start_button() -> void:
	start_button.grab_focus()


func _focus_rules_button() -> void:
	rules_button.grab_focus()


func _quit_game() -> void:
	get_tree().quit()
