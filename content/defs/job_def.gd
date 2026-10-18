class_name JobDef extends Def
## A job, such as Squire or Black Mage: how it shapes a character's stats, the gear it can use, the
## abilities it teaches and what unlocks it. Characters keep what they've learned when they change
## jobs, so an old job's actions can become their secondary command.

## The stats a job sets outright instead of scaling the character's own.
const JOB_SET_STATS: Array[Stat.Id] = [Stat.Id.MOVE, Stat.Id.JUMP, Stat.Id.EVASION]

## The name of its command in battle menus, such as "Black Magic".
@export var command_name := ""
@export_group("Stats")
## How it scales the character's own HP, MP, Attack, Defense, Magic, Resist and Speed, in percent.
## Stats left out stay at 100.
@export var stat_multipliers: Dictionary[Stat.Id, int] = {}
## What each level gained in this job adds to the character's own stats. Fractions add up over
## levels, and the gains stay when the character changes jobs.
@export var stat_growth: Dictionary[Stat.Id, float] = {}
## Move, Jump and Evasion come from the job alone, whoever has it.
@export var move := 4
@export var jump := 3
@export var evasion := 5
@export_group("")
## Kinds of gear it can use, matched against each item's equip_tag.
@export var equip_tags: Array[StringName] = []
## What the Attack command does without a weapon, such as a punch.
@export var unarmed_attack: AbilityDef
## Each ability it teaches and its JP cost. Its actions, in this order, make up its command.
@export var abilities: Dictionary[AbilityDef, int] = {}
## Every condition must hold, for the character changing jobs, before it can be chosen.
@export var unlock_conditions: Array[Condition] = []
## Shown while it's locked, such as "Reach level 2 as a Squire."
@export var unlock_hint := ""
## How a character looks in this job.
@export var sprite: Texture2D
## The colors Phase 9's palette-swap shader paints [member sprite] with.
@export var palette: Texture2D


## The stats a character has in this job before gear and abilities: their own stats ([param own])
## scaled by [member stat_multipliers], and this job's Move, Jump and Evasion.
func base_stats(own: StatBlock) -> StatBlock:
	var base := StatBlock.new()
	for stat: Stat.Id in Stat.all():
		base.set_value(stat, own.exact(stat) * multiplier(stat) / 100.0)
	base.set_value(Stat.Id.MOVE, move)
	base.set_value(Stat.Id.JUMP, jump)
	base.set_value(Stat.Id.EVASION, evasion)
	return base


## The percentage it scales [param stat] by.
func multiplier(stat: Stat.Id) -> int:
	return stat_multipliers.get(stat, 100)


## Its actions, in order: the command it gives in battle.
func actions() -> Array[AbilityDef]:
	var found: Array[AbilityDef] = []
	for ability: AbilityDef in abilities:
		if ability and ability.kind == AbilityDef.Kind.ACTION:
			found.append(ability)
	return found


func teaches(ability: AbilityDef) -> bool:
	return abilities.has(ability)


## The JP it costs to learn [param ability] here.
func jp_cost(ability: AbilityDef) -> int:
	return abilities.get(ability, 0)


## Whether [param character] may take up this job now.
func is_unlocked(session: GameSession, character: Character) -> bool:
	for condition: Condition in unlock_conditions:
		if not condition.is_met(session, character):
			return false
	return true


func validate() -> PackedStringArray:
	var problems := super()
	if command_name.is_empty():
		problems.append("has no command_name")
	for stat: Stat.Id in JOB_SET_STATS:
		if stat_multipliers.has(stat) or stat_growth.has(stat):
			problems.append("%s comes from the job's own %s setting, not stat_multipliers or stat_growth" % [
				Stat.display_name(stat), Stat.key(stat)])
	for stat: Stat.Id in stat_multipliers:
		if stat_multipliers[stat] <= 0:
			problems.append("its %s multiplier must be positive" % Stat.display_name(stat))
	if move < 1 or jump < 0 or evasion < 0:
		problems.append("move must be at least 1, and jump and evasion can't be negative")
	if abilities.has(null) or unlock_conditions.has(null):
		problems.append("has an empty ability or condition slot")
	for ability: AbilityDef in abilities:
		if ability and abilities[ability] < 0:
			problems.append("the JP cost of \"%s\" can't be negative" % ability.id)
	if actions().is_empty():
		problems.append("teaches no actions, so its command would be empty")
	if unarmed_attack == null or not unarmed_attack.is_usable_in_battle():
		problems.append("needs an unarmed_attack that works in battle (an action with targeting and effects)")
	return problems
