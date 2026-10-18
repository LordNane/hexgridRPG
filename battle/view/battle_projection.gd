@tool
class_name BattleProjection extends RefCounted
## Where battle hexes appear in the 2.5D view. Every hex-to-screen conversion in battle goes
## through [method project], so turning the camera in 60° steps later only changes this class.

var layout: HexLayout


func _init(hex_layout: HexLayout = null) -> void:
	layout = hex_layout if hex_layout else HexLayout.new()


## The screen point of the center of [param hex]'s top face, raised [param height] levels.
func project(hex: Vector2i, height: int = 0) -> Vector2:
	return layout.to_pixel(hex) + layout.elevation_offset(height)


## The six corners of [param hex]'s top face raised [param height] levels, clockwise on screen from
## the rightmost.
func corners(hex: Vector2i, height: int) -> PackedVector2Array:
	var lift := layout.elevation_offset(height)
	var points := layout.corners(hex)
	for i: int in points.size():
		points[i] += lift
	return points


## The outline a hex column raised [param height] levels covers on screen: its top face plus its
## sides down to the ground.
func silhouette(hex: Vector2i, height: int) -> PackedVector2Array:
	var top := corners(hex, height)
	var ground := corners(hex, 0)
	return PackedVector2Array([top[3], top[4], top[5], top[0], ground[0], ground[1], ground[2], ground[3]])


## Where [param hex] comes in drawing order: hexes nearer the back of the map draw first.
func depth(hex: Vector2i) -> float:
	return project(hex).y
