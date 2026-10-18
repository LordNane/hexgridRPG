class_name ExploreOverlay extends Node2D
## Draws the hovered hex and the route the party would walk to it.

const HOVER_COLOR := Color(1, 1, 1, 0.85)
const ROUTE_COLOR := Color("ffd84a")
const ROUTE_SHADOW := Color(0, 0, 0, 0.55)

var _layout: HexLayout
var _hover := Vector2i.ZERO
var _has_hover := false
var _route: Array[Vector2i] = []


func setup(layout: HexLayout) -> void:
	_layout = layout


## Outlines [param hex] and dots [param route] (whose first hex, the party's, gets no dot).
func show_hover(hex: Vector2i, route: Array[Vector2i]) -> void:
	_hover = hex
	_has_hover = true
	_route = route
	queue_redraw()


func clear() -> void:
	_has_hover = false
	_route = []
	queue_redraw()


func _draw() -> void:
	if not _has_hover:
		return
	for i: int in range(1, _route.size()):
		var dot := _layout.to_pixel(_route[i]).floor()
		draw_rect(Rect2(dot + Vector2(-1, 0), Vector2(3, 3)), ROUTE_SHADOW)
		draw_rect(Rect2(dot + Vector2(-1, -1), Vector2(2, 2)), ROUTE_COLOR)
	var outline := _layout.corners(_hover)
	outline.append(outline[0])
	draw_polyline(outline, HOVER_COLOR)
