@abstract
class_name PoiHost extends RefCounted
## The screen a POI talks to: the exploration screen in the game, a recorder in tests. It grows as POIs
## learn new tricks, such as asking questions, opening shops or starting battles.


## Shows [param text] and returns once the player has read it.
@abstract func say(text: String) -> void


## Takes the party into [param map] at its arrival point [param entry]. Returns once the party has
## left that map again.
@abstract func enter_map(map: MapDef, entry: StringName) -> void


## Takes the party back to the map it entered this one from, once the POI's actions finish.
@abstract func exit_map() -> void


## Fights [param encounter] where the party stands. Returns once the battle is won; a lost one ends
## the game.
@abstract func start_battle(encounter: EncounterDef) -> void
