@tool
class_name CellView extends Node2D
## One hex of a battle arena in 2.5D: its top face raised by its height, the cliff below it down to
## the ground, a highlight when it's in range of something, and its prop standing on top. It sits
## on the hex's ground point, so a y-sorted parent draws hexes back to front.

## Drawn instead of a cliff texture when the terrain has none.
const BARE_CLIFF := Color(0.24, 0.2, 0.18)

var hex: Vector2i
var height := 0
## The painted terrain tile's texture.
var top: Texture2D
## One elevation level of cliff, from the terrain tile's "cliff" custom data.
var cliff: Texture2D
var prop: Texture2D
## How far the prop is drawn up and left of the hex center.
var prop_origin := Vector2.ZERO
## Fills the top face while visible, such as for a movement range.
var highlight := Color.TRANSPARENT:
	set(value):
		highlight = value
		queue_redraw()

var _projection: BattleProjection


## Sets the cell up from [param hex]'s tiles on the arena's layers. [param heights] and
## [param props] may be null.
func setup(projection: BattleProjection, at: Vector2i, terrain: TileMapLayer, heights: TileMapLayer, props: TileMapLayer) -> void:
	_projection = projection
	hex = at
	position = projection.project(hex)
	top = TileArt.texture_at(terrain, hex)
	cliff = TileArt.data_at(terrain, hex, TileArt.CLIFF) as Texture2D
	var painted_height: Variant = TileArt.data_at(heights, hex, BattleMapBuilder.HEIGHT) if heights else null
	height = int(painted_height) if painted_height != null else 0
	if props and props.get_cell_source_id(hex) >= 0:
		prop = TileArt.texture_at(props, hex)
		prop_origin = TileArt.origin_at(props, hex)
	queue_redraw()


## The point on top of this hex, in the parent's coordinates, where a unit stands.
func top_point() -> Vector2:
	return _projection.project(hex, height)


func _draw() -> void:
	if _projection == null:
		return
	var step := _projection.layout.elevation_step
	var face := _local(_projection.corners(hex, height))
	var corner := face[3] + Vector2(0, -_projection.layout.cell_size.y / 2.0)
	for level: int in height:
		if cliff:
			draw_texture(cliff, corner + Vector2(0, step * level))
	if cliff == null and height > 0:
		draw_colored_polygon(_local(_projection.silhouette(hex, height)), BARE_CLIFF)
	if top:
		draw_texture(top, corner)
	else:
		draw_colored_polygon(face, Color(0.4, 0.4, 0.4))
	if highlight.a > 0.0:
		draw_colored_polygon(face, highlight)
		face.append(face[0])
		draw_polyline(face, Color(highlight, minf(1.0, highlight.a * 2.0)))
	if prop:
		var center := _projection.project(hex, height) - position
		draw_texture(prop, (center - prop_origin - prop.get_size() / 2.0).round())


func _local(points: PackedVector2Array) -> PackedVector2Array:
	var local := PackedVector2Array()
	for point: Vector2 in points:
		local.append(point - position)
	return local
