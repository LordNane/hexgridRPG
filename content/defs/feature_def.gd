class_name FeatureDef extends Def
## A nature element on top of the terrain, such as a forest, hills or mountains. Paint it on the
## feature layer with tiles whose "feature_id" custom data holds this id.

## Added to the terrain's move cost.
@export var extra_move_cost := 0.0
## Whether the party can't enter at all, like sheer mountains.
@export var blocks_movement := false
## Whether it stops line of sight. The hex itself is still seen; hexes behind it aren't.
@export var blocks_sight := false
## Extra vision range while standing here, like the view from hills.
@export var sight_bonus := 0
## Arenas for random battles here. They take the place of the terrain's.
@export_file("*.tscn") var battle_arenas: Array[String] = []


func validate() -> PackedStringArray:
	var problems := super()
	if extra_move_cost < 0.0:
		problems.append("extra_move_cost can't be negative")
	problems.append_array(TerrainDef.arena_problems(battle_arenas))
	return problems
