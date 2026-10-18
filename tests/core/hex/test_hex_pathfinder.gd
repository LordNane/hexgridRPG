extends GutTest

## The test map: step cost of entering each hex. Hexes not listed are off the map.
var _costs: Dictionary[Vector2i, float] = {}


func before_each() -> void:
	_costs.clear()


func test_path_across_open_ground_is_a_straight_line() -> void:
	_fill_disc(5, 1.0)
	var path := HexPathfinder.find_path(Vector2i(-3, 0), Vector2i(3, 0), _step_cost)
	assert_eq(path.size(), 7)
	assert_eq(path[0], Vector2i(-3, 0))
	assert_eq(path[-1], Vector2i(3, 0))
	_assert_contiguous(path)


func test_path_to_the_start_is_just_the_start() -> void:
	_fill_disc(2, 1.0)
	var expected: Array[Vector2i] = [Vector2i(1, 0)]
	assert_eq(HexPathfinder.find_path(Vector2i(1, 0), Vector2i(1, 0), _step_cost), expected)


func test_walled_off_goal_has_no_path() -> void:
	_fill_disc(4, 1.0)
	for hex: Vector2i in Hex.ring(Vector2i.ZERO, 2):
		_costs.erase(hex)
	assert_true(HexPathfinder.find_path(Vector2i(4, 0), Vector2i.ZERO, _step_cost).is_empty())


func test_path_detours_around_expensive_terrain() -> void:
	_fill_disc(4, 1.0)
	for r: int in range(-2, 3):
		_costs[Vector2i(0, r)] = 10.0  # a swamp column through the middle
	var path := HexPathfinder.find_path(Vector2i(-2, 1), Vector2i(2, -1), _step_cost)
	assert_eq(path[-1], Vector2i(2, -1))
	assert_true(_path_cost(path) < 10.0, "goes around the swamp (cost %s)" % _path_cost(path))


func test_find_path_is_as_cheap_as_exhaustive_search_on_random_maps() -> void:
	var rng := SeededRng.new(1234)
	for trial: int in 25:
		_random_map(rng, 6, [1.0, 2.0, 3.0, 4.0])
		_assert_optimal(rng, 1.0, trial)


func test_min_step_cost_keeps_cheap_roads_optimal() -> void:
	var rng := SeededRng.new(99)
	for trial: int in 25:
		_random_map(rng, 6, [0.5, 1.0, 2.0])
		_assert_optimal(rng, 0.5, trial)


func test_reachable_with_uniform_cost_is_a_disc() -> void:
	_fill_disc(6, 1.0)
	var reach := HexPathfinder.reachable(Vector2i.ZERO, 3.0, _step_cost)
	assert_eq(reach.hexes().size(), Hex.disc(Vector2i.ZERO, 3).size())
	assert_true(reach.has(Vector2i(3, 0)))
	assert_false(reach.has(Vector2i(4, 0)))
	assert_eq(reach.cost_to(Vector2i(4, 0)), INF)
	assert_true(reach.path_to(Vector2i(4, 0)).is_empty())


func test_reachable_respects_the_budget_and_paths_add_up() -> void:
	var rng := SeededRng.new(7)
	_random_map(rng, 6, [1.0, 2.0, 3.0])
	var start: Vector2i = rng.pick(_costs.keys())
	var reach := HexPathfinder.reachable(start, 5.0, _step_cost)
	assert_eq(reach.origin, start)
	assert_eq(reach.cost_to(start), 0.0)
	for hex: Vector2i in reach.hexes():
		var path := reach.path_to(hex)
		assert_true(reach.cost_to(hex) <= 5.0)
		assert_eq(path[0], start)
		assert_eq(path[-1], hex)
		_assert_contiguous(path)
		assert_almost_eq(_path_cost(path), reach.cost_to(hex), 0.0001)


func test_impassable_hexes_are_never_entered() -> void:
	_fill_disc(3, 1.0)
	_costs[Vector2i(0, 0)] = INF
	var reach := HexPathfinder.reachable(Vector2i(-2, 0), 10.0, _step_cost)
	assert_false(reach.has(Vector2i(0, 0)))
	var path := HexPathfinder.find_path(Vector2i(-2, 0), Vector2i(2, 0), _step_cost)
	assert_false(path.has(Vector2i(0, 0)))


func _step_cost(_from: Vector2i, to: Vector2i) -> float:
	return _costs.get(to, INF)


func _fill_disc(radius: int, cost: float) -> void:
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, radius):
		_costs[hex] = cost


## A random map with holes, using step costs drawn from [param costs].
func _random_map(rng: SeededRng, radius: int, costs: Array[float]) -> void:
	_costs.clear()
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, radius):
		if not rng.chance(0.15):
			_costs[hex] = rng.pick(costs)


## A* must find a path exactly as cheap as Dijkstra exploring the whole map.
func _assert_optimal(rng: SeededRng, min_step_cost: float, trial: int) -> void:
	var hexes: Array = _costs.keys()
	var start: Vector2i = rng.pick(hexes)
	var goal: Vector2i = rng.pick(hexes)
	var path := HexPathfinder.find_path(start, goal, _step_cost, min_step_cost)
	var exhaustive := HexPathfinder.reachable(start, INF, _step_cost)
	if exhaustive.has(goal):
		assert_almost_eq(_path_cost(path), exhaustive.cost_to(goal), 0.0001, "trial %d" % trial)
		_assert_contiguous(path)
	else:
		assert_true(path.is_empty(), "trial %d: unreachable goal" % trial)


func _path_cost(path: Array[Vector2i]) -> float:
	var total := 0.0
	for i: int in range(1, path.size()):
		total += _step_cost(path[i - 1], path[i])
	return total


func _assert_contiguous(path: Array[Vector2i]) -> void:
	for i: int in range(1, path.size()):
		assert_eq(Hex.distance(path[i - 1], path[i]), 1, "step %d of the path" % i)
