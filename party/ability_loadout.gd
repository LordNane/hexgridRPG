class_name AbilityLoadout extends RefCounted
## The abilities a character takes into battle, as in FF Tactics: their job's command (not stored
## here: it's always the current job's), a secondary command borrowed from another job, and one
## reaction, one support and one movement ability. Only a record: Character checks the rules.

## The slots for equipped abilities. Each holds an ability of that kind.
const SLOTS: Array[AbilityDef.Kind] = [AbilityDef.Kind.REACTION, AbilityDef.Kind.SUPPORT, AbilityDef.Kind.MOVEMENT]

## The job whose learned actions make up the secondary command, or null.
var secondary: JobDef

var _equipped: Dictionary[AbilityDef.Kind, AbilityDef] = {}


## The ability equipped in the [param kind] slot, or null.
func get_ability(kind: AbilityDef.Kind) -> AbilityDef:
	return _equipped.get(kind)


## Equips [param ability] in the [param kind] slot, or empties it when null.
func set_ability(kind: AbilityDef.Kind, ability: AbilityDef) -> void:
	assert(SLOTS.has(kind), "Actions aren't equipped; they're used from commands.")
	if ability:
		_equipped[kind] = ability
	else:
		_equipped.erase(kind)


## Every equipped ability, in slot order.
func abilities() -> Array[AbilityDef]:
	var found: Array[AbilityDef] = []
	for kind: AbilityDef.Kind in SLOTS:
		if _equipped.has(kind):
			found.append(_equipped[kind])
	return found


## The stat modifiers of every equipped ability.
func modifiers() -> Array[StatModifier]:
	var found: Array[StatModifier] = []
	for ability: AbilityDef in abilities():
		found.append_array(ability.modifiers)
	return found


## The kinds of gear equipped abilities allow, such as Equip Swords' &"sword".
func equip_tags() -> Array[StringName]:
	var found: Array[StringName] = []
	for ability: AbilityDef in abilities():
		found.append_array(ability.equip_tags)
	return found


func duplicate() -> AbilityLoadout:
	var copy := AbilityLoadout.new()
	copy.secondary = secondary
	copy._equipped = _equipped.duplicate()
	return copy


func to_dict() -> Dictionary:
	var data := {"secondary": String(secondary.id) if secondary else ""}
	for kind: AbilityDef.Kind in SLOTS:
		data[AbilityDef.kind_name(kind).to_lower()] = String(_equipped[kind].id) if _equipped.has(kind) else ""
	return data


## Jobs and abilities [param content] doesn't have any more are dropped with a warning.
static func from_dict(data: Dictionary, content: ContentRegistry) -> AbilityLoadout:
	var loadout := AbilityLoadout.new()
	var secondary_id := StringName(data.get("secondary", ""))
	if not secondary_id.is_empty():
		loadout.secondary = content.get_def(secondary_id) as JobDef
		if loadout.secondary == null:
			push_warning("A save has \"%s\" as a secondary command, but there's no such job." % secondary_id)
	for kind: AbilityDef.Kind in SLOTS:
		var id := StringName(data.get(AbilityDef.kind_name(kind).to_lower(), ""))
		if id.is_empty():
			continue
		var ability := content.get_def(id) as AbilityDef
		if ability and ability.kind == kind:
			loadout._equipped[kind] = ability
		else:
			push_warning("A save has \"%s\" equipped as a %s ability, but there's no such ability." % [id, AbilityDef.kind_name(kind)])
	return loadout
