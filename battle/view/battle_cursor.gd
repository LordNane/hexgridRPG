class_name BattleCursor extends Node2D
## The battle cursor: an outline on top of the chosen hex and a bobbing arrow above it, drawn over
## everything so it never hides behind a cliff. The camera follows it.

const COLOR := Color(1.0, 0.86, 0.35)
const SHADOW := Color(0, 0, 0, 0.6)
## Pixels the arrow bobs, and bobs per second.
const BOB_HEIGHT := 2.0
const BOB_SPEED := 3.0

var _outline := PackedVector2Array()
var _time := 0.0


## Moves the cursor onto [param hex], raised [param height] levels.
func point_at(projection: BattleProjection, hex: Vector2i, height: int) -> void:
	position = projection.project(hex, height)
	_outline = PackedVector2Array()
	for corner: Vector2 in projection.corners(hex, height):
		_outline.append(corner - position)
	_outline.append(_outline[0])
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if _outline.is_empty():
		return
	draw_polyline(_shifted(_outline, Vector2(0, 1)), SHADOW)
	draw_polyline(_outline, COLOR)
	var bob := roundf(sin(_time * TAU * BOB_SPEED / 2.0) * BOB_HEIGHT)
	var tip := Vector2(0, -26 + bob)
	var arrow := PackedVector2Array([tip, tip + Vector2(-4, -5), tip + Vector2(4, -5)])
	draw_colored_polygon(_shifted(arrow, Vector2(1, 1)), SHADOW)
	draw_colored_polygon(arrow, COLOR)


static func _shifted(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var moved := PackedVector2Array()
	for point: Vector2 in points:
		moved.append(point + by)
	return moved
