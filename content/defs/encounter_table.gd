class_name EncounterTable extends Def
## The random battles of a region: how often they happen and which encounters to pick from.
## Regions share a table by pointing at the same one. EncounterRoller rolls on it each step.

## The chance of a battle on each step once the grace period after the last one is over.
@export_range(0.0, 1.0, 0.01) var chance_per_step := 0.1
## Each encounter and its weight: one with weight 2 comes up twice as often as one with weight 1.
@export var encounters: Dictionary[EncounterDef, int] = {}


func validate() -> PackedStringArray:
	var problems := super()
	if encounters.is_empty():
		problems.append("has no encounters")
	if encounters.has(null):
		problems.append("has an empty encounter slot")
	for encounter: EncounterDef in encounters:
		if encounter and encounters[encounter] < 1:
			problems.append("the weight of \"%s\" must be at least 1" % encounter.id)
	return problems
