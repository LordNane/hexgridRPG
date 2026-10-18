class_name CharacterDef extends Def
## A premade character, such as a member of the starting party or, later, a recruit. Its
## [member display_name] is the character's name. Character.from_def turns it into a Character.

@export var job: JobDef
## Each level past 1 adds [member job]'s stat growth once.
@export var level := 1
## The character's own stats at level 1, before their job scales them. Move, Jump and Evasion come
## from the job instead.
@export var base_stats: Dictionary[Stat.Id, int] = {}
## Worn from the start, one piece per slot.
@export var equipment: Array[EquipmentDef] = []
## Abilities known from the start. Each counts as learned from the job that teaches it.
@export var learned: Array[AbilityDef] = []


func validate() -> PackedStringArray:
	var problems := super()
	if job == null:
		problems.append("has no job")
	if level < 1:
		problems.append("level must be at least 1")
	if base_stats.get(Stat.Id.HP, 0) < 1:
		problems.append("needs at least 1 base HP")
	if equipment.has(null) or learned.has(null):
		problems.append("has an empty equipment or learned slot")
	var filled: Dictionary[EquipmentDef.Slot, bool] = {}
	for item: EquipmentDef in equipment:
		if item and filled.has(item.slot):
			problems.append("wears two pieces in the %s slot" % EquipmentDef.slot_name(item.slot))
		elif item:
			filled[item.slot] = true
	return problems
