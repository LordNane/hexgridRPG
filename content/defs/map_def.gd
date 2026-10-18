class_name MapDef extends Def
## An explorable map: the overworld, a cave or a town. All of them share one exploration system.

## The authored map scene (an ExploreMapScene). Stored as a path so loading content stays light.
@export_file("*.tscn") var scene: String
## Whether hexes the party hasn't seen yet are hidden.
@export var fog_of_war := true
## How many hexes around the party it can see.
@export var vision_radius := 3


func validate() -> PackedStringArray:
	var problems := super()
	if scene.is_empty() or not ResourceLoader.exists(scene):
		problems.append("scene \"%s\" doesn't exist" % scene)
	if vision_radius < 1:
		problems.append("vision_radius must be at least 1")
	return problems
