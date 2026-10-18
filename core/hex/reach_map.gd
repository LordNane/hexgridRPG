class_name ReachMap extends RefCounted
## What [method HexPathfinder.reachable] found: each reachable hex, its cost, and the way there.

## The hex the search started from.
var origin: Vector2i

var _costs: Dictionary[Vector2i, float]
var _came_from: Dictionary[Vector2i, Vector2i]


func _init(start: Vector2i, costs: Dictionary[Vector2i, float], came_from: Dictionary[Vector2i, Vector2i]) -> void:
	origin = start
	_costs = costs
	_came_from = came_from


## Whether [param hex] can be reached.
func has(hex: Vector2i) -> bool:
	return _costs.has(hex)


## The total cost to reach [param hex], or INF if it can't be reached.
func cost_to(hex: Vector2i) -> float:
	return _costs.get(hex, INF)


## Every reachable hex, the origin included.
func hexes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_costs.keys())
	return result


## The cheapest path from [member origin] to [param hex], both ends included; empty if unreachable.
func path_to(hex: Vector2i) -> Array[Vector2i]:
	return HexPathfinder.trace_path(_came_from, hex)
