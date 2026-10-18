class_name TerrainDef extends Def
## The ground of a hex, such as grassland, desert or water. Paint it with tiles whose
## "terrain_id" custom data holds this id.

## Travel cost to enter a hex of this terrain. 1 is a normal step and takes one hour on the map.
@export var move_cost := 1.0
## Whether the party can enter at all. Water and chasms can't be entered.
@export var passable := true
## Whether it stops line of sight. The hex itself is still seen; hexes behind it aren't.
@export var blocks_sight := false


func validate() -> PackedStringArray:
	var problems := super()
	if passable and move_cost <= 0.0:
		problems.append("move_cost must be positive")
	return problems
