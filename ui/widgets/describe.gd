class_name Describe
## Sentences about content for menus: what an item or ability does, in the player's words.

## "—", shown for an empty slot.
const NOTHING := "—"


## What [param modifiers] do, such as "Attack +5, Speed +1".
static func modifiers(list: Array[StatModifier]) -> String:
	var parts := PackedStringArray()
	for modifier: StatModifier in list:
		parts.append(modifier.describe())
	return ", ".join(parts)


## [param item]'s description followed by what it does when worn.
static func item(of_item: ItemDef) -> String:
	var parts := PackedStringArray([of_item.description])
	var gear := of_item as EquipmentDef
	if gear:
		var effects := modifiers(gear.modifiers)
		if effects:
			parts.append(effects + ".")
		if gear is WeaponDef and (gear as WeaponDef).two_handed:
			parts.append("Takes both hands.")
	return " ".join(parts).strip_edges()


## What kind of item [param of_item] is, such as "Weapon (sword)" or "Accessory".
static func item_kind(of_item: ItemDef) -> String:
	var gear := of_item as EquipmentDef
	if gear:
		var slot := EquipmentDef.slot_name(gear.slot)
		return "%s (%s)" % [slot, gear.equip_tag] if gear.equip_tag else slot
	return "Consumable" if of_item is ConsumableDef else "Item"


## [param ability]'s description followed by its cost or what it does when equipped.
static func ability(of_ability: AbilityDef) -> String:
	var parts := PackedStringArray([of_ability.description])
	if of_ability.mp_cost > 0:
		parts.append("%d MP." % of_ability.mp_cost)
	var effects := modifiers(of_ability.modifiers)
	if effects:
		parts.append(effects + ".")
	return " ".join(parts).strip_edges()


## A list of [param actions] with their MP costs, one per line, for a command.
static func command(actions: Array[AbilityDef]) -> String:
	if actions.is_empty():
		return "Nothing learned yet."
	var lines := PackedStringArray()
	for action: AbilityDef in actions:
		lines.append(action.display_name + ("  %d MP" % action.mp_cost if action.mp_cost > 0 else ""))
	return "\n".join(lines)


## The names of [param items] as a list: "Bronze Sword and Buckler".
static func names(items: Array[EquipmentDef]) -> String:
	var found := PackedStringArray()
	for gear: EquipmentDef in items:
		found.append(gear.display_name)
	return English.list(found)


## A sentence saying [param items] went back to the inventory, or "" if there are none.
static func returned(items: Array[EquipmentDef]) -> String:
	return "" if items.is_empty() else "The %s went back to the inventory." % names(items)
