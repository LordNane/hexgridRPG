@abstract
class_name PoiHost extends RefCounted
## The screen a POI talks to: the exploration HUD in the game, a recorder in tests. It grows as POIs
## learn new tricks, such as asking questions, opening shops or starting battles.


## Shows [param text] and returns once the player has read it.
@abstract func say(text: String) -> void
