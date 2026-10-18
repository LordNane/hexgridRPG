class_name EncounterRoller
## Whether a step on a map leads into a random battle, against whom and in which arena. Rolls on
## the session's RNG, after a grace period of quiet steps that every battle starts over.

## Steps without random battles after a battle, and at the start of a journey.
const GRACE_STEPS := 6


## Rolls for a random battle on one step, in a region whose table is [param table] (null where
## there are none). Returns the encounter, or null. Counts down the grace period first.
static func roll(session: GameSession, table: EncounterTable) -> EncounterDef:
	if session.encounter_grace > 0:
		session.encounter_grace -= 1
		return null
	if table == null or table.encounters.is_empty() or not session.rng.chance(table.chance_per_step):
		return null
	var encounters: Array[EncounterDef] = []
	var weights := PackedFloat32Array()
	for encounter: EncounterDef in table.encounters:
		encounters.append(encounter)
		weights.append(table.encounters[encounter])
	return encounters[session.rng.pick_weighted(weights)]


## Starts the grace period over, after a battle.
static func reset_grace(session: GameSession) -> void:
	session.encounter_grace = GRACE_STEPS


## An arena for [param encounter] on a hex with [param terrain] and [param feature], picked from
## its pool on [param rng]. Empty if the pool is.
static func pick_arena(encounter: EncounterDef, terrain: TerrainDef, feature: FeatureDef, rng: SeededRng) -> String:
	var pool := encounter.arena_pool(terrain, feature)
	return "" if pool.is_empty() else pool[rng.randi_range(0, pool.size() - 1)]
