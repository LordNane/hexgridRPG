class_name AbilityDef extends Def
## Something a character can learn from a job: an action used from a battle command (Fire, Cure), a
## reaction that triggers by itself (Counter), or a support or movement ability that's always on
## while equipped (Attack Up, Move +1). Weapons' basic attacks and items' uses are actions too.
## An action works in battle once it has [member targeting] and [member effects]; Phase 6 gives
## them to spells and skills.

enum Kind {
	## Used from a battle command: the character's job's, or their secondary one's.
	ACTION,
	## Triggers by itself in battle, such as striking back when hit.
	REACTION,
	## Always on while equipped.
	SUPPORT,
	## Always on while equipped; about getting around the battlefield.
	MOVEMENT,
}

const KIND_NAMES: Array[String] = ["Action", "Reaction", "Support", "Movement"]

@export var kind := Kind.ACTION
## MP spent each time it's used. Only actions cost MP.
@export var mp_cost := 0
## Stat changes while it's equipped, for abilities such as Move +1.
@export var modifiers: Array[StatModifier] = []
## Kinds of gear the character may use while it's equipped, for supports such as Equip Swords.
## Matched against each item's equip_tag, like a job's equip_tags.
@export var equip_tags: Array[StringName] = []
@export_group("In battle")
## Where an action can be aimed.
@export var targeting: TargetingDef
## What an action does to the unit it hits, in order.
@export var effects: Array[Effect] = []


static func kind_name(of_kind: Kind) -> String:
	return KIND_NAMES[of_kind]


## Whether it can be used in battle yet: an action with targeting and at least one effect.
func is_usable_in_battle() -> bool:
	return kind == Kind.ACTION and targeting != null and not effects.is_empty()


func validate() -> PackedStringArray:
	var problems := super()
	if mp_cost < 0:
		problems.append("mp_cost can't be negative")
	if modifiers.has(null):
		problems.append("has an empty modifier slot")
	if kind == Kind.ACTION and not (modifiers.is_empty() and equip_tags.is_empty()):
		problems.append("is an action, so its modifiers and equip_tags would never apply; only equipped abilities use them")
	if kind != Kind.ACTION and mp_cost > 0:
		problems.append("only actions cost MP")
	if effects.has(null):
		problems.append("has an empty effect slot")
	if not effects.is_empty() and targeting == null:
		problems.append("has effects but no targeting, so it can't be aimed")
	if targeting:
		problems.append_array(targeting.validate())
	for effect: Effect in effects:
		if effect:
			problems.append_array(effect.validate())
	return problems
