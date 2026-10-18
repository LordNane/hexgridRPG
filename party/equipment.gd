class_name Equipment extends RefCounted
## The gear a character wears, one piece per slot. Only a record: Character checks EquipRules and
## moves gear to and from the inventory.

var _items: Dictionary[EquipmentDef.Slot, EquipmentDef] = {}


## What's worn in [param slot], or null.
func get_item(slot: EquipmentDef.Slot) -> EquipmentDef:
	return _items.get(slot)


## Puts [param item] in [param slot], or empties it when null. Returns what was there.
func set_item(slot: EquipmentDef.Slot, item: EquipmentDef) -> EquipmentDef:
	var previous := get_item(slot)
	if item:
		_items[slot] = item
	else:
		_items.erase(slot)
	return previous


func weapon() -> WeaponDef:
	return get_item(EquipmentDef.Slot.WEAPON) as WeaponDef


## Every piece worn, in slot order.
func items() -> Array[EquipmentDef]:
	var worn: Array[EquipmentDef] = []
	for slot: EquipmentDef.Slot in EquipmentDef.slots():
		if _items.has(slot):
			worn.append(_items[slot])
	return worn


## The stat modifiers of every piece worn.
func modifiers() -> Array[StatModifier]:
	var found: Array[StatModifier] = []
	for item: EquipmentDef in items():
		found.append_array(item.modifiers)
	return found


## The traits every piece worn grants, each listed once.
func granted_tags() -> Array[StringName]:
	var found: Array[StringName] = []
	for item: EquipmentDef in items():
		for tag: StringName in item.granted_tags:
			if not found.has(tag):
				found.append(tag)
	return found


func duplicate() -> Equipment:
	var copy := Equipment.new()
	copy._items = _items.duplicate()
	return copy


func to_dict() -> Dictionary:
	var data := {}
	for slot: EquipmentDef.Slot in EquipmentDef.slots():
		if _items.has(slot):
			data[EquipmentDef.slot_key(slot)] = String(_items[slot].id)
	return data


## Gear [param content] doesn't have any more is dropped with a warning.
static func from_dict(data: Dictionary, content: ContentRegistry) -> Equipment:
	var equipment := Equipment.new()
	for key: Variant in data:
		var slot := EquipmentDef.slot_from_key(str(key))
		var item := content.get_def(StringName(data[key])) as EquipmentDef
		if slot >= 0 and item:
			equipment._items[slot] = item
		else:
			push_warning("A save has \"%s\" in a \"%s\" slot, but there's no such gear or slot." % [data[key], key])
	return equipment
