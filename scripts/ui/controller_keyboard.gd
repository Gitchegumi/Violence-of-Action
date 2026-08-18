extends ConfirmationDialog

const KEY_ROWS: Array[Array] = [
	["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "'"],
	["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
	["A", "S", "D", "F", "G", "H", "J", "K", "L"],
	["Z", "X", "C", "V", "B", "N", "M"],
]

var target_input: LineEdit = null
var _preview: LineEdit = null
var _letter_buttons: Dictionary = {}
var _first_button: Button = null
var _uppercase := true


func _ready() -> void:
	title = "Enter Player Name"
	ok_button_text = "Done"
	exclusive = false
	dialog_hide_on_ok = false
	confirmed.connect(_commit)
	canceled.connect(_cancel)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(720, 330)
	content.add_theme_constant_override("separation", 10)
	add_child(content)

	_preview = LineEdit.new()
	_preview.editable = false
	_preview.focus_mode = Control.FOCUS_NONE
	content.add_child(_preview)

	for row: Array in KEY_ROWS:
		var row_container := HBoxContainer.new()
		row_container.alignment = BoxContainer.ALIGNMENT_CENTER
		row_container.add_theme_constant_override("separation", 6)
		content.add_child(row_container)
		for key: String in row:
			var button := _create_key_button(key, key)
			row_container.add_child(button)
			if key.length() == 1 and key >= "A" and key <= "Z":
				_letter_buttons[key] = button

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 8)
	content.add_child(controls)
	for control_key in ["Shift", "Space", "Backspace", "Clear"]:
		var button := _create_key_button(control_key, control_key)
		if control_key == "Space":
			button.custom_minimum_size.x = 240.0
		controls.add_child(button)


func _create_key_button(label: String, key: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(48, 42)
	button.pressed.connect(_press_key.bind(key))
	if _first_button == null:
		_first_button = button
	return button


func open_for(input: LineEdit) -> void:
	target_input = input
	_preview.text = input.text
	_uppercase = true
	_update_letter_labels()
	popup_centered(Vector2i(760, 430))
	if _first_button != null:
		_first_button.grab_focus.call_deferred()


func _press_key(key: String) -> void:
	match key:
		"Shift":
			_uppercase = not _uppercase
			_update_letter_labels()
		"Space":
			_append_text(" ")
		"Backspace":
			if not _preview.text.is_empty():
				_preview.text = _preview.text.left(_preview.text.length() - 1)
		"Clear":
			_preview.text = ""
		_:
			_append_text(key if _uppercase else key.to_lower())


func _append_text(value: String) -> void:
	if target_input != null and target_input.max_length > 0 \
			and _preview.text.length() + value.length() > target_input.max_length:
		return
	_preview.text += value


func _update_letter_labels() -> void:
	for key: String in _letter_buttons:
		var button: Button = _letter_buttons[key]
		button.text = key if _uppercase else key.to_lower()


func _commit() -> void:
	if target_input != null:
		target_input.text = _preview.text
		var input := target_input
		target_input = null
		hide()
		input.grab_focus.call_deferred()


func _cancel() -> void:
	var input := target_input
	target_input = null
	hide()
	if input != null:
		input.grab_focus.call_deferred()


func press_key_for_test(key: String) -> void:
	_press_key(key)


func confirm_for_test() -> void:
	_commit()


func cancel_for_test() -> void:
	_cancel()
