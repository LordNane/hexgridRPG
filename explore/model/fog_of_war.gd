class_name FogOfWar extends RefCounted
## What the party can see now, and what it has ever seen. Vision reaches a radius around the
## party; forests, mountains and other sight-blocking hexes stop it, though they are seen themselves.

var _map: ExploreMap
var _explored: Dictionary[Vector2i, bool]
var _visible: Dictionary[Vector2i, bool] = {}


## [param explored] is the map's saved MapState.explored; looking around adds to it.
func _init(map: ExploreMap, explored: Dictionary[Vector2i, bool]) -> void:
	_map = map
	_explored = explored


## Whether the party has ever seen [param hex].
func is_explored(hex: Vector2i) -> bool:
	return _explored.has(hex)


## Whether the party can see [param hex] right now.
func is_visible(hex: Vector2i) -> bool:
	return _visible.has(hex)


## Recomputes what the party sees from [param center] within [param radius]. Returns every hex
## whose fog changed (newly seen, or just left behind) so views redraw only those.
func look_from(center: Vector2i, radius: int) -> Array[Vector2i]:
	var now_visible: Dictionary[Vector2i, bool] = {}
	for hex: Vector2i in Hex.disc(center, radius):
		if _map.has_hex(hex) and _has_line_of_sight(center, hex):
			now_visible[hex] = true
	var changed: Array[Vector2i] = []
	for hex: Vector2i in _visible:
		if not now_visible.has(hex):
			changed.append(hex)
	for hex: Vector2i in now_visible:
		if not _visible.has(hex):
			changed.append(hex)
			_explored[hex] = true
	_visible = now_visible
	return changed


func _has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	var line := Hex.line(from, to)
	for i: int in range(1, line.size() - 1):
		if _map.blocks_sight(line[i]):
			return false
	return true
