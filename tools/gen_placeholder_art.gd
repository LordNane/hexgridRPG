extends SceneTree
## Generates placeholder pixel art so development isn't blocked on real art. Tile sizes come from
## HexLayout's defaults, so re-run this after changing them, then re-run gen_placeholder_tilesets.gd:
## [codeblock]
## godot --headless --path . -s res://tools/gen_placeholder_art.gd
## [/codeblock]
## Writes to res://assets/tilesets/placeholder/:
## - terrain_tops.png   one hex top face per terrain (rows), in TOP_VARIANTS variants (columns)
## - cliff_faces.png    one elevation level of cliff per terrain (rows), aligned with the top faces
## - height_digits.png  hex tops labelled 0–9, for painting arena heights
## - features.png       forest, hills and mountains (rows) standing on a hex, in 2 variants (columns)
## - regions.png        translucent tints for painting regions
## - fog.png            fog over unexplored hexes, then fog over remembered ones
## - preview_x4.png     a small stacked arena at 4× zoom, to judge the hex size and elevation step
## and to res://assets/sprites/placeholder/: party_token.png and poi/<name>.png icons.

const TILESET_DIR := "res://assets/tilesets/placeholder/"
const SPRITE_DIR := "res://assets/sprites/placeholder/"
const TOP_VARIANTS := 4
const FEATURE_VARIANTS := 2
const SEED := 2026
const PREVIEW_ZOOM := 4

## Placeholder terrains: name → [top color, cliff color]. Rows appear in this order in each sheet.
const TERRAINS := {
	"grass": [Color("5a9a4a"), Color("6b4f3a")],
	"dirt": [Color("8a6a46"), Color("5e4630")],
	"stone": [Color("80828c"), Color("5b5d66")],
	"sand": [Color("c8b47a"), Color("9a8456")],
	"water": [Color("3a6ab0"), Color("2a4c80")],
	"snow": [Color("dfe6ee"), Color("9fb0c0")],
	"swamp": [Color("4f6a3c"), Color("3c3a2a")],
}

## Feature rows in features.png.
const FEATURES: Array[String] = ["forest", "hills", "mountains"]

const REGION_TINTS: Array[Color] = [
	Color("ff6a5a"), Color("5ab0ff"), Color("7aff6a"), Color("ffd84a"), Color("c87aff"), Color("5affe0")]

const FOG_COLOR := Color("0d151c")
const FOG_REMEMBERED_ALPHA := 0.55
const OUTLINE := Color("1a1620")

## 3×5 pixel digits, row by row.
const DIGITS: Array[String] = [
	"111101101101111", "010110010010111", "111001111100111", "111001111001111", "101101111001001",
	"111100111001111", "111100111101111", "111001001001001", "111101111101111", "111101111001111",
]

var _layout := HexLayout.new()
var _cell := _layout.cell_size
var _step := _layout.elevation_step


func _init() -> void:
	var outputs: Dictionary[String, Image] = {}
	_add_terrain_sheets(outputs)
	outputs[TILESET_DIR + "height_digits.png"] = _height_digits()
	outputs[TILESET_DIR + "features.png"] = _feature_sheet()
	outputs[TILESET_DIR + "regions.png"] = _region_sheet()
	outputs[TILESET_DIR + "fog.png"] = _fog_sheet()
	outputs[SPRITE_DIR + "party_token.png"] = _party_token()
	var icons: Dictionary[String, Callable] = {
		"chest": _icon_chest.bind(false), "chest_open": _icon_chest.bind(true), "shrine": _icon_shrine,
		"stones": _icon_stones, "sign": _icon_sign, "cave": _icon_cave, "tower": _icon_tower,
	}
	for icon_name: String in icons:
		outputs[SPRITE_DIR + "poi/%s.png" % icon_name] = icons[icon_name].call()
	var failures := 0
	for path: String in outputs:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
		var image := outputs[path]
		var error := image.save_png(path)
		print("%s %s (%dx%d)" % ["wrote" if error == OK else "FAILED", path, image.get_width(), image.get_height()])
		failures += 1 if error != OK else 0
	quit(1 if failures > 0 else 0)


# --- Hex shapes -------------------------------------------------------------------------------


## Whether the pixel at ([param x], [param y]) is inside a top face whose box starts at (0, 0).
## Edges on the left are inside and edges on the right are outside, so neighboring hexes tile
## the plane with no gaps or overlaps.
func _in_top(x: int, y: int) -> bool:
	var px := x + 0.5
	var py := y + 0.5
	var w := float(_cell.x)
	var h := float(_cell.y)
	var slope := 2.0 * h / w
	return py > 0.0 and py < h \
			and py >= h / 2.0 - slope * px \
			and py <= h / 2.0 + slope * px \
			and py > slope * (px - 0.75 * w) \
			and py < h / 2.0 - slope * (px - w)


## Whether the pixel is in the band of cliff one elevation level tall hanging under the top face.
func _in_cliff(x: int, y: int) -> bool:
	if _in_top(x, y):
		return false
	for drop: int in range(1, _step + 1):
		if _in_top(x, y - drop):
			return true
	return false


## A hex top face filled with [param color], with a lighter top edge if [param bevel] is on.
func _flat_hex(color: Color, bevel: bool = false) -> Image:
	var image := Image.create_empty(_cell.x, _cell.y, false, Image.FORMAT_RGBA8)
	for y: int in _cell.y:
		for x: int in _cell.x:
			if _in_top(x, y):
				image.set_pixel(x, y, color.lightened(0.15) if bevel and not _in_top(x, y - 1) else color)
	return image


# --- Terrain ----------------------------------------------------------------------------------


func _add_terrain_sheets(outputs: Dictionary[String, Image]) -> void:
	var names: Array = TERRAINS.keys()
	var tops := Image.create_empty(_cell.x * TOP_VARIANTS, _cell.y * names.size(), false, Image.FORMAT_RGBA8)
	var cliffs := Image.create_empty(_cell.x, (_cell.y + _step) * names.size(), false, Image.FORMAT_RGBA8)
	var top_tiles: Dictionary[String, Image] = {}
	var cliff_tiles: Dictionary[String, Image] = {}
	for row: int in names.size():
		var terrain: String = names[row]
		var colors: Array = TERRAINS[terrain]
		for variant: int in TOP_VARIANTS:
			var tile := _top_tile(colors[0], SEED + row * 31 + variant)
			_blit(tops, tile, Vector2i(variant * _cell.x, row * _cell.y))
			if variant == 0:
				top_tiles[terrain] = tile
		cliff_tiles[terrain] = _cliff_tile(colors[1], SEED + row)
		_blit(cliffs, cliff_tiles[terrain], Vector2i(0, row * (_cell.y + _step)))
	var preview := _preview(top_tiles, cliff_tiles)
	preview.resize(preview.get_width() * PREVIEW_ZOOM, preview.get_height() * PREVIEW_ZOOM, Image.INTERPOLATE_NEAREST)
	outputs[TILESET_DIR + "terrain_tops.png"] = tops
	outputs[TILESET_DIR + "cliff_faces.png"] = cliffs
	outputs[TILESET_DIR + "preview_x4.png"] = preview


## A hex top face: dithered base color, lit top edge, shaded bottom edge.
func _top_tile(base: Color, seed_value: int) -> Image:
	var rng := SeededRng.new(seed_value)
	var image := Image.create_empty(_cell.x, _cell.y, false, Image.FORMAT_RGBA8)
	for y: int in _cell.y:
		for x: int in _cell.x:
			if not _in_top(x, y):
				continue
			var color := base
			var speckle := rng.randf()
			if speckle < 0.12:
				color = base.darkened(0.1)
			elif speckle < 0.2:
				color = base.lightened(0.08)
			if not _in_top(x, y - 1):
				color = base.lightened(0.2)
			elif not _in_top(x, y + 1):
				color = base.darkened(0.25)
			image.set_pixel(x, y, color)
	return image


## One elevation level of cliff: left, front and right faces shaded for light from the upper left,
## with a darker strata line at the bottom so stacked levels can be counted.
func _cliff_tile(base: Color, seed_value: int) -> Image:
	var rng := SeededRng.new(seed_value)
	var image := Image.create_empty(_cell.x, _cell.y + _step, false, Image.FORMAT_RGBA8)
	for y: int in _cell.y + _step:
		for x: int in _cell.x:
			if not _in_cliff(x, y):
				continue
			var face := 0.0 if x < _cell.x / 4 else (0.15 if x < _cell.x * 3 / 4 else 0.3)
			var color := base.darkened(face)
			if not _in_cliff(x, y + 1):
				color = color.darkened(0.3)
			elif rng.randf() < 0.1:
				color = color.darkened(0.12)
			image.set_pixel(x, y, color)
	return image


## A small hill of stacked hexes, drawn back to front the way the battle view will draw arenas.
func _preview(top_tiles: Dictionary[String, Image], cliff_tiles: Dictionary[String, Image]) -> Image:
	var heights: Dictionary[Vector2i, int] = {}
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, 3):
		heights[hex] = maxi(0, 3 - Hex.distance(hex, Vector2i(1, -1)))
	var order: Array[Vector2i] = []
	order.assign(heights.keys())
	order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var ay := _layout.to_pixel(a).y
		var by := _layout.to_pixel(b).y
		return ay < by or (ay == by and a.x < b.x))
	var bounds := Rect2i()
	for hex: Vector2i in order:
		var tile_rect := Rect2i(_tile_origin(hex, heights[hex]), Vector2i(_cell.x, _cell.y + _step * heights[hex]))
		bounds = tile_rect if bounds.size == Vector2i.ZERO else bounds.merge(tile_rect)
	bounds = bounds.grow(4)
	var image := Image.create_empty(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color("1d2b36"))
	for hex: Vector2i in order:
		var height := heights[hex]
		var terrain := "stone" if height >= 3 else ("grass" if height >= 1 else ("water" if hex.x + hex.y > 1 else "dirt"))
		var at := _tile_origin(hex, height) - bounds.position
		for level: int in height:
			_blit(image, cliff_tiles[terrain], at + Vector2i(0, _step * level))
		_blit(image, top_tiles[terrain], at)
	return image


## Top-left pixel of the top-face image for [param hex] raised [param height] levels.
func _tile_origin(hex: Vector2i, height: int) -> Vector2i:
	return Vector2i(_layout.to_pixel(hex) + _layout.elevation_offset(height)) - _cell / 2


## Hex tops tinted by height (dark = low) with the height number in the middle.
func _height_digits() -> Image:
	var sheet := Image.create_empty(_cell.x * DIGITS.size(), _cell.y, false, Image.FORMAT_RGBA8)
	for height: int in DIGITS.size():
		var base := Color("2e3b4e").lerp(Color("c9d6e3"), height / 9.0)
		var tile := _flat_hex(base, true)
		var ink := Color.WHITE if base.get_luminance() < 0.5 else Color("1a1a1a")
		var glyph := DIGITS[height]
		var corner := Vector2i(_cell.x / 2 - 1, _cell.y / 2 - 2)
		for i: int in glyph.length():
			if glyph[i] == "1":
				tile.set_pixelv(corner + Vector2i(i % 3, i / 3), ink)
		_blit(sheet, tile, Vector2i(height * _cell.x, 0))
	return sheet


# --- Overworld features, regions, fog -------------------------------------------------------


## Features stand on a hex: each tile is a hex wide and two tall, its hex footprint in the bottom half.
func _feature_sheet() -> Image:
	var size := Vector2i(_cell.x, _cell.y * 2)
	var sheet := Image.create_empty(size.x * FEATURE_VARIANTS, size.y * FEATURES.size(), false, Image.FORMAT_RGBA8)
	var painters: Array[Callable] = [_paint_forest, _paint_hills, _paint_mountains]
	for row: int in FEATURES.size():
		for variant: int in FEATURE_VARIANTS:
			var tile := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
			painters[row].call(tile, variant)
			_outline(tile, OUTLINE)
			_blit(sheet, tile, Vector2i(variant * size.x, row * size.y))
	return sheet


func _paint_forest(image: Image, variant: int) -> void:
	# Each tree is (base x, base y, height), listed back to front.
	var trees: Array[Vector3i] = [Vector3i(10, 25, 11), Vector3i(22, 25, 12), Vector3i(16, 30, 10)]
	if variant == 1:
		trees = [Vector3i(17, 23, 13), Vector3i(9, 28, 10), Vector3i(24, 29, 10)]
	for tree: Vector3i in trees:
		var base := Vector2(tree.x, tree.y)
		var top := base - Vector2(0, tree.z)
		var half_width := tree.z * 0.38
		_fill_rect(image, Rect2i(tree.x, tree.y - 2, 1, 3), Color("5a3a24"))
		_fill_triangle(image, top, base + Vector2(-half_width, -2), base + Vector2(half_width + 1, -2), Color("2e6b34"))
		_fill_triangle(image, top, base + Vector2(-half_width, -2), base + Vector2(0.5, -2), Color("4a9a4a"))


func _paint_hills(image: Image, variant: int) -> void:
	# Each mound is (center, radius), listed back to front.
	var mounds: Array[Rect2] = [Rect2(11, 27, 8, 6), Rect2(21, 25, 9, 7)]
	if variant == 1:
		mounds = [Rect2(12, 24, 8, 7), Rect2(20, 28, 9, 6)]
	for mound: Rect2 in mounds:
		var center := mound.position
		var radius := mound.size
		_fill_ellipse(image, center, radius, Color("8a9a52"), center.y + 1)
		_fill_ellipse(image, center - Vector2(radius.x * 0.3, radius.y * 0.35), radius * 0.45, Color("a8b86a"), center.y)


func _paint_mountains(image: Image, variant: int) -> void:
	# Each peak is (apex x, apex y, half the base width), listed back to front.
	var peaks: Array[Vector3] = [Vector3(16, 3, 13)]
	if variant == 1:
		peaks = [Vector3(21, 5, 11), Vector3(11, 9, 10)]
	for peak: Vector3 in peaks:
		var apex := Vector2(peak.x, peak.y)
		var left := Vector2(peak.x - peak.z, 29)
		var right := Vector2(peak.x + peak.z, 29)
		var middle := Vector2(peak.x + 0.5, 29)
		_fill_triangle(image, apex, middle, right, Color("74747f"))
		_fill_triangle(image, apex, left, middle, Color("a0a0ac"))
		var snow_line := peak.y + (29 - peak.y) * 0.3
		for y: int in range(int(peak.y), int(snow_line)):
			for x: int in range(maxi(0, int(left.x)), mini(image.get_width(), int(right.x) + 1)):
				if image.get_pixel(x, y).a > 0.5:
					image.set_pixel(x, y, Color("eef2f6") if x <= peak.x else Color("c8d0d8"))


func _region_sheet() -> Image:
	var sheet := Image.create_empty(_cell.x * REGION_TINTS.size(), _cell.y, false, Image.FORMAT_RGBA8)
	for i: int in REGION_TINTS.size():
		var tint := REGION_TINTS[i]
		var tile := _flat_hex(Color(tint, 0.35))
		for y: int in _cell.y:
			for x: int in _cell.x:
				if _in_top(x, y) and not (_in_top(x - 1, y) and _in_top(x + 1, y) and _in_top(x, y - 1) and _in_top(x, y + 1)):
					tile.set_pixel(x, y, Color(tint, 0.8))
		_blit(sheet, tile, Vector2i(i * _cell.x, 0))
	return sheet


func _fog_sheet() -> Image:
	var sheet := Image.create_empty(_cell.x * 2, _cell.y, false, Image.FORMAT_RGBA8)
	_blit(sheet, _flat_hex(FOG_COLOR), Vector2i.ZERO)
	_blit(sheet, _flat_hex(Color(FOG_COLOR, FOG_REMEMBERED_ALPHA)), Vector2i(_cell.x, 0))
	return sheet


# --- Sprites ----------------------------------------------------------------------------------


## A little adventurer, feet at the bottom center, with a soft shadow.
func _party_token() -> Image:
	var image := Image.create_empty(16, 24, false, Image.FORMAT_RGBA8)
	_fill_rect(image, Rect2i(6, 17, 2, 5), Color("3a3048"))
	_fill_rect(image, Rect2i(9, 17, 2, 5), Color("3a3048"))
	for y: int in range(9, 18):
		var inset := 1 if y < 12 else 0
		_fill_rect(image, Rect2i(4 + inset, y, 9 - inset * 2, 1), Color("c84a3a"))
		_fill_rect(image, Rect2i(4 + inset, y, 2, 1), Color("e06a50"))
	_fill_rect(image, Rect2i(6, 4, 5, 5), Color("f0c8a0"))
	_fill_rect(image, Rect2i(6, 3, 5, 2), Color("5a3a2a"))
	_fill_rect(image, Rect2i(6, 4, 1, 2), Color("5a3a2a"))
	image.set_pixel(7, 6, Color("2a2030"))
	image.set_pixel(9, 6, Color("2a2030"))
	_outline(image, OUTLINE)
	_fill_ellipse(image, Vector2(8.5, 22.5), Vector2(5, 1.6), Color(0, 0, 0, 0.35), 99.0, true)
	return image


func _icon_chest(open: bool) -> Image:
	var image := _icon()
	if open:
		_fill_rect(image, Rect2i(3, 3, 10, 4), Color("a8703a"))
		_fill_rect(image, Rect2i(4, 6, 8, 2), Color("3a2410"))
		image.set_pixel(6, 6, Color("ffd84a"))
		image.set_pixel(9, 7, Color("ffd84a"))
	else:
		_fill_rect(image, Rect2i(3, 6, 10, 3), Color("a8703a"))
	_fill_rect(image, Rect2i(3, 8, 10, 6), Color("8a5a2e"))
	_fill_rect(image, Rect2i(3, 8, 10, 1), Color("6a4020"))
	_fill_rect(image, Rect2i(7, 9, 2, 2), Color("e8c040"))
	return _finish_icon(image)


func _icon_shrine() -> Image:
	var image := _icon()
	_fill_rect(image, Rect2i(3, 11, 10, 3), Color("8a8a96"))
	_fill_rect(image, Rect2i(6, 6, 4, 5), Color("a0a0ac"))
	_fill_ellipse(image, Vector2(8, 4), Vector2(2.5, 2.5), Color("6ad0ff"))
	image.set_pixel(7, 3, Color("e0f6ff"))
	return _finish_icon(image)


func _icon_stones() -> Image:
	var image := _icon()
	for stone: Rect2i in [Rect2i(2, 7, 3, 7), Rect2i(7, 3, 3, 11), Rect2i(12, 6, 3, 8)]:
		_fill_rect(image, stone, Color("7a7a86"))
		_fill_rect(image, Rect2i(stone.position, Vector2i(1, stone.size.y)), Color("a0a0ac"))
	return _finish_icon(image)


func _icon_sign() -> Image:
	var image := _icon()
	_fill_rect(image, Rect2i(7, 7, 2, 7), Color("6a4a2a"))
	_fill_rect(image, Rect2i(2, 2, 12, 6), Color("b08850"))
	_fill_rect(image, Rect2i(4, 4, 8, 1), Color("7a5a30"))
	_fill_rect(image, Rect2i(4, 6, 5, 1), Color("7a5a30"))
	return _finish_icon(image)


func _icon_cave() -> Image:
	var image := _icon()
	_fill_ellipse(image, Vector2(8, 13), Vector2(7.5, 9), Color("7a7a84"), 13.5)
	_fill_ellipse(image, Vector2(6, 8), Vector2(3, 3), Color("9a9aa4"), 13.5)
	_fill_ellipse(image, Vector2(8.5, 13.5), Vector2(3, 4), Color("141418"), 13.5)
	return _finish_icon(image)


func _icon_tower() -> Image:
	var image := _icon()
	_fill_rect(image, Rect2i(4, 4, 8, 10), Color("9a9aa6"))
	_fill_rect(image, Rect2i(4, 4, 2, 10), Color("b4b4c0"))
	for x: int in [4, 7, 10]:
		_fill_rect(image, Rect2i(x, 2, 2, 2), Color("9a9aa6"))
	_fill_rect(image, Rect2i(7, 6, 2, 3), Color("2a2a34"))
	_fill_rect(image, Rect2i(6, 10, 4, 4), Color("5a3a24"))
	return _finish_icon(image)


func _icon() -> Image:
	return Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)


func _finish_icon(image: Image) -> Image:
	_outline(image, OUTLINE)
	return image


# --- Drawing helpers --------------------------------------------------------------------------


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect.intersection(Rect2i(Vector2i.ZERO, image.get_size())), color)


## Fills the triangle [param a] [param b] [param c] (pixel centers inside it).
func _fill_triangle(image: Image, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	var area := (b - a).cross(c - a)
	if is_zero_approx(area):
		return
	for y: int in image.get_height():
		for x: int in image.get_width():
			var p := Vector2(x + 0.5, y + 0.5)
			var u := (b - p).cross(c - p) / area
			var v := (c - p).cross(a - p) / area
			if u >= 0.0 and v >= 0.0 and u + v <= 1.0:
				image.set_pixel(x, y, color)


## Fills an ellipse down to [param max_y], so mounds can be cut flat at the bottom. With
## [param under] set it only paints transparent pixels, for shadows beneath a figure.
func _fill_ellipse(image: Image, center: Vector2, radius: Vector2, color: Color, max_y: float = 9999.0, under: bool = false) -> void:
	for y: int in image.get_height():
		for x: int in image.get_width():
			var p := Vector2(x + 0.5, y + 0.5)
			var d := (p - center) / radius
			if d.length_squared() <= 1.0 and p.y <= max_y and (not under or image.get_pixel(x, y).a == 0.0):
				image.set_pixel(x, y, color)


## Draws a one-pixel [param color] outline around everything drawn so far.
func _outline(image: Image, color: Color) -> void:
	var source := image.duplicate() as Image
	for y: int in image.get_height():
		for x: int in image.get_width():
			if source.get_pixel(x, y).a > 0.0:
				continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n := Vector2i(x, y) + offset
				if Rect2i(Vector2i.ZERO, image.get_size()).has_point(n) and source.get_pixelv(n).a > 0.5:
					image.set_pixel(x, y, color)
					break


func _blit(target: Image, source: Image, at: Vector2i) -> void:
	target.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), at)
