class_name ModeRouter extends Node
## The stack of game modes, such as the title screen, exploring a map or a battle. Only the top mode
## is in the scene tree. The ones below stay alive out of the tree, so they're hidden, paused and
## deaf to input until everything above them pops. Changes fade through black, and input is
## ignored while one plays.
##
## [method push] returns once the pushed mode pops, with the result it popped with, so a POI script
## can await a cave or a battle and carry on afterwards.

## Emitted after each change, once [param top] is fully shown.
signal changed(top: Node)

## Above everything a mode draws.
const FADE_LAYER := 100

## Seconds to fade out, and again to fade back in. At 0, modes swap at once.
@export var fade_seconds := 0.25


## One mode on the stack, and the result it popped with.
class _Entry:
	signal popped

	var mode: Node
	var has_popped := false
	var result: Variant

	func _init(stacked: Node) -> void:
		mode = stacked


var _stack: Array[_Entry] = []
var _changing := false
var _curtain: ColorRect


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = FADE_LAYER
	add_child(layer)
	_curtain = ColorRect.new()
	# Start covered, so the first mode fades in.
	_curtain.color = Color.BLACK
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_curtain)


func _notification(what: int) -> void:
	# Modes below the top aren't children while they wait, so freeing the router wouldn't free them.
	if what == NOTIFICATION_PREDELETE:
		for entry: _Entry in _stack:
			if is_instance_valid(entry.mode) and entry.mode.get_parent() == null:
				entry.mode.free()


func _input(_event: InputEvent) -> void:
	if _changing:
		get_viewport().set_input_as_handled()


## The mode on top, or null when there are none.
func top() -> Node:
	return null if _stack.is_empty() else _stack.back().mode


## How many modes are stacked.
func depth() -> int:
	return _stack.size()


## Whether a change is fading out or in.
func is_changing() -> bool:
	return _changing


## Puts [param mode] on top and takes the one below out of the tree until [param mode] pops. Returns
## once it pops, with the result given to [method pop].
func push(mode: Node) -> Variant:
	var entry := _Entry.new(mode)
	await _cover()
	if not _stack.is_empty():
		remove_child(top())
	_stack.append(entry)
	add_child(mode)
	await _uncover()
	if not entry.has_popped:
		await entry.popped
	return entry.result


## Frees the top mode and brings back the one below. The [method push] that added the popped mode
## then returns [param result].
func pop(result: Variant = null) -> void:
	await _cover()
	assert(_stack.size() > 1, "Only modes pushed over another can pop; use switch_to to replace the last one.")
	var entry: _Entry = _stack.pop_back()
	_discard(entry.mode)
	add_child(top())
	await _uncover()
	entry.has_popped = true
	entry.result = result
	entry.popped.emit()


## Frees every mode and stacks [param modes] instead, bottom first. Only the last joins the tree now;
## each one below joins when the modes above it pop. Pushes of the freed modes never return.
func switch_to(modes: Array[Node]) -> void:
	assert(not modes.is_empty(), "Switch to at least one mode.")
	await _cover()
	for entry: _Entry in _stack:
		_discard(entry.mode)
	_stack.clear()
	for mode: Node in modes:
		_stack.append(_Entry.new(mode))
	add_child(modes.back())
	await _uncover()


## Waits for any change in progress to finish, then fades the screen out.
func _cover() -> void:
	while _changing:
		await changed
	_changing = true
	await _fade_to(1.0)


func _uncover() -> void:
	await _fade_to(0.0)
	_changing = false
	changed.emit(top())


func _fade_to(alpha: float) -> void:
	if fade_seconds <= 0.0 or is_equal_approx(_curtain.color.a, alpha):
		_curtain.color.a = alpha
		return
	var tween := create_tween()
	tween.tween_property(_curtain, "color:a", alpha, fade_seconds)
	await tween.finished


func _discard(mode: Node) -> void:
	if mode.get_parent() == self:
		remove_child(mode)
	mode.queue_free()
