class_name EquipRules
## Who may wear what. Gear goes in its own slot; a character can use it when their job lists its
## equip_tag (or an equipped ability, such as Equip Swords, adds it); and a two-handed weapon leaves
## no hand free for a shield.


## Why [param character] can't wear [param item] in [param slot], as a sentence for the player, or
## an empty string if they can. Taking gear off ([param item] null) is always allowed.
static func can_equip(character: Character, item: EquipmentDef, slot: EquipmentDef.Slot) -> String:
	if item == null:
		return ""
	if item.slot != slot:
		return "The %s goes in the %s slot." % [item.display_name, EquipmentDef.slot_name(item.slot)]
	if not item.equip_tag.is_empty() and not character.equip_tags().has(item.equip_tag):
		return "%s can't use the %s as %s." % [character.name, item.display_name, English.with_article(character.job.display_name)]
	var weapon := character.equipment.weapon()
	if slot == EquipmentDef.Slot.SHIELD and weapon and weapon.two_handed:
		return "The %s takes both hands." % weapon.display_name
	return ""


## The other slots emptied when [param item] goes in [param slot]: a two-handed weapon takes the
## shield hand too.
static func displaced_slots(item: EquipmentDef, slot: EquipmentDef.Slot) -> Array[EquipmentDef.Slot]:
	var displaced: Array[EquipmentDef.Slot] = []
	var weapon := item as WeaponDef
	if slot == EquipmentDef.Slot.WEAPON and weapon and weapon.two_handed:
		displaced.append(EquipmentDef.Slot.SHIELD)
	return displaced

