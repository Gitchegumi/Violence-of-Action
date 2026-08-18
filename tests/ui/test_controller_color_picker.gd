extends GutTest

var ControllerColorPickerScript = preload("res://scripts/ui/controller_color_picker.gd")
var controller = null
var button: ColorPickerButton = null


func before_each() -> void:
	controller = ControllerColorPickerScript.new()
	add_child_autofree(controller)
	button = ColorPickerButton.new()
	button.color = Color.from_hsv(0.2, 0.4, 0.6)
	add_child_autofree(button)


func test_controller_adjusts_full_picker_hsv_channels() -> void:
	controller.begin(button, 0, true)
	controller.adjust_for_test(Vector2(0.2, -0.1), 0.15)
	assert_almost_eq(button.color.s, 0.6, 0.001)
	assert_almost_eq(button.color.v, 0.7, 0.001)
	assert_almost_eq(button.color.h, 0.35, 0.001)
	assert_eq(button.get_picker().color, button.color)


func test_cancel_restores_original_color_and_selection_state() -> void:
	var original := button.color
	watch_signals(controller)
	controller.begin(button, 2, false)
	controller.adjust_for_test(Vector2(0.2, -0.1), 0.15)
	controller.cancel_for_test()
	assert_eq(button.color, original)
	assert_signal_emitted_with_parameters(controller, "selection_restored", [2, false])


func test_confirm_keeps_adjusted_color() -> void:
	watch_signals(controller)
	controller.begin(button, 1, false)
	controller.adjust_for_test(Vector2(0.1, 0.0), 0.0)
	var adjusted := button.color
	controller.confirm_for_test()
	assert_eq(button.color, adjusted)
	assert_signal_emitted_with_parameters(controller, "color_committed", [adjusted, 1])
