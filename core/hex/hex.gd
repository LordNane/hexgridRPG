class_name Hex
## Axial hex-grid math for flat-top hexes. A hex is a [Vector2i] holding (q, r).
##
## Everything here is static, pure and pixel-free; [HexLayout] decides where hexes appear on
## screen. Directions are plain ints holding a [enum Dir] value so they can be looped over and
## stored without casts. Reference: https://www.redblobgames.com/grids/hexagons/

## The six neighbor directions, counter-clockwise on screen starting from south-east.
enum Dir { SE, NE, N, NW, SW, S }

const DIR_COUNT := 6

## The axial step for each [enum Dir], in enum order.
const OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

const SQRT3 := 1.7320508075688772

## Shifts line endpoints off hex edges so points exactly between two hexes always round the same way.
const _LINE_NUDGE := Vector2(1e-6, 2e-6)


## The hex one step from [param hex] in direction [param dir]. Directions wrap, so 6 is SE again.
static func neighbor(hex: Vector2i, dir: int) -> Vector2i:
	return hex + OFFSETS[posmod(dir, DIR_COUNT)]


## All six neighbors of [param hex], in [enum Dir] order.
static func neighbors(hex: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset: Vector2i in OFFSETS:
		result.append(hex + offset)
	return result


## The number of steps between two hexes.
static func distance(a: Vector2i, b: Vector2i) -> int:
	var d := a - b
	return (absi(d.x) + absi(d.y) + absi(d.x + d.y)) / 2


## The hexes exactly [param radius] steps from [param center], in walking order around the ring.
## Radius 0 is just the center; a negative radius is empty.
static func ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if radius < 0:
		return result
	if radius == 0:
		result.append(center)
		return result
	var hex := center + OFFSETS[Dir.SW] * radius
	for side: int in DIR_COUNT:
		for _step: int in radius:
			result.append(hex)
			hex = neighbor(hex, side)
	return result


## Every hex within [param radius] steps of [param center]: a filled hexagon, center included.
static func disc(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for q: int in range(-radius, radius + 1):
		for r: int in range(maxi(-radius, -q - radius), mini(radius, -q + radius) + 1):
			result.append(center + Vector2i(q, r))
	return result


## The hexes on a straight line from [param from] to [param to], both ends included.
static func line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var steps := distance(from, to)
	var start := Vector2(from) + _LINE_NUDGE
	var end := Vector2(to) + _LINE_NUDGE
	var result: Array[Vector2i] = []
	for i: int in steps + 1:
		var t := 0.0 if steps == 0 else float(i) / steps
		result.append(round_axial(start.lerp(end, t)))
	return result


## [param hex] rotated around [param center] by [param steps] × 60°. Positive steps follow the
## [enum Dir] order (SE → NE → N …), so rotating a neighbor one step gives the next direction's
## neighbor. Used to turn shapes such as area-of-effect patterns toward a target.
static func rotate(hex: Vector2i, center: Vector2i, steps: int) -> Vector2i:
	var v := hex - center
	for _i: int in posmod(steps, DIR_COUNT):
		v = Vector2i(v.x + v.y, -v.x)
	return center + v


## The [enum Dir] from [param from] that points most directly at [param to], e.g. which way a
## unit should face. Exact ties pick the earlier direction. Returns -1 when the hexes are equal.
static func direction_to(from: Vector2i, to: Vector2i) -> int:
	if from == to:
		return -1
	var target := _to_cartesian(to - from)
	var best := 0
	var best_alignment := -INF
	for dir: int in DIR_COUNT:
		# Every step has the same cartesian length, so the dot product alone ranks alignment.
		var alignment := target.dot(_to_cartesian(OFFSETS[dir]))
		if alignment > best_alignment + 1e-9:
			best = dir
			best_alignment = alignment
	return best


## The hex containing the fractional axial position [param axial] (cube rounding).
static func round_axial(axial: Vector2) -> Vector2i:
	var s := -axial.x - axial.y
	var q := roundf(axial.x)
	var r := roundf(axial.y)
	var rounded_s := roundf(s)
	var q_error := absf(q - axial.x)
	var r_error := absf(r - axial.y)
	var s_error := absf(rounded_s - s)
	if q_error > r_error and q_error > s_error:
		q = -r - rounded_s
	elif r_error > s_error:
		r = -q - rounded_s
	return Vector2i(int(q), int(r))


## Axial → "odd-q" offset coordinates (column, row): the visual rows of a flat-top map, where odd
## columns sit half a row lower. Useful for rectangular storage and screen-row logic.
static func to_offset(hex: Vector2i) -> Vector2i:
	return Vector2i(hex.x, hex.y + (hex.x - (hex.x & 1)) / 2)


## "Odd-q" offset coordinates (column, row) → axial. The inverse of [method to_offset].
static func from_offset(cell: Vector2i) -> Vector2i:
	return Vector2i(cell.x, cell.y - (cell.x - (cell.x & 1)) / 2)


## Position on an unsquashed grid of unit-size hexes. Only for comparing angles; use [HexLayout] for pixels.
static func _to_cartesian(hex: Vector2i) -> Vector2:
	return Vector2(1.5 * hex.x, SQRT3 * (hex.y + hex.x * 0.5))
