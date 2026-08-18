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


func _ready() -> void:
	set_process(false)
	set_process_input(false)


func begin(button: ColorPickerButton, player_id: int, was_selected: bool) -> void:
	_button = button
	_player_id = player_id
	_initial_color = button.color
	_initial_selected = was_selected
	_left_stick = Vector2.ZERO
	_right_stick = Vector2.ZERO
	if not button.get_popup().visible:
		button.get_popup().popup()
	set_process(true)
	set_process_input(true)


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


func _input(event: InputEvent) -> void:
	if _button == null:
		return
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
				return
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventJoypadButton or not event.pressed:
		return
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
			return
	get_viewport().set_input_as_handled()


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
	var player_id := _player_id
	var was_selected := _initial_selected
	_button.color = _initial_color
	_button.get_picker().color = _initial_color
	_button.get_popup().hide()
	_deactivate()
	selection_restored.emit(player_id, was_selected)


func _deactivate() -> void:
	_button = null
	_player_id = -1
	_left_stick = Vector2.ZERO
	_right_stick = Vector2.ZERO
	set_process(false)
	set_process_input(false)


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
