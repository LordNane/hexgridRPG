class_name CellPicker extends RefCounted
## Which hex of a 2.5D battle map is under a point on screen. It tests each hex column's outline
## from the front of the map to the back, so a raised hex covers the ones behind it, just as it
## does when drawn.

## Returned by [method pick] when no hex is under the point.
const NONE := Vector2i.MAX

var _projection: BattleProjection
var _map: BattleMap
## The map's hexes, front first.
var _front_to_back: Array[Vector2i] = []


func _init(map: BattleMap, projection: BattleProjection) -> void:
	_map = map
	_projection = projection
	_front_to_back = map.hexes()
	_front_to_back.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var depth_a := projection.depth(a)
		var depth_b := projection.depth(b)
		return depth_a > depth_b or (depth_a == depth_b and a.x > b.x))


## The hex whose column covers [param point], or [constant NONE].
func pick(point: Vector2) -> Vector2i:
	for hex: Vector2i in _front_to_back:
		if Geometry2D.is_point_in_polygon(point, _projection.silhouette(hex, _map.height_at(hex))):
			return hex
	return NONE
