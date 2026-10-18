class_name EquipScreen extends MenuScreen
## Changing one character's gear. Choose a slot, then an item from the inventory for it.
## Highlighting an item previews the stats it would give; gear the character can't use is dimmed,
## and highlighting or choosing it says why.

var _character: Character
var _session: GameSession
var _content: ContentRegistry
var _slots := MenuList.new()
var _items := MenuList.new()
var _stats := StatsPanel.new()
## Whether the items for [member _slot] are listed; otherwise a slot is being chosen.
var _choosing := false
var _slot := EquipmentDef.Slot.WEAPON


func _init(character: Character, session: GameSession, content: ContentRegistry) -> void:
	super()
	_character = character
	_session = session
	_content = content


func _ready() -> void:
	var row := _build_frame("Equip: %s" % _character.name)
	_add_column(row, "Gear", 190).add_child(_slots)
	_add_column(row, "Inventory", 170).add_child(_items)
	_add_column(row, "Stats").add_child(_stats)
	_slots.highlighted.connect(_on_slot_highlighted)
	_slots.chosen.connect(_on_slot_chosen)
	_items.highlighted.connect(_on_item_highlighted)
	_items.chosen.connect(_on_item_chosen)
	_fill_slots()
	_stats.show_stats(_character.stats())


func default_focus() -> Control:
	return _slots.first()


func cancel() -> void:
	if _choosing:
		_close_slot()
	else:
		super()


func _fill_slots() -> void:
	_slots.clear()
	for slot: EquipmentDef.Slot in EquipmentDef.slots():
		var item := _character.equipment.get_item(slot)
		_slots.add_option(EquipmentDef.slot_name(slot), slot, item.display_name if item else Describe.NOTHING)
	_slots.set_focusable(not _choosing)


func _on_slot_highlighted(value: Variant) -> void:
	var slot: EquipmentDef.Slot = value
	var item := _character.equipment.get_item(slot)
	show_hint(Describe.item(item) if item else "Nothing in the %s slot." % EquipmentDef.slot_name(slot))


## Lists what could go in the chosen slot: nothing (taking off what's there), then every item for it
## in the inventory, dimmed if the character can't use it.
func _on_slot_chosen(value: Variant) -> void:
	var slot: EquipmentDef.Slot = value
	_slot = slot
	_items.clear()
	if _character.equipment.get_item(slot):
		_items.add_option("Remove", null)
	var inventory := _session.inventory
	for item_id: StringName in inventory.item_ids():
		var item := _content.get_def(item_id) as EquipmentDef
		if item and item.slot == slot:
			var usable := EquipRules.can_equip(_character, item, slot).is_empty()
			_items.add_option(item.display_name, item, "×%d" % inventory.count_of(item_id), item.icon, not usable)
	if _items.is_empty():
		show_hint("Nothing the party carries goes in the %s slot." % EquipmentDef.slot_name(slot), true)
		return
	_choosing = true
	_slots.set_focusable(false)
	_items.first().grab_focus()


func _on_item_highlighted(value: Variant) -> void:
	var item := value as EquipmentDef
	var reason := EquipRules.can_equip(_character, item, _slot)
	# No preview for gear that can't go on, so the stats don't suggest it could.
	_stats.show_stats(_character.stats(), null if reason else _character.preview_equip(_slot, item))
	if item == null:
		show_hint("Take off the %s." % _character.equipment.get_item(_slot).display_name)
	else:
		show_hint(reason if reason else Describe.item(item), not reason.is_empty())


func _on_item_chosen(value: Variant) -> void:
	var before := _character.equipment.items()
	var item := value as EquipmentDef
	if item:
		var reason := _character.equip(_slot, item, _session.inventory)
		if reason:
			show_hint(reason, true)
			return
	else:
		_character.unequip(_slot, _session.inventory)
	_close_slot()
	show_hint(Describe.returned(_gear_taken_off(_character, before)))


func _close_slot() -> void:
	_choosing = false
	_items.clear()
	_fill_slots()
	_stats.show_stats(_character.stats())
	_slots.option_for(_slot).grab_focus()
