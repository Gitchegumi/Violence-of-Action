extends Node

signal color_changed(color: Color, player_id: int)
signal color_committed(color: Color, player_id: int)
signal selection_restored(player_id: int, was_selected: bool)

const STICK_DEADZONE := 0.2
const SATURATION_VALUE_SPEED := 0.75
const HUE_SPEED := 0.5
const PRECISE_STEP := 0.03

var _button: ColorPickerButton = null
var _player_id := -1
var _initial_color := Color.WHITE
var _initial_selected := false
var _left_stick := Vector2.ZERO
var _right_stick := Vector2.ZERO
var _accept_armed := true
var _opening_device := -1


func _ready() -> void:
	set_process(false)


func begin(
	button: ColorPickerButton,
	player_id: int,
	was_selected: bool,
	opening_device := -1,
) -> void:
	_button = button
	_player_id = player_id
	_initial_color = button.color
	_initial_selected = was_selected
	_left_stick = Vector2.ZERO
	_right_stick = Vector2.ZERO
	_accept_armed = opening_device < 0
	_opening_device = opening_device
	var popup := button.get_popup()
	if not popup.window_input.is_connected(_on_popup_input):
		popup.window_input.connect(_on_popup_input)
	if not popup.visible:
		popup.popup()
	set_process(true)


func is_active() -> bool:
	return _button != null


func _process(delta: float) -> void:
	if _button == null:
		return
	if not _button.get_popup().visible:
		_deactivate()
		return
	var saturation_value_delta := _deadzone_vector(_left_stick) \
		* SATURATION_VALUE_SPEED * delta
	var hue_delta := _deadzone_axis(_right_stick.x) * HUE_SPEED * delta
	if saturation_value_delta != Vector2.ZERO or not is_zero_approx(hue_delta):
		_adjust_color(saturation_value_delta, hue_delta)


func _on_popup_input(event: InputEvent) -> void:
	if _button == null:
		return
	var popup_viewport := _button.get_popup().get_viewport()
	if _handle_input_event(event):
		popup_viewport.set_input_as_handled()


func _handle_input_event(event: InputEvent) -> bool:
	if _button == null:
		return false
	if event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_LEFT_X:
				_left_stick.x = event.axis_value
			JOY_AXIS_LEFT_Y:
				_left_stick.y = event.axis_value
			JOY_AXIS_RIGHT_X:
				_right_stick.x = event.axis_value
			JOY_AXIS_RIGHT_Y:
				_right_stick.y = event.axis_value
			_:
				return false
		return true
	if not event is InputEventJoypadButton:
		return false
	if not _accept_armed and event.button_index == JOY_BUTTON_A \
			and event.device == _opening_device:
		if not event.pressed:
			_opening_device = -1
			_arm_accept.call_deferred()
		return true
	if not event.pressed:
		return false
	match event.button_index:
		JOY_BUTTON_A:
			_confirm()
		JOY_BUTTON_B:
			_cancel()
		JOY_BUTTON_DPAD_LEFT:
			_adjust_color(Vector2(-PRECISE_STEP, 0), 0.0)
		JOY_BUTTON_DPAD_RIGHT:
			_adjust_color(Vector2(PRECISE_STEP, 0), 0.0)
		JOY_BUTTON_DPAD_UP:
			_adjust_color(Vector2(0, -PRECISE_STEP), 0.0)
		JOY_BUTTON_DPAD_DOWN:
			_adjust_color(Vector2(0, PRECISE_STEP), 0.0)
		JOY_BUTTON_LEFT_SHOULDER:
			_adjust_color(Vector2.ZERO, -PRECISE_STEP)
		JOY_BUTTON_RIGHT_SHOULDER:
			_adjust_color(Vector2.ZERO, PRECISE_STEP)
		_:
			return false
	return true


func _arm_accept() -> void:
	if _button != null:
		_accept_armed = true


func _adjust_color(saturation_value_delta: Vector2, hue_delta: float) -> void:
	if _button == null:
		return
	var current := _button.color
	var next := Color.from_hsv(
		wrapf(current.h + hue_delta, 0.0, 1.0),
		clampf(current.s + saturation_value_delta.x, 0.0, 1.0),
		clampf(current.v - saturation_value_delta.y, 0.0, 1.0),
		1.0
	)
	_button.color = next
	_button.get_picker().color = next
	color_changed.emit(next, _player_id)


func _confirm() -> void:
	if _button == null:
		return
	var color := _button.color
	var player_id := _player_id
	_button.get_popup().hide()
	_deactivate()
	color_committed.emit(color, player_id)


func _cancel() -> void:
	if _button == null:
		return
	var button := _button
	var player_id := _player_id
	var was_selected := _initial_selected
	var initial_color := _initial_color
	button.get_popup().hide()
	_deactivate()
	_restore_cancelled_selection.call_deferred(button, initial_color, player_id, was_selected)


func _restore_cancelled_selection(
	button: ColorPickerButton,
	initial_color: Color,
	player_id: int,
	was_selected: bool,
) -> void:
	if not is_instance_valid(button):
		return
	var picker := button.get_picker()
	button.set_block_signals(true)
	picker.set_block_signals(true)
	button.color = initial_color
	picker.color = initial_color
	picker.set_block_signals(false)
	button.set_block_signals(false)
	selection_restored.emit(player_id, was_selected)


func _deactivate() -> void:
	_button = null
	_player_id = -1
	_left_stick = Vector2.ZERO
	_right_stick = Vector2.ZERO
	_accept_armed = true
	_opening_device = -1
	set_process(false)


func _deadzone_vector(value: Vector2) -> Vector2:
	return value if value.length() >= STICK_DEADZONE else Vector2.ZERO


func _deadzone_axis(value: float) -> float:
	return value if absf(value) >= STICK_DEADZONE else 0.0


func adjust_for_test(saturation_value_delta: Vector2, hue_delta: float) -> void:
	_adjust_color(saturation_value_delta, hue_delta)


func confirm_for_test() -> void:
	_confirm()


func cancel_for_test() -> void:
	_cancel()
