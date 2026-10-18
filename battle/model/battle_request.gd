class_name BattleRequest extends RefCounted
## Everything a battle needs to start, handed to BattleMode: where it's fought, who fights on each
## side and the seed for its randomness.

## The BattleArena scene.
var arena: String
## The party members who fight, placed on the arena's party spawns in order. They're the session's
## own Characters, so the battle's damage lands on them.
var party: Array[Character]
var encounter: EncounterDef
var rng_seed: int


func _init(arena_path: String, members: Array[Character], enemies: EncounterDef, seed_value: int) -> void:
	arena = arena_path
	party = members
	encounter = enemies
	rng_seed = seed_value
