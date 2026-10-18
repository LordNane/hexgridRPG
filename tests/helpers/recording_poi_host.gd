class_name RecordingPoiHost extends PoiHost
## A PoiHost for tests: records everything POIs say and every map change they ask for, and returns
## at once.

## Emit to let a waiting [method enter_map] return, as if the party had left the map.
signal party_returned

var said: Array[String] = []
## Each map entered, as "map_id:entry".
var entered: Array[String] = []
var exits := 0
## The id of each encounter fought.
var battles: Array[String] = []
## When on, [method enter_map] waits for [signal party_returned], as the game waits for the party
## to leave the map.
var waits_in_maps := false


func say(text: String) -> void:
	said.append(text)


func enter_map(map: MapDef, entry: StringName) -> void:
	entered.append("%s:%s" % [map.id, entry])
	if waits_in_maps:
		await party_returned


func exit_map() -> void:
	exits += 1


func start_battle(encounter: EncounterDef) -> void:
	battles.append(String(encounter.id))
