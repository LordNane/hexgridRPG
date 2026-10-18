extends GutTest

const CENTER := Vector2i(2, -1)


func test_neighbors_are_one_step_away_in_every_direction() -> void:
	var neighbors := Hex.neighbors(CENTER)
	assert_eq(neighbors.size(), Hex.DIR_COUNT)
	for dir: int in Hex.DIR_COUNT:
		assert_eq(neighbors[dir], Hex.neighbor(CENTER, dir))
		assert_eq(Hex.distance(CENTER, neighbors[dir]), 1)


func test_neighbor_directions_wrap() -> void:
	assert_eq(Hex.neighbor(CENTER, Hex.DIR_COUNT), Hex.neighbor(CENTER, Hex.Dir.SE))
	assert_eq(Hex.neighbor(CENTER, -1), Hex.neighbor(CENTER, Hex.Dir.S))


func test_distance_matches_known_values_and_is_symmetric() -> void:
	assert_eq(Hex.distance(Vector2i(0, 0), Vector2i(0, 0)), 0)
	assert_eq(Hex.distance(Vector2i(0, 0), Vector2i(3, 0)), 3)
	assert_eq(Hex.distance(Vector2i(0, 0), Vector2i(2, -3)), 3)
	assert_eq(Hex.distance(Vector2i(-2, 4), Vector2i(1, -1)), 5)
	assert_eq(Hex.distance(Vector2i(1, -1), Vector2i(-2, 4)), 5)


func test_ring_is_a_closed_loop_of_six_times_radius_hexes() -> void:
	for radius: int in range(1, 6):
		var ring := Hex.ring(CENTER, radius)
		assert_eq(ring.size(), 6 * radius, "ring size at radius %d" % radius)
		assert_eq(_unique_count(ring), ring.size(), "ring hexes are unique")
		for i: int in ring.size():
			assert_eq(Hex.distance(CENTER, ring[i]), radius)
			assert_eq(Hex.distance(ring[i], ring[(i + 1) % ring.size()]), 1, "ring steps are adjacent")


func test_ring_of_radius_zero_is_the_center_and_negative_is_empty() -> void:
	var expected: Array[Vector2i] = [CENTER]
	assert_eq(Hex.ring(CENTER, 0), expected)
	assert_true(Hex.ring(CENTER, -1).is_empty())


func test_disc_holds_every_hex_within_radius_exactly_once() -> void:
	for radius: int in range(0, 6):
		var disc := Hex.disc(CENTER, radius)
		assert_eq(disc.size(), 3 * radius * (radius + 1) + 1, "disc size at radius %d" % radius)
		assert_eq(_unique_count(disc), disc.size(), "disc hexes are unique")
		for hex: Vector2i in disc:
			assert_true(Hex.distance(CENTER, hex) <= radius)


func test_disc_is_the_union_of_its_rings() -> void:
	var from_rings: Array[Vector2i] = []
	for radius: int in range(0, 4):
		from_rings.append_array(Hex.ring(CENTER, radius))
	var disc := Hex.disc(CENTER, 3)
	from_rings.sort()
	disc.sort()
	assert_eq(from_rings, disc)


func test_line_runs_end_to_end_through_adjacent_hexes() -> void:
	var from := Vector2i(-3, 1)
	var to := Vector2i(4, -2)
	var line := Hex.line(from, to)
	assert_eq(line.size(), Hex.distance(from, to) + 1)
	assert_eq(line[0], from)
	assert_eq(line[-1], to)
	for i: int in range(1, line.size()):
		assert_eq(Hex.distance(line[i - 1], line[i]), 1)


func test_line_along_an_axis_is_straight() -> void:
	var expected: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]
	assert_eq(Hex.line(Vector2i(0, 0), Vector2i(0, 3)), expected)


func test_line_to_itself_is_one_hex() -> void:
	var expected: Array[Vector2i] = [CENTER]
	assert_eq(Hex.line(CENTER, CENTER), expected)


func test_rotating_a_neighbor_one_step_gives_the_next_direction() -> void:
	for dir: int in Hex.DIR_COUNT:
		assert_eq(Hex.rotate(Hex.neighbor(CENTER, dir), CENTER, 1), Hex.neighbor(CENTER, dir + 1))


func test_rotation_preserves_distance_and_six_steps_is_identity() -> void:
	var hex := Vector2i(5, -2)
	for steps: int in range(-6, 7):
		var rotated := Hex.rotate(hex, CENTER, steps)
		assert_eq(Hex.distance(CENTER, rotated), Hex.distance(CENTER, hex))
		assert_eq(Hex.rotate(rotated, CENTER, -steps), hex, "rotating back undoes %d steps" % steps)
	assert_eq(Hex.rotate(hex, CENTER, 6), hex)


func test_direction_to_a_neighbor_is_its_direction() -> void:
	for dir: int in Hex.DIR_COUNT:
		assert_eq(Hex.direction_to(CENTER, Hex.neighbor(CENTER, dir)), dir)


func test_direction_to_a_distant_hex() -> void:
	assert_eq(Hex.direction_to(Vector2i.ZERO, Vector2i(0, -5)), Hex.Dir.N)
	assert_eq(Hex.direction_to(Vector2i.ZERO, Vector2i(4, 0)), Hex.Dir.SE)
	assert_eq(Hex.direction_to(Vector2i.ZERO, Vector2i(-1, 4)), Hex.Dir.S)
	assert_eq(Hex.direction_to(Vector2i.ZERO, Vector2i(-3, 4)), Hex.Dir.SW)
	assert_eq(Hex.direction_to(CENTER, CENTER), -1)


func test_round_axial_finds_the_containing_hex() -> void:
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, 5):
		assert_eq(Hex.round_axial(Vector2(hex)), hex)
	assert_eq(Hex.round_axial(Vector2(0.2, 0.1)), Vector2i(0, 0))
	assert_eq(Hex.round_axial(Vector2(0.8, -0.1)), Vector2i(1, 0))
	assert_eq(Hex.round_axial(Vector2(-0.1, -0.8)), Vector2i(0, -1))


func test_offset_coordinates_round_trip() -> void:
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, 7):
		assert_eq(Hex.from_offset(Hex.to_offset(hex)), hex)


func test_an_offset_row_is_a_horizontal_zigzag() -> void:
	for hex: Vector2i in [Vector2i(-2, 1), Vector2i(-1, 1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, -1), Vector2i(3, -1)]:
		assert_eq(Hex.to_offset(hex).y, 0, "hex %s is on row 0" % hex)


func _unique_count(hexes: Array[Vector2i]) -> int:
	var seen: Dictionary[Vector2i, bool] = {}
	for hex: Vector2i in hexes:
		seen[hex] = true
	return seen.size()
