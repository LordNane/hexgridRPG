class_name TargetingDef extends Resource
## Where an ability can be aimed: part of an AbilityDef rather than content of its own. Phase 6 adds
## area shapes, lines, line of sight and which units count as targets.

## The nearest hex it can be aimed at, in steps from the user; 0 lets the user aim at itself.
@export var range_min := 1
## The farthest hex it can be aimed at, in steps from the user.
@export var range_max := 1
## How many elevation levels above or below the user the target may be, or -1 for any.
@export var vertical_reach := -1


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if range_min < 0 or range_max < range_min:
		problems.append("its targeting range must be 0 or more, with range_max at least range_min")
	if vertical_reach < -1:
		problems.append("its vertical_reach must be -1 (any) or more")
	return problems
