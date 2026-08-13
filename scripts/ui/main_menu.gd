extends Control

signal match_config_created(config: Dictionary)

const GAMEPLAY_SCENE := "res://scenes/main.tscn"

@onready var start_button: Button = $Center/Menu/StartButton
@onready var rules_button: Button = $Center/Menu/RulesButton
@onready var quit_button: Button = $Center/Menu/QuitButton
@onready var setup_dialog: ConfirmationDialog = $SetupDialog
@onready var player_count_option: OptionButton = $SetupDialog/SetupFields/PlayerCountOption
@onready var seed_input: LineEdit = $SetupDialog/SetupFields/SeedInput
@onready var rules_dialog: AcceptDialog = $RulesDialog


func _ready() -> void:
	start_button.pressed.connect(open_setup_dialog)
	rules_button.pressed.connect(open_rules_dialog)
	quit_button.pressed.connect(_quit_game)
	setup_dialog.confirmed.connect(_start_game)
	setup_dialog.canceled.connect(_focus_start_button)
	rules_dialog.confirmed.connect(_focus_rules_button)
	player_count_option.select(0)
	start_button.grab_focus()


func open_setup_dialog() -> void:
	rules_dialog.hide()
	setup_dialog.popup_centered(Vector2i(420, 240))
	player_count_option.grab_focus()


func open_rules_dialog() -> void:
	setup_dialog.hide()
	rules_dialog.popup_centered(Vector2i(720, 520))
	rules_dialog.get_ok_button().grab_focus()


func get_open_popup_count() -> int:
	return int(setup_dialog.visible) + int(rules_dialog.visible)


static func build_match_config(player_count: int, seed_text: String, fallback_seed: int = 0) -> Dictionary:
	var resolved_player_count := clampi(player_count, 2, 3)
	var normalized_seed := seed_text.strip_edges()
	var resolved_seed := fallback_seed
	if not normalized_seed.is_empty():
		resolved_seed = int(normalized_seed)
	elif resolved_seed == 0:
		var random := RandomNumberGenerator.new()
		random.randomize()
		resolved_seed = random.randi()
	return {"player_count": resolved_player_count, "seed": resolved_seed}


func _start_game() -> void:
	submit_setup(true)


func submit_setup(transition_to_game: bool = true) -> Dictionary:
	var player_count := player_count_option.get_item_id(player_count_option.selected)
	var config := build_match_config(player_count, seed_input.text)
	GameSession.set_match_config(config)
	match_config_created.emit(config)
	if transition_to_game:
		get_tree().change_scene_to_file(GAMEPLAY_SCENE)
	return config


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
