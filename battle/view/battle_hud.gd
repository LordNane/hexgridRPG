class_name BattleHud extends CanvasLayer
## The battle screen's overlay: the coming turns, cards for the unit whose turn it is and the unit
## under the cursor, the command menu, a hint line, announcements and the result at the end.

## Emitted when a command is chosen from the menu, with the value it stands for.
signal command_chosen(value: Variant)

const THEME := preload("res://ui/theme/pixel_theme.tres")
## How many coming turns the turn order shows.
const TURNS_SHOWN := 8
const BANNER_SECONDS := 1.2

var _root := Control.new()
var _turns := HBoxContainer.new()
var _active_card := UnitCard.new()
var _target_card := UnitCard.new()
var _commands := MenuList.new()
var _command_panel := PanelContainer.new()
var _hint := MenuScreen.make_label("", &"DimLabel")
var _banner := MenuScreen.make_label("", &"HeaderLabel")


func _init() -> void:
	layer = 5
	_root.theme = THEME
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# Turn order along the top, commands at the right, cards in the bottom corners with the hint
	# between them. Only the command menu takes the mouse; clicks elsewhere reach the map.
	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		frame.add_theme_constant_override("margin_" + side, 6)
	_root.add_child(frame)
	var rows := VBoxContainer.new()
	frame.add_child(rows)
	var top := HBoxContainer.new()
	rows.add_child(top)
	var order := PanelContainer.new()
	order.theme_type_variation = &"InsetPanel"
	_turns.add_theme_constant_override("separation", 2)
	order.add_child(_turns)
	top.add_child(order)
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.alignment = BoxContainer.ALIGNMENT_END
	rows.add_child(middle)
	_command_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_command_panel.custom_minimum_size = Vector2(96, 0)
	_commands.custom_minimum_size = Vector2(0, 40)
	_command_panel.add_child(_commands)
	_command_panel.hide()
	middle.add_child(_command_panel)
	_commands.chosen.connect(command_chosen.emit)
	var bottom := HBoxContainer.new()
	rows.add_child(bottom)
	bottom.add_child(_active_card)
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.size_flags_vertical = Control.SIZE_SHRINK_END
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(_hint)
	bottom.add_child(_target_card)
	for node: Node in [frame, rows, top, order, middle, bottom, _hint]:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner.position.y += 40
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	_root.add_child(_banner)


## Shows the coming turns, the current one first.
func show_turn_order(units: Array[BattleUnit]) -> void:
	for child: Node in _turns.get_children():
		_turns.remove_child(child)
		child.queue_free()
	for unit: BattleUnit in units.slice(0, TURNS_SHOWN):
		var slot := VBoxContainer.new()
		slot.add_theme_constant_override("separation", 1)
		var face := TextureRect.new()
		face.texture = unit.character.job.sprite
		face.modulate = UnitView.ENEMY_TINT if unit.team == BattleUnit.Team.ENEMY else Color.WHITE
		face.flip_h = unit.team == BattleUnit.Team.ENEMY
		slot.add_child(face)
		var side := ColorRect.new()
		side.color = UnitView.PARTY_COLOR if unit.team == BattleUnit.Team.PARTY else UnitView.ENEMY_COLOR
		side.custom_minimum_size = Vector2(16, 2)
		slot.add_child(side)
		_turns.add_child(slot)


## Shows [param unit] on the card for the unit whose turn it is.
func show_active(unit: BattleUnit) -> void:
	_active_card.show_unit(unit)


## Shows [param unit] on the second card, or hides it when null.
func show_target(unit: BattleUnit) -> void:
	_target_card.show_unit(unit)


## Redraws both cards, after HP or MP changed.
func refresh_cards() -> void:
	_active_card.refresh()
	_target_card.refresh()


## Opens the command menu with [param options], each [code][text, value, available][/code], and
## focuses its first available option.
func show_commands(options: Array[Array]) -> void:
	_commands.clear()
	var first: Button = null
	for option: Array in options:
		var button := _commands.add_option(option[0], option[1], "", null, not option[2])
		if first == null and option[2]:
			first = button
	_command_panel.show()
	(first if first else _commands.first()).grab_focus()


func hide_commands() -> void:
	_command_panel.hide()
	var focused := _root.get_viewport().gui_get_focus_owner() if _root.is_inside_tree() else null
	if focused:
		focused.release_focus()


func show_hint(text: String) -> void:
	_hint.text = text


## Shows [param text] large at the top of the screen for a moment; returns once it has faded.
func announce(text: String, instant: bool = false) -> void:
	_banner.text = text
	if instant:
		return
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.2)
	tween.tween_interval(BANNER_SECONDS)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.3)
	await tween.finished


## Shows how the battle ended and what was won, and returns once the player confirms.
func show_result(result: BattleResult, content: ContentRegistry, instant: bool = false) -> void:
	hide_commands()
	show_active(null)
	show_target(null)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(200, 0)
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	var title := MenuScreen.make_label("Victory!" if result.is_victory() else "Defeat...", &"HeaderLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(title)
	if result.is_victory():
		var lines := PackedStringArray()
		if result.gold > 0:
			lines.append("%d gold" % result.gold)
		for item_id: StringName in result.items:
			var item := content.get_def(item_id)
			lines.append("%s ×%d" % [item.display_name if item else String(item_id), result.items[item_id]])
		rows.add_child(MenuScreen.make_label("Found " + ", ".join(lines) + "." if not lines.is_empty() else "Nothing to collect.", &"", true))
	else:
		rows.add_child(MenuScreen.make_label("The party has fallen.", &"DimLabel"))
	var buttons := MenuList.new()
	buttons.custom_minimum_size = Vector2(0, 14)
	var button := buttons.add_option("Continue" if result.is_victory() else "Return to title", null)
	rows.add_child(buttons)
	_root.add_child(panel)
	if instant:
		return
	button.grab_focus()
	await buttons.chosen
