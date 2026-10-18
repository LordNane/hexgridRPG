class_name MenuScreen extends Control
## One screen of a menu, shown by a ScreenStack. Screens build their controls in code when they
## first enter the tree, inside the window [method _build_frame] makes, and change the game only
## through model methods such as Character.equip. Their look comes from the theme.

## The stack showing this screen; set when it's pushed.
var stack: ScreenStack

var _hint: Label


func _init() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE


## The control to focus when the screen opens: by default, the first one that can take focus.
func default_focus() -> Control:
	return _first_focusable(self)


## Backs out one step. By default that closes the screen; screens with steps of their own, such as
## choosing a slot and then an item, step back first.
func cancel() -> void:
	stack.pop()


## Called when the screen is on top again because the one over it closed. Refresh anything the
## other screen may have changed.
func revealed() -> void:
	pass


## Shows [param text] on the hint line at the bottom, in the warning color if [param warning].
func show_hint(text: String, warning: bool = false) -> void:
	_hint.text = text
	_hint.theme_type_variation = &"WarningLabel" if warning else &"DimLabel"


## What the hint line says.
func hint() -> String:
	return _hint.text


## Builds the window every screen shares: [param title] at the top, the hint line at the bottom,
## and between them a row for the screen's columns, which it returns.
func _build_frame(title: String) -> HBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	add_child(margin)
	var window := PanelContainer.new()
	margin.add_child(window)
	var rows := VBoxContainer.new()
	window.add_child(rows)
	var heading := Label.new()
	heading.text = title
	heading.theme_type_variation = &"HeaderLabel"
	rows.add_child(heading)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 6)
	rows.add_child(columns)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size.y = 26
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.theme_type_variation = &"DimLabel"
	rows.add_child(_hint)
	return columns


## Adds a framed column to [param row], [param width] pixels wide or, at 0, sharing the leftover
## space. [param heading] labels it if given. Returns the box to fill.
func _add_column(row: HBoxContainer, heading: String, width: int = 0) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"InsetPanel"
	panel.custom_minimum_size.x = width
	panel.size_flags_horizontal = SIZE_EXPAND_FILL if width == 0 else SIZE_FILL
	row.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	if heading:
		box.add_child(make_label(heading, &"DimLabel"))
	return box


## The pieces in [param before] that [param character] no longer wears, to say what a change took off.
static func _gear_taken_off(character: Character, before: Array[EquipmentDef]) -> Array[EquipmentDef]:
	var worn := character.equipment.items()
	var taken_off: Array[EquipmentDef] = []
	for item: EquipmentDef in before:
		if not worn.has(item):
			taken_off.append(item)
	return taken_off


## A label showing [param text] in the theme style [param variation], wrapping if [param wrapped].
static func make_label(text: String, variation: StringName = &"", wrapped: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	if wrapped:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func _first_focusable(node: Node) -> Control:
	for child: Node in node.get_children():
		var control := child as Control
		if control and control.focus_mode != FOCUS_NONE and control.is_visible_in_tree():
			return control
		var found := _first_focusable(child)
		if found:
			return found
	return null
