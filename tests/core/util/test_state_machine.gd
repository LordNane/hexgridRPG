extends GutTest


## Records every hook call into a log shared by all states in a test.
class RecordingState extends State:
	var label: String
	var calls: Array[String]
	var last_message: Dictionary = {}

	func _init(state_label: String, shared_calls: Array[String]) -> void:
		label = state_label
		calls = shared_calls

	func enter(message: Dictionary) -> void:
		last_message = message
		calls.append("enter " + label)

	func exit() -> void:
		calls.append("exit " + label)

	func handle_input(_event: InputEvent) -> void:
		calls.append("input " + label)

	func update(_delta: float) -> void:
		calls.append("update " + label)


var _calls: Array[String] = []
var _machine: StateMachine
var _moving: RecordingState


func before_each() -> void:
	_calls.clear()
	_moving = RecordingState.new("moving", _calls)
	_machine = StateMachine.new()
	_machine.add(&"idle", RecordingState.new("idle", _calls))
	_machine.add(&"moving", _moving)


func test_nothing_is_active_before_the_first_transition() -> void:
	assert_null(_machine.current())
	assert_eq(_machine.current_name, &"")
	_machine.update(0.1)
	assert_true(_calls.is_empty())


func test_transition_exits_the_old_state_and_enters_the_new_one() -> void:
	_machine.transition_to(&"idle")
	_machine.transition_to(&"moving", {"to": Vector2i(1, 0)})
	var expected: Array[String] = ["enter idle", "exit idle", "enter moving"]
	assert_eq(_calls, expected)
	assert_eq(_machine.current_name, &"moving")
	assert_eq(_moving.last_message, {"to": Vector2i(1, 0)})


func test_a_state_can_hand_over_by_itself() -> void:
	_machine.transition_to(&"idle")
	_machine.current().transition_to(&"moving")
	assert_eq(_machine.current_name, &"moving")
	assert_eq(_machine.current(), _moving)


func test_state_changed_reports_both_names() -> void:
	watch_signals(_machine)
	_machine.transition_to(&"idle")
	_machine.transition_to(&"moving")
	assert_signal_emitted_with_parameters(_machine, "state_changed", [&"idle", &"moving"])


func test_input_and_updates_go_only_to_the_active_state() -> void:
	_machine.transition_to(&"moving")
	_calls.clear()
	_machine.handle_input(InputEventKey.new())
	_machine.update(0.016)
	var expected: Array[String] = ["input moving", "update moving"]
	assert_eq(_calls, expected)
