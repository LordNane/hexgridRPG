class_name PoiContext extends RefCounted
## What a PoiAction can see and do while it runs: the playthrough's state, where the POI is, and
## the screen it talks through.

var session: GameSession
## The state of the map the POI is on.
var map_state: MapState
## The hex the POI is on.
var hex: Vector2i

var _host: PoiHost


func _init(game_session: GameSession, state: MapState, poi_hex: Vector2i, host: PoiHost) -> void:
	session = game_session
	map_state = state
	hex = poi_hex
	_host = host


## Shows [param text] and waits until the player dismisses it.
func say(text: String) -> void:
	@warning_ignore("redundant_await")  # The game's host waits for the player; a test host may not.
	await _host.say(text)
