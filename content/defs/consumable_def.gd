class_name ConsumableDef extends ItemDef
## An item used up when it's used, such as a Potion. What it does is an ability, so items share
## targeting and effects with skills and spells.

@export var ability: AbilityDef


func validate() -> PackedStringArray:
	var problems := super()
	if ability == null:
		problems.append("has no ability")
	elif ability.kind != AbilityDef.Kind.ACTION:
		problems.append("its ability \"%s\" must be an action" % ability.id)
	return problems
