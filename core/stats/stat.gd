class_name Stat
## The stats every character has, and their names. Content files store a stat as its number in
## [enum Id], so add new stats at the end and never reorder them; saves use [method key] instead.

enum Id {
	## Damage a character can take before falling.
	HP,
	## Spent on spells and some skills.
	MP,
	## Strength of weapon attacks and physical skills.
	ATTACK,
	## Protection from weapon attacks and physical skills.
	DEFENSE,
	## Strength of spells.
	MAGIC,
	## Protection from spells.
	RESIST,
	## How quickly turns come around in battle.
	SPEED,
	## Hexes a character can walk in one turn.
	MOVE,
	## Elevation levels a character can climb or drop in one step.
	JUMP,
	## How well a character dodges weapon attacks.
	EVASION,
}

const NAMES: Array[String] = ["HP", "MP", "Attack", "Defense", "Magic", "Resist", "Speed", "Move", "Jump", "Evasion"]
const SHORT_NAMES: Array[String] = ["HP", "MP", "ATK", "DEF", "MAG", "RES", "SPD", "MOV", "JMP", "EVA"]


## Every stat, in order.
static func all() -> Array[Id]:
	var stats: Array[Id] = []
	stats.assign(Id.values())
	return stats


static func display_name(stat: Id) -> String:
	return NAMES[stat]


## A three-letter name for tight spaces, such as "ATK".
static func short_name(stat: Id) -> String:
	return SHORT_NAMES[stat]


## The lowest a stat can go: a character always has at least 1 HP, and nothing goes below 0.
static func minimum(stat: Id) -> int:
	return 1 if stat == Id.HP else 0


## The stat's name in saves, such as "attack". It stays the same if stats are added.
static func key(stat: Id) -> String:
	return String(Id.keys()[stat]).to_lower()


## The stat saved as [param text] by [method key], or -1 if there's no such stat.
static func from_key(text: String) -> int:
	return Id.get(text.to_upper(), -1)
