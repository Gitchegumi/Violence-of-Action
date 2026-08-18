extends GutTest

var KeyboardScript = preload("res://scripts/ui/controller_keyboard.gd")
var keyboard = null
var target: LineEdit = null


func before_each() -> void:
	keyboard = KeyboardScript.new()
	add_child_autofree(keyboard)
	target = LineEdit.new()
	add_child_autofree(target)


func test_qwerty_keyboard_commits_letters_digits_and_space() -> void:
	keyboard.open_for(target)
	keyboard.press_key_for_test("A")
	keyboard.press_key_for_test("Space")
	keyboard.press_key_for_test("1")
	keyboard.confirm_for_test()
	assert_eq(target.text, "A 1")


func test_shift_and_backspace_edit_preview_before_commit() -> void:
	keyboard.open_for(target)
	keyboard.press_key_for_test("Shift")
	keyboard.press_key_for_test("Q")
	keyboard.press_key_for_test("W")
	keyboard.press_key_for_test("Backspace")
	keyboard.confirm_for_test()
	assert_eq(target.text, "q")


func test_cancel_preserves_original_name() -> void:
	target.text = "Original"
	keyboard.open_for(target)
	keyboard.press_key_for_test("Clear")
	keyboard.cancel_for_test()
	assert_eq(target.text, "Original")
