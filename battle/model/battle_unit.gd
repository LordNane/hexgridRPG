class_name BattleUnit extends RefCounted
## One fighter in a battle: a Character, the side it's on, where it stands, which way it faces and
## when its next turn comes. Damage lands on the Character itself.

enum Team { PARTY, ENEMY }

var character: Character
var team: Team
## The EnemyDef an enemy was made from, for its loot; null for party members.
var source: EnemyDef
var hex: Vector2i
## The [enum Hex.Dir] it faces.
var facing: int
## Charge time: Speed fills it, and the unit takes a turn at CtScheduler.READY.
var ct := 0
## Whether it has moved this turn.
var moved := false
## Whether it has acted this turn.
var acted := false
## The character's name.
var name: String:
	get:
		return character.name


func _init(fighter: Character, side: Team, at: Vector2i, faces: int, made_from: EnemyDef = null) -> void:
	character = fighter
	team = side
	hex = at
	facing = faces
	source = made_from


## The unit's stats in battle. Statuses join in Phase 6.
func stats() -> StatBlock:
	return character.stats()


func is_alive() -> bool:
	return character.hp > 0


## Whether [param other] fights on the other side.
func is_foe_of(other: BattleUnit) -> bool:
	return team != other.team
