class_name EquipmentDef extends ItemDef
## Gear worn in one of a character's equipment slots: armor, a shield or an accessory. Weapons are
## WeaponDefs. Who may wear it depends on their job; see EquipRules.

## Content files store a slot as its number, so add new slots at the end.
enum Slot { WEAPON, SHIELD, HEAD, BODY, ACCESSORY }

const SLOT_NAMES: Array[String] = ["Weapon", "Shield", "Head", "Body", "Accessory"]

@export var slot := Slot.BODY
## The kind of gear this is, such as &"sword", &"robe" or &"hat". Characters can wear it when their
## job, or an ability they have equipped, lists this tag. Leave it empty for gear anyone can wear.
@export var equip_tag: StringName
## Stat changes while it's worn.
@export var modifiers: Array[StatModifier] = []
## Traits the wearer gains, such as &"flying". Battles read them from Phase 6.
@export var granted_tags: Array[StringName] = []


## Every slot, in order.
static func slots() -> Array[Slot]:
	var all: Array[Slot] = []
	all.assign(Slot.values())
	return all


static func slot_name(of_slot: Slot) -> String:
	return SLOT_NAMES[of_slot]


## The slot's name in saves, such as "weapon". It stays the same if slots are added.
static func slot_key(of_slot: Slot) -> String:
	return String(Slot.keys()[of_slot]).to_lower()


## The slot saved as [param text] by [method slot_key], or -1 if there's no such slot.
static func slot_from_key(text: String) -> int:
	return Slot.get(text.to_upper(), -1)


func validate() -> PackedStringArray:
	var problems := super()
	if modifiers.has(null):
		problems.append("has an empty modifier slot")
	return problems
