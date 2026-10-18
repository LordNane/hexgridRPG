class_name StateMachine extends RefCounted
## Runs exactly one [State] at a time and switches when a state asks to.
## The owner forwards input and frame updates; states never reference each other directly.

## Emitted after a switch, before the new state's [method State.enter] runs.
signal state_changed(previous: StringName, current: StringName)

## The registered name of the active state, or an empty name before the first transition.
var current_name: StringName = &""

var _current: State
var _states: Dictionary[StringName, State] = {}


## Registers [param state] under [param state_name].
func add(state_name: StringName, state: State) -> void:
	_states[state_name] = state
	state.transition_requested.connect(transition_to)


## The active state, or null before the first transition.
func current() -> State:
	return _current


## Leaves the active state (if any) and enters the one registered as [param state_name].
func transition_to(state_name: StringName, message: Dictionary = {}) -> void:
	assert(_states.has(state_name), "Unknown state: %s" % state_name)
	var previous := current_name
	if _current:
		_current.exit()
	current_name = state_name
	_current = _states[state_name]
	state_changed.emit(previous, current_name)
	_current.enter(message)


## Forwards [param event] to the active state.
func handle_input(event: InputEvent) -> void:
	if _current:
		_current.handle_input(event)


## Forwards a frame update to the active state.
func update(delta: float) -> void:
	if _current:
		_current.update(delta)
