class_name MenuList extends ScrollContainer
## A scrolling column of options for the keyboard, a gamepad or the mouse. Each option stands for a
## value, such as a character or an item; the list reports which value is highlighted (focused or
## hovered) and which is chosen.

signal highlighted(value: Variant)
signal chosen(value: Variant)

var _box := VBoxContainer.new()


func _init() -> void:
	horizontal_scroll_mode = SCROLL_MODE_DISABLED
	follow_focus = true
	size_flags_vertical = SIZE_EXPAND_FILL
	_box.size_flags_horizontal = SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 0)
	add_child(_box)


## Adds an option showing [param text] that stands for [param value] (null is fine, as for "None"),
## with [param detail] on the right and [param icon] on the left. A [param dim] option looks
## unavailable but can still be highlighted and chosen, so the screen can say why.
func add_option(text: String, value: Variant, detail: String = "", icon: Texture2D = null, dim: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.icon = icon
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.theme_type_variation = &"DimButton" if dim else &""
	button.set_meta(&"value", value)
	if detail:
		var label := Label.new()
		label.text = detail
		label.theme_type_variation = &"DimLabel"
		label.mouse_filter = MOUSE_FILTER_IGNORE
		label.set_anchors_and_offsets_preset(PRESET_RIGHT_WIDE)
		label.offset_right = -4
		label.offset_left = -4
		label.grow_horizontal = GROW_DIRECTION_BEGIN
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_child(label)
	button.focus_entered.connect(highlighted.emit.bind(value))
	button.mouse_entered.connect(func() -> void:
		if button.focus_mode != FOCUS_NONE:
			button.grab_focus())
	button.pressed.connect(chosen.emit.bind(value))
	_box.add_child(button)
	return button


## Adds a heading between options, such as "Weapons". It can't be highlighted.
func add_heading(text: String) -> void:
	_box.add_child(MenuScreen.make_label(text, &"DimLabel"))


## Removes every option and heading.
func clear() -> void:
	for child: Node in _box.get_children():
		_box.remove_child(child)
		child.queue_free()


func options() -> Array[Button]:
	var found: Array[Button] = []
	for child: Node in _box.get_children():
		if child is Button:
			found.append(child)
	return found


func is_empty() -> bool:
	return options().is_empty()


## The first option, or null.
func first() -> Button:
	var all := options()
	return null if all.is_empty() else all[0]


## The option standing for [param value], or null.
func option_for(value: Variant) -> Button:
	for button: Button in options():
		# A null value isn't stored: set_meta with null removes the entry.
		var option_value: Variant = button.get_meta(&"value") if button.has_meta(&"value") else null
		if typeof(option_value) == typeof(value) and option_value == value:
			return button
	return null


## Whether the keyboard and gamepad can move onto the options. Off, they can still be clicked.
func set_focusable(focusable: bool) -> void:
	for button: Button in options():
		button.focus_mode = FOCUS_ALL if focusable else FOCUS_NONE
