class_name MapState extends RefCounted
## What the party has done on one map: the hexes it has seen and the one-time POIs it has used.

## Every hex the party has seen. FogOfWar adds to it directly.
var explored: Dictionary[Vector2i, bool] = {}

var _used_pois: Dictionary[Vector2i, bool] = {}


## Whether the one-time POI on [param hex] has been used.
func is_used(hex: Vector2i) -> bool:
	return _used_pois.has(hex)


## Records that the one-time POI on [param hex] has been used.
func mark_used(hex: Vector2i) -> void:
	_used_pois[hex] = true


func to_dict() -> Dictionary:
	return {"explored": _pack(explored.keys()), "used_pois": _pack(_used_pois.keys())}


static func from_dict(data: Dictionary) -> MapState:
	var state := MapState.new()
	for hex: Vector2i in _unpack(data.get("explored", [])):
		state.explored[hex] = true
	for hex: Vector2i in _unpack(data.get("used_pois", [])):
		state._used_pois[hex] = true
	return state


## Hex lists are saved as flat [q0, r0, q1, r1, …] arrays: compact and JSON-friendly.
static func _pack(hexes: Array) -> Array[int]:
	var values: Array[int] = []
	for hex: Vector2i in hexes:
		values.append(hex.x)
		values.append(hex.y)
	return values


static func _unpack(values: Array) -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	for i: int in range(0, values.size() - 1, 2):
		hexes.append(Vector2i(int(values[i]), int(values[i + 1])))
	return hexes
