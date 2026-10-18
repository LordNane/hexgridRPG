class_name HexLayout extends Resource
## Where hexes appear on screen: converts between hexes and pixels for flat-top hexes, squashed
## vertically for the game's 3/4 view.
##
## The only class that knows about pixels. Models work purely in hexes ([Hex]); views ask a
## HexLayout where to draw. Sharing one layout keeps every map, sprite and click in agreement, and
## matches a TileSet set to Hexagon shape, Vertical offset axis and Stairs Down layout.

## Size of one hex's top face in pixels. Keep the width divisible by 4 and the height even so
## every hex center lands on a whole pixel.
@export var cell_size := Vector2i(32, 16)

## Pixels a tile rises per level of elevation.
@export var elevation_step := 8

## Pixel position of the center of hex (0, 0).
@export var origin := Vector2.ZERO

## Screen directions closer than this count as a tie in [method neighbor_toward].
const _TIE_EPSILON := 0.0001


## The center of [param hex] in pixels.
func to_pixel(hex: Vector2i) -> Vector2:
	return origin + Vector2(cell_size.x * 0.75 * hex.x, cell_size.y * (hex.y + hex.x * 0.5))


## The hex whose top face contains [param point].
func to_hex(point: Vector2) -> Vector2i:
	var local := point - origin
	var q := local.x / (cell_size.x * 0.75)
	var r := local.y / cell_size.y - q * 0.5
	return Hex.round_axial(Vector2(q, r))


## The six corners of [param hex]'s top face, clockwise on screen from the rightmost point.
func corners(hex: Vector2i) -> PackedVector2Array:
	var center := to_pixel(hex)
	var half_width := cell_size.x * 0.5
	var quarter_width := cell_size.x * 0.25
	var half_height := cell_size.y * 0.5
	return PackedVector2Array([
		center + Vector2(half_width, 0),
		center + Vector2(quarter_width, half_height),
		center + Vector2(-quarter_width, half_height),
		center + Vector2(-half_width, 0),
		center + Vector2(-quarter_width, -half_height),
		center + Vector2(quarter_width, -half_height),
	])


## The screen offset for something raised [param height] levels above the ground.
func elevation_offset(height: int) -> Vector2:
	return Vector2(0, -elevation_step * height)


## The neighbor of [param hex] that best matches a screen direction, for arrow keys and sticks.
## Flat-top hexes have no east or west neighbor, so a horizontal press stays on the same visual
## row and zig-zags the way the map does. A zero direction returns [param hex] itself.
func neighbor_toward(hex: Vector2i, screen_dir: Vector2) -> Vector2i:
	if screen_dir.is_zero_approx():
		return hex
	var wanted := screen_dir.normalized()
	var center := to_pixel(hex)
	var row := Hex.to_offset(hex).y
	var best := hex
	var best_score := -INF
	for candidate: Vector2i in Hex.neighbors(hex):
		var score := wanted.dot((to_pixel(candidate) - center).normalized())
		var is_tie := absf(score - best_score) <= _TIE_EPSILON
		if (score > best_score and not is_tie) or (is_tie and Hex.to_offset(candidate).y == row):
			best = candidate
			best_score = score
	return best
