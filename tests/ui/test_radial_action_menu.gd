extends GutTest

# Action-mode radial: occupied tiles open a menu of unit actions instead of
# deployable units (Attack / Move / Upgrade / Inspect).

var RadialScene = preload("res://scenes/ui/radial_menu.tscn")
var menu = null

func _actions() -> Array:
	return [
		{"action_id": "attack", "label": "Attack", "enabled": true},
		{"action_id": "move", "label": "Move", "enabled": true},
		{"action_id": "upgrade", "label": "Upgrade", "enabled": false},
		{"action_id": "inspect", "label": "Inspect", "enabled": true},
	]

func before_each():
	menu = RadialScene.instantiate()
	menu.size = Vector2(400, 400)
	add_child_autofree(menu)

func test_open_actions_enters_action_mode_with_items():
	menu.open_actions(Vector2i(1, 1), _actions())
	assert_true(menu.is_action_mode(), "open_actions enters action mode")
	assert_eq(menu.visible_units.size(), 4, "all actions become items")
	assert_eq(menu.unit_icons.size(), 4, "an icon per action")

func test_open_resets_to_deploy_mode():
	menu.open_actions(Vector2i(1, 1), _actions())
	menu.open(Vector2i(2, 2), [])
	assert_false(menu.is_action_mode(), "open() returns to deploy mode")

func test_action_confirm_emits_action_selected():
	menu.open_actions(Vector2i(1, 1), _actions())
	watch_signals(menu)
	menu.focus_index = 0  # attack
	menu._confirm_item(menu.get_focused_unit())
	assert_signal_emitted_with_parameters(menu, "deploy_action_selected",
		["attack", Vector2i(1, 1)])

func test_disabled_action_is_not_selectable():
	menu.open_actions(Vector2i(1, 1), _actions())
	watch_signals(menu)
	menu.focus_index = 2  # upgrade (disabled)
	menu._confirm_item(menu.get_focused_unit())
	assert_signal_not_emitted(menu, "deploy_action_selected",
		"disabled action emits nothing")

func test_action_mode_does_not_attempt_placement():
	menu.open_actions(Vector2i(1, 1), _actions())
	watch_signals(menu)
	menu.focus_index = 0
	menu._confirm_item(menu.get_focused_unit())
	assert_signal_not_emitted(menu, "deploy_unit_selected",
		"action mode never emits unit placement")

func test_initial_focus_lands_on_first_enabled_action():
	# Disable the first action; focus should skip to the next enabled one.
	var acts = _actions()
	acts[0]["enabled"] = false
	menu.open_actions(Vector2i(1, 1), acts)
	assert_true(menu.get_focused_unit().get("enabled", false),
		"initial focus is on an enabled action")

func test_mouse_exit_does_not_emit_unhovered_in_action_mode():
	menu.open_actions(Vector2i(1, 1), _actions())
	watch_signals(menu)
	menu._on_icon_unhovered()
	assert_signal_not_emitted(menu, "deploy_unit_unhovered",
		"action mode has no hover preview to clear")
