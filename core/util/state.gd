class_name State extends RefCounted
## One behavior in a [StateMachine], such as "choosing where to move".
## Override only the hooks you need, and call [method transition_to] to hand control to another state.

## Emitted by [method transition_to]. The owning [StateMachine] listens and switches states.
signal transition_requested(to: StringName, message: Dictionary)


## Called when this state becomes active. [param _message] carries data from the previous state.
func enter(_message: Dictionary) -> void:
	pass


## Called just before another state takes over.
func exit() -> void:
	pass


## Receives input forwarded by the machine's owner while this state is active.
func handle_input(_event: InputEvent) -> void:
	pass


## Receives frame updates forwarded by the machine's owner while this state is active.
func update(_delta: float) -> void:
	pass


## Asks the machine to switch to the state registered as [param to].
func transition_to(to: StringName, message: Dictionary = {}) -> void:
	transition_requested.emit(to, message)
