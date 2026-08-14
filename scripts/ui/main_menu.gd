extends Control

signal match_config_created(config: Dictionary)

const GAMEPLAY_SCENE := "res://scenes/main.tscn"

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


func _ready() -> void:
	GameState.return_to_menu()
	start_button.pressed.connect(open_setup_dialog)
	rules_button.pressed.connect(open_rules_dialog)
	quit_button.pressed.connect(_quit_game)
	setup_dialog.confirmed.connect(_start_game)
	setup_dialog.canceled.connect(_focus_start_button)
	rules_dialog.confirmed.connect(_focus_rules_button)
	player_count_option.item_selected.connect(_on_player_count_selected)
	player_count_option.select(0)
	_refresh_player_identity_rows(2)
	start_button.grab_focus()


func open_setup_dialog() -> void:
	rules_dialog.hide()
	setup_error.text = ""
	setup_dialog.popup_centered(Vector2i(560, 440))
	player_count_option.grab_focus()


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


func _get_identity_validation_error(player_count: int) -> String:
	var selected_colors: Array[Color] = []
	for player_id in range(player_count):
		if player_name_inputs[player_id].text.strip_edges().is_empty():
			return "Player %d must enter a name." % (player_id + 1)
		var color := player_color_inputs[player_id].color
		if color.a <= 0.0:
			return "Player %d must choose a color." % (player_id + 1)
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
