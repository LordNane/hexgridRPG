class_name TerrainDef extends Def
## The ground of a hex, such as grassland, desert or water. Paint it with tiles whose
## "terrain_id" custom data holds this id.

## Travel cost to enter a hex of this terrain. 1 is a normal step and takes one hour on the map.
@export var move_cost := 1.0
## Whether the party can enter at all. Water and chasms can't be entered.
@export var passable := true
## Whether it stops line of sight. The hex itself is still seen; hexes behind it aren't.
@export var blocks_sight := false
@export_group("Battle")
## Move points it takes to step onto in battle; most ground takes 1.
@export var battle_move_cost := 1
## Arenas for random battles on this terrain. A feature's arenas come before these.
@export_file("*.tscn") var battle_arenas: Array[String] = []


func validate() -> PackedStringArray:
	var problems := super()
	if passable and move_cost <= 0.0:
		problems.append("move_cost must be positive")
	if passable and battle_move_cost < 1:
		problems.append("battle_move_cost must be at least 1")
	problems.append_array(arena_problems(battle_arenas))
	return problems


## Problems with a list of arena scene paths, for Defs that list arenas.
static func arena_problems(arenas: Array[String]) -> PackedStringArray:
	var problems := PackedStringArray()
	for path: String in arenas:
		if not ResourceLoader.exists(path):
			problems.append("arena \"%s\" doesn't exist" % path)
	return problems
