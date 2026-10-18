class_name EncounterDef extends Def
## A group of enemies the party can meet, at random from a region's EncounterTable or on purpose
## from a POI's StartBattleAction. Its [member display_name] is announced when the battle starts.

## Who the party fights, placed on the arena's enemy spawns in order.
@export var enemies: Array[EnemyDef] = []
## Arenas to fight in. When empty, the battle takes place in an arena from the pool of the
## feature, or else the terrain, where the party stands.
@export_file("*.tscn") var arenas: Array[String] = []


## The arenas a battle with these enemies could take place in, on a hex with [param terrain] and
## [param feature] (which may be null).
func arena_pool(terrain: TerrainDef, feature: FeatureDef) -> Array[String]:
	if not arenas.is_empty():
		return arenas
	if feature and not feature.battle_arenas.is_empty():
		return feature.battle_arenas
	if terrain and not terrain.battle_arenas.is_empty():
		return terrain.battle_arenas
	var none: Array[String] = []
	return none


func validate() -> PackedStringArray:
	var problems := super()
	if enemies.is_empty():
		problems.append("has no enemies")
	if enemies.has(null):
		problems.append("has an empty enemy slot")
	problems.append_array(TerrainDef.arena_problems(arenas))
	return problems
