extends GutTest

var _session: GameSession
var _map: ExploreMap


func before_each() -> void:
	_session = GameSession.new(1)
	_map = FakeContent.uniform_map(5, FakeContent.terrain(&"grass"))


func test_route_walks_around_water() -> void:
	var water := FakeContent.terrain(&"water", 1.0, false)
	for r: int in range(-2, 3):
		_map.set_terrain(Vector2i(1, r), water)
	var exploration := Exploration.new(_session, _map, Vector2i.ZERO, false)
	var route := exploration.route_to(Vector2i(2, 0))
	assert_eq(route[0], Vector2i.ZERO)
	assert_eq(route[-1], Vector2i(2, 0))
	for hex: Vector2i in route:
		assert_true(_map.terrain_at(hex).passable, "%s is dry" % hex)


func test_route_to_a_blocking_poi_ends_next_to_it() -> void:
	var sign_post := FakeContent.poi(&"sign", [FakeContent.message("North")])
	sign_post.blocks_movement = true
	_map.set_poi(Vector2i(3, 0), sign_post)
	var exploration := Exploration.new(_session, _map, Vector2i.ZERO, false)
	var route := exploration.route_to(Vector2i(3, 0))
	assert_eq(Hex.distance(route[-1], Vector2i(3, 0)), 1)
	assert_eq(route.size(), 3, "the shortest way to a neighbor")


func test_unseen_hexes_cant_be_routed_to_on_fogged_maps() -> void:
	var exploration := Exploration.new(_session, _map, Vector2i.ZERO, true, 2)
	assert_false(exploration.route_to(Vector2i(2, 0)).is_empty())
	assert_true(exploration.route_to(Vector2i(4, 0)).is_empty())


func test_a_step_takes_time_and_reveals_fog() -> void:
	_map.set_terrain(Vector2i(1, 0), FakeContent.terrain(&"swamp", 2.0))
	var exploration := Exploration.new(_session, _map, Vector2i.ZERO, true, 2)
	var outcome := exploration.step_to(Vector2i(1, 0))
	assert_eq(outcome.hours, 2.0)
	assert_eq(_session.hours, GameSession.START_HOUR + 2.0)
	assert_eq(exploration.party_hex, Vector2i(1, 0))
	assert_true(outcome.fog_changed.has(Vector2i(3, 0)), "sees further east")
	assert_true(exploration.is_known(Vector2i(3, 0)))


func test_entering_a_region_is_reported_once() -> void:
	var vale := FakeContent.region(&"vale")
	_map.set_region(Vector2i(1, 0), vale)
	_map.set_region(Vector2i(2, 0), vale)
	var exploration := Exploration.new(_session, _map, Vector2i.ZERO, false)
	assert_eq(exploration.step_to(Vector2i(1, 0)).entered_region, vale)
	assert_null(exploration.step_to(Vector2i(2, 0)).entered_region, "still in the vale")


func test_stepping_onto_an_on_enter_poi_triggers_it_until_used() -> void:
	var lookout := FakeContent.poi(&"lookout", [FakeContent.message("A view!")], PoiDef.Trigger.ON_ENTER)
	lookout.once = true
	_map.set_poi(Vector2i(1, 0), lookout)
	var exploration := Exploration.new(_session, _map, Vector2i.ZERO, false)
	assert_eq(exploration.step_to(Vector2i(1, 0)).triggered_poi, lookout)
	exploration.map_state.mark_used(Vector2i(1, 0))
	exploration.step_to(Vector2i(0, 0))
	assert_null(exploration.step_to(Vector2i(1, 0)).triggered_poi, "used up")


func test_interacting_needs_standing_on_the_poi_or_next_to_a_blocking_one() -> void:
	var chest := FakeContent.poi(&"chest", [FakeContent.message("Loot")])
	var sign_post := FakeContent.poi(&"sign", [FakeContent.message("North")])
	sign_post.blocks_movement = true
	_map.set_poi(Vector2i(1, 0), chest)
	_map.set_poi(Vector2i(-1, 0), sign_post)
	var exploration := Exploration.new(_session, _map, Vector2i.ZERO, false)
	assert_null(exploration.poi_to_interact(Vector2i(1, 0)), "the chest is a step away")
	assert_eq(exploration.poi_to_interact(Vector2i(-1, 0)), sign_post, "the sign is close enough")
	exploration.step_to(Vector2i(1, 0))
	assert_eq(exploration.poi_to_interact(Vector2i(1, 0)), chest)
	assert_null(exploration.poi_to_interact(Vector2i(-1, 0)), "the sign is now out of reach")


func test_route_hours_add_up_each_step() -> void:
	_map.set_terrain(Vector2i(1, 0), FakeContent.terrain(&"swamp", 2.5))
	var exploration := Exploration.new(_session, _map, Vector2i.ZERO, false)
	var route: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)]
	assert_eq(exploration.route_hours(route), 3.5)
