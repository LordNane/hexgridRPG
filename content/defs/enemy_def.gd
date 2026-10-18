class_name EnemyDef extends CharacterDef
## A foe the party can fight: a character like any other (job, level, gear), plus what it leaves
## behind. Encounters list them; AI behavior arrives in Phase 7.

## Gold the party gets for defeating it.
@export var gold := 0
## Items it may drop, each with its chance from 0 to 1.
@export var drops: Dictionary[ItemDef, float] = {}


func validate() -> PackedStringArray:
	var problems := super()
	if gold < 0:
		problems.append("gold can't be negative")
	if drops.has(null):
		problems.append("has an empty drop slot")
	for item: ItemDef in drops:
		if item and (drops[item] <= 0.0 or drops[item] > 1.0):
			problems.append("the chance of dropping \"%s\" must be above 0 and at most 1" % item.id)
	return problems
