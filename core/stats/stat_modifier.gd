class_name StatModifier extends Resource
## A change to one stat, from gear, an equipped ability or, in battle, a status. StatBlock.compute
## combines them: flat amounts first, then percentages, then multipliers.

enum Kind {
	## Adds [member value], as in Attack +5.
	FLAT,
	## Adds [member value] percent. Percentages on one stat add up: +10% and +20% make +30%.
	PERCENT,
	## Multiplies by [member value] after everything else. Multipliers stack: ×0.5 twice is ×0.25.
	MULTIPLY,
}

@export var stat := Stat.Id.ATTACK
@export var kind := Kind.FLAT
@export var value := 0.0


func _init(on_stat: Stat.Id = Stat.Id.ATTACK, amount: float = 0.0, modifier_kind: Kind = Kind.FLAT) -> void:
	stat = on_stat
	value = amount
	kind = modifier_kind


## How it reads in menus, such as "Attack +5", "Defense +10%" or "Speed ×1.5".
func describe() -> String:
	var number := str(roundi(value)) if is_equal_approx(value, roundf(value)) else String.num(value, 2)
	match kind:
		Kind.PERCENT:
			return "%s %s%s%%" % [Stat.display_name(stat), "+" if value >= 0.0 else "", number]
		Kind.MULTIPLY:
			return "%s ×%s" % [Stat.display_name(stat), number]
		_:
			return "%s %s%s" % [Stat.display_name(stat), "+" if value >= 0.0 else "", number]
