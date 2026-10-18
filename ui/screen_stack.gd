class_name ScreenStack extends CanvasLayer
## Menu screens shown one over another, such as the party, then one character, then their gear.
## Only the top screen is in the scene tree, so the ones below keep their state but take no input.
## Each new screen takes the keyboard and gamepad focus, and closing it puts the focus back where it
## was on the screen below. Cancel backs out one step; the menu button closes every screen.

## Emitted when the last screen closes.
signal closed

## Above the exploration HUD, below the ModeRouter's fades.
const DEFAULT_LAYER := 10
const THEME := preload("res://ui/theme/pixel_theme.tres")
## Dims whatever is behind the menu.
const BACKDROP_COLOR := Color(0, 0, 0, 0.45)
const NAVIGATION_ACTIONS: Array[StringName] = [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_accept"]

var _screens: Array[MenuScreen] = []
## For each screen with another over it: what had focus when that one opened.
var _focus_memory: Dictionary[MenuScreen, Control] = {}
var _root: ColorRect


func _init() -> void:
	layer = DEFAULT_LAYER
	_root = ColorRect.new()
	_root.name = "Screens"
	_root.color = BACKDROP_COLOR
	_root.theme = THEME
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.hide()
	add_child(_root)


func _notification(what: int) -> void:
	# Screens below the top aren't in the tree while they wait, so freeing the stack wouldn't free them.
	if what == NOTIFICATION_PREDELETE:
		for screen: MenuScreen in _screens:
			if is_instance_valid(screen) and screen.get_parent() == null:
				screen.free()


func is_open() -> bool:
	return not _screens.is_empty()


## The screen on top, or null when the menu is closed.
func top() -> MenuScreen:
	return null if _screens.is_empty() else _screens.back()


## How many screens are open.
func depth() -> int:
	return _screens.size()


## Opens [param screen] over the current one, which waits out of the tree until it closes.
func push(screen: MenuScreen) -> void:
	var below := top()
	if below:
		_focus_memory[below] = get_viewport().gui_get_focus_owner()
		_root.remove_child(below)
	_screens.append(screen)
	screen.stack = self
	_root.add_child(screen)
	_root.show()
	_focus(screen, null)


## Closes the top screen and brings back the one below, focused where it was.
func pop() -> void:
	assert(is_open(), "There's no screen to close.")
	var screen: MenuScreen = _screens.pop_back()
	_discard(screen)
	var below := top()
	if below == null:
		_root.hide()
		closed.emit()
		return
	_root.add_child(below)
	below.revealed()
	var remembered: Variant = _focus_memory.get(below)
	_focus_memory.erase(below)
	_focus(below, remembered)


## Closes every screen.
func close() -> void:
	for screen: MenuScreen in _screens:
		_discard(screen)
	_screens.clear()
	_focus_memory.clear()
	_root.hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	# Handled before the GUI sees it, so a focused button can't swallow it (Tab moves focus otherwise).
	if not is_open():
		return
	if event.is_action_pressed(&"menu"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed(&"cancel"):
		get_viewport().set_input_as_handled()
		top().cancel()


func _unhandled_input(event: InputEvent) -> void:
	# A click on empty space drops the focus; the next key or button press brings it back.
	if not is_open() or get_viewport().gui_get_focus_owner() != null:
		return
	for action: StringName in NAVIGATION_ACTIONS:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			_focus(top(), null)
			return


## Focuses [param remembered] if it's still on [param screen] and can take focus, or else the
## screen's default.
func _focus(screen: MenuScreen, remembered: Variant) -> void:
	var target := screen.default_focus()
	if is_instance_valid(remembered):
		var control := remembered as Control
		if screen.is_ancestor_of(control) and control.is_visible_in_tree() and control.focus_mode != Control.FOCUS_NONE:
			target = control
	if target:
		target.grab_focus()


func _discard(screen: MenuScreen) -> void:
	if screen.get_parent() == _root:
		_root.remove_child(screen)
	screen.queue_free()
