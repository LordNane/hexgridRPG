class_name WorldState extends RefCounted
## Story flags and the state of each map. Saved with the session.

## Emitted when a flag is set or cleared.
signal flag_changed(flag: StringName, is_set: bool)

var _flags: Dictionary[StringName, bool] = {}
var _maps: Dictionary[StringName, MapState] = {}


## Whether the story flag [param flag] is set.
func has_flag(flag: StringName) -> bool:
	return _flags.has(flag)


## Sets [param flag], or clears it when [param is_set] is false.
func set_flag(flag: StringName, is_set: bool = true) -> void:
	if has_flag(flag) == is_set:
		return
	if is_set:
		_flags[flag] = true
	else:
		_flags.erase(flag)
	flag_changed.emit(flag, is_set)


## The state of the map with [param map_id], created the first time it's asked for.
func map_state(map_id: StringName) -> MapState:
	if not _maps.has(map_id):
		_maps[map_id] = MapState.new()
	return _maps[map_id]


func to_dict() -> Dictionary:
	var maps := {}
	for map_id: StringName in _maps:
		maps[map_id] = _maps[map_id].to_dict()
	return {"flags": _flags.keys(), "maps": maps}


static func from_dict(data: Dictionary) -> WorldState:
	var world := WorldState.new()
	for flag: Variant in data.get("flags", []):
		world._flags[StringName(flag)] = true
	var maps: Dictionary = data.get("maps", {})
	for map_id: Variant in maps:
		world._maps[StringName(map_id)] = MapState.from_dict(maps[map_id])
	return world
