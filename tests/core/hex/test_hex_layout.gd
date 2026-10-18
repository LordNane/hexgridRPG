extends GutTest

var _layout: HexLayout


func before_each() -> void:
	_layout = HexLayout.new()


func test_hex_zero_is_at_the_origin() -> void:
	_layout.origin = Vector2(100, 50)
	assert_eq(_layout.to_pixel(Vector2i.ZERO), Vector2(100, 50))


func test_neighbor_spacing_follows_the_cell_size() -> void:
	# 32×16 cells: columns 24 px apart, rows 16 px apart, each column half a row lower than the last.
	assert_eq(_layout.to_pixel(Vector2i(0, 1)), Vector2(0, 16))
	assert_eq(_layout.to_pixel(Vector2i(1, 0)), Vector2(24, 8))
	assert_eq(_layout.to_pixel(Vector2i(1, -1)), Vector2(24, -8))


func test_hex_centers_land_on_whole_pixels() -> void:
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, 8):
		var center := _layout.to_pixel(hex)
		assert_eq(center, center.round(), "center of %s" % hex)


func test_to_hex_inverts_to_pixel() -> void:
	_layout.origin = Vector2(320, 180)
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, 10):
		assert_eq(_layout.to_hex(_layout.to_pixel(hex)), hex)


func test_points_just_inside_each_corner_belong_to_the_hex() -> void:
	for hex: Vector2i in [Vector2i.ZERO, Vector2i(3, -2), Vector2i(-4, 1)]:
		var center := _layout.to_pixel(hex)
		for corner: Vector2 in _layout.corners(hex):
			assert_eq(_layout.to_hex(center.lerp(corner, 0.95)), hex, "near corner %s of %s" % [corner, hex])


func test_corners_span_exactly_one_cell() -> void:
	var corners := _layout.corners(Vector2i(2, 3))
	assert_eq(corners.size(), 6)
	var bounds := Rect2(corners[0], Vector2.ZERO)
	for corner: Vector2 in corners:
		bounds = bounds.expand(corner)
	assert_eq(bounds.size, Vector2(_layout.cell_size))
	assert_eq(bounds.get_center(), _layout.to_pixel(Vector2i(2, 3)))


func test_elevation_raises_things_up_the_screen() -> void:
	assert_eq(_layout.elevation_offset(0), Vector2.ZERO)
	assert_eq(_layout.elevation_offset(3), Vector2(0, -3 * _layout.elevation_step))


func test_neighbor_toward_up_and_down_is_north_and_south() -> void:
	var hex := Vector2i(2, 1)
	assert_eq(_layout.neighbor_toward(hex, Vector2.UP), Hex.neighbor(hex, Hex.Dir.N))
	assert_eq(_layout.neighbor_toward(hex, Vector2.DOWN), Hex.neighbor(hex, Hex.Dir.S))


func test_neighbor_toward_diagonals() -> void:
	var hex := Vector2i(1, 1)
	assert_eq(_layout.neighbor_toward(hex, Vector2(1, -1)), Hex.neighbor(hex, Hex.Dir.NE))
	assert_eq(_layout.neighbor_toward(hex, Vector2(-1, 1)), Hex.neighbor(hex, Hex.Dir.SW))


func test_neighbor_toward_left_and_right_stays_on_the_visual_row() -> void:
	var hex := Vector2i(0, 0)
	var row := Hex.to_offset(hex).y
	for step: int in 6:
		hex = _layout.neighbor_toward(hex, Vector2.RIGHT)
		assert_eq(hex.x, step + 1, "moved one column right")
		assert_eq(Hex.to_offset(hex).y, row, "stayed on row %d" % row)
	for _step: int in 6:
		hex = _layout.neighbor_toward(hex, Vector2.LEFT)
		assert_eq(Hex.to_offset(hex).y, row)
	assert_eq(hex, Vector2i.ZERO, "walking back left returns to the start")


func test_neighbor_toward_nowhere_stays_put() -> void:
	assert_eq(_layout.neighbor_toward(Vector2i(4, -2), Vector2.ZERO), Vector2i(4, -2))


func test_tilemap_coordinates_are_axial() -> void:
	# The TileSet setup maps are painted with must use the same coordinates and spacing as HexLayout.
	var tile_set := TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	tile_set.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	tile_set.tile_layout = TileSet.TILE_LAYOUT_STAIRS_DOWN
	tile_set.tile_size = _layout.cell_size
	var tile_map: TileMapLayer = autofree(TileMapLayer.new())
	tile_map.tile_set = tile_set
	var tile_origin := tile_map.map_to_local(Vector2i.ZERO)
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, 6):
		assert_eq(tile_map.map_to_local(hex) - tile_origin, _layout.to_pixel(hex), "position of %s" % hex)
		assert_eq(tile_map.local_to_map(tile_origin + _layout.to_pixel(hex)), hex, "lookup of %s" % hex)
	for dir: int in Hex.DIR_COUNT:
		var neighbor := Hex.neighbor(Vector2i.ZERO, dir)
		assert_true(tile_map.get_surrounding_cells(Vector2i.ZERO).has(neighbor), "Godot agrees %s is a neighbor" % neighbor)
