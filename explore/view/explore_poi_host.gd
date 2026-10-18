class_name ExplorePoiHost extends PoiHost
## The exploration screen's side of POIs: messages show in the HUD, and the Game autoload moves the
## party between maps and into battles.

## Whether a POI asked to leave the map. ExploreMode leaves once the POI finishes.
var exit_requested := false

var _hud: ExploreHud
## Picks the arena for a battle where the party stands: (EncounterDef) -> String.
var _arena_for: Callable


func _init(hud: ExploreHud, arena_for: Callable) -> void:
	_hud = hud
	_arena_for = arena_for


func say(text: String) -> void:
	await _hud.show_message(text)


func enter_map(map: MapDef, entry: StringName) -> void:
	await Game.enter_map(map, entry)


func exit_map() -> void:
	exit_requested = true


func start_battle(encounter: EncounterDef) -> void:
	var arena: String = _arena_for.call(encounter)
	if arena.is_empty():
		push_warning("There's no arena for %s here, so the battle is skipped." % encounter.id)
		return
	await Game.start_battle(encounter, arena)
