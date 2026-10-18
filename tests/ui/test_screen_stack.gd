extends GutTest


## A screen with two buttons that counts how often it's revealed.
class TwoButtonScreen extends MenuScreen:
	var buttons: Array[Button] = []
	var reveals := 0

	func _init() -> void:
		super()
		for i: int in 2:
			var button := Button.new()
			button.text = str(i)
			add_child(button)
			buttons.append(button)

	func revealed() -> void:
		reveals += 1


var _stack: ScreenStack


func before_each() -> void:
	_stack = ScreenStack.new()
	add_child_autofree(_stack)


func after_each() -> void:
	await wait_process_frames(1, "let closed screens be deleted")


func test_only_the_top_screen_is_in_the_tree_and_it_takes_the_focus() -> void:
	var first := TwoButtonScreen.new()
	_stack.push(first)
	assert_true(_stack.is_open())
	assert_true(first.buttons[0].has_focus())
	var second := TwoButtonScreen.new()
	_stack.push(second)
	assert_false(first.is_inside_tree())
	assert_true(second.buttons[0].has_focus())
	assert_same(_stack.top(), second)


func test_closing_a_screen_puts_the_focus_back_where_it_was() -> void:
	var first := TwoButtonScreen.new()
	_stack.push(first)
	first.buttons[1].grab_focus()
	_stack.push(TwoButtonScreen.new())
	_stack.pop()
	assert_true(first.is_inside_tree())
	assert_eq(first.reveals, 1)
	assert_true(first.buttons[1].has_focus())


func test_cancel_backs_out_one_screen_and_the_menu_button_closes_them_all() -> void:
	watch_signals(_stack)
	_stack.push(TwoButtonScreen.new())
	_stack.push(TwoButtonScreen.new())
	_stack.push(TwoButtonScreen.new())
	_press(&"cancel")
	assert_eq(_stack.depth(), 2)
	assert_signal_not_emitted(_stack, "closed")
	_press(&"menu")
	assert_false(_stack.is_open())
	assert_signal_emit_count(_stack, "closed", 1)


func test_closing_the_last_screen_reports_it() -> void:
	watch_signals(_stack)
	_stack.push(TwoButtonScreen.new())
	_stack.pop()
	assert_false(_stack.is_open())
	assert_signal_emitted(_stack, "closed")


func test_a_lost_focus_comes_back_with_the_next_direction_pressed() -> void:
	var screen := TwoButtonScreen.new()
	_stack.push(screen)
	screen.buttons[0].release_focus()
	_press(&"ui_down")
	assert_true(screen.buttons[0].has_focus())


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_stack.get_viewport().push_input(event)
