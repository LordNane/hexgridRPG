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
	var exploration := _explore(false)
	var route := exploration.route_to(Vector2i(2, 0))
	assert_eq(route[0], Vector2i.ZERO)
	assert_eq(route[-1], Vector2i(2, 0))
	for hex: Vector2i in route:
		assert_true(_map.terrain_at(hex).passable, "%s is dry" % hex)


func test_route_to_a_blocking_poi_ends_next_to_it() -> void:
	var sign_post := FakeContent.poi(&"sign", [FakeContent.message("North")])
	sign_post.blocks_movement = true
	_map.set_poi(Vector2i(3, 0), sign_post)
	var exploration := _explore(false)
	var route := exploration.route_to(Vector2i(3, 0))
	assert_eq(Hex.distance(route[-1], Vector2i(3, 0)), 1)
	assert_eq(route.size(), 3, "the shortest way to a neighbor")


func test_unseen_hexes_cant_be_routed_to_on_fogged_maps() -> void:
	var exploration := _explore(true, 2)
	assert_false(exploration.route_to(Vector2i(2, 0)).is_empty())
	assert_true(exploration.route_to(Vector2i(4, 0)).is_empty())


func test_a_step_takes_time_and_reveals_fog() -> void:
	_map.set_terrain(Vector2i(1, 0), FakeContent.terrain(&"swamp", 2.0))
	var exploration := _explore(true, 2)
	var outcome := exploration.step_to(Vector2i(1, 0))
	assert_eq(outcome.hours, 2.0)
	assert_eq(_session.hours, GameSession.START_HOUR + 2.0)
	assert_eq(exploration.party_hex, Vector2i(1, 0))
	assert_true(outcome.fog_changed.has(Vector2i(3, 0)), "sees further east")
	assert_true(exploration.is_known(Vector2i(3, 0)))


func test_steps_move_the_party_in_the_session_so_saves_know_where_it_is() -> void:
	var exploration := _explore(false)
	assert_same(exploration.position, _session.location())
	exploration.step_to(Vector2i(1, 0))
	exploration.step_to(Vector2i(1, 1))
	assert_eq(_session.location().hex, Vector2i(1, 1))


func test_entering_a_region_is_reported_once() -> void:
	var vale := FakeContent.region(&"vale")
	_map.set_region(Vector2i(1, 0), vale)
	_map.set_region(Vector2i(2, 0), vale)
	var exploration := _explore(false)
	assert_eq(exploration.step_to(Vector2i(1, 0)).entered_region, vale)
	assert_null(exploration.step_to(Vector2i(2, 0)).entered_region, "still in the vale")


func test_stepping_onto_an_on_enter_poi_triggers_it_until_used() -> void:
	var lookout := FakeContent.poi(&"lookout", [FakeContent.message("A view!")], PoiDef.Trigger.ON_ENTER)
	lookout.once = true
	_map.set_poi(Vector2i(1, 0), lookout)
	var exploration := _explore(false)
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
	var exploration := _explore(false)
	assert_null(exploration.poi_to_interact(Vector2i(1, 0)), "the chest is a step away")
	assert_eq(exploration.poi_to_interact(Vector2i(-1, 0)), sign_post, "the sign is close enough")
	exploration.step_to(Vector2i(1, 0))
	assert_eq(exploration.poi_to_interact(Vector2i(1, 0)), chest)
	assert_null(exploration.poi_to_interact(Vector2i(-1, 0)), "the sign is now out of reach")


func test_route_hours_add_up_each_step() -> void:
	_map.set_terrain(Vector2i(1, 0), FakeContent.terrain(&"swamp", 2.5))
	var exploration := _explore(false)
	var route: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)]
	assert_eq(exploration.route_hours(route), 3.5)


## Explores [member _map] with the party entering it at the origin.
func test_steps_in_a_region_with_encounters_can_start_a_battle() -> void:
	var bandits := FakeContent.encounter(&"bandits", [FakeContent.enemy(&"bandit", FakeContent.job(&"brawler"))])
	var table := EncounterTable.new()
	table.chance_per_step = 1.0
	table.encounters = {bandits: 1}
	var region := FakeContent.region(&"wilds")
	region.encounters = table
	for hex: Vector2i in _map.hexes():
		_map.set_region(hex, region)
	_session.encounter_grace = 1
	var exploration := _explore(false)
	assert_null(exploration.step_to(Vector2i(1, 0)).encounter, "the grace period comes first")
	assert_eq(exploration.step_to(Vector2i(2, 0)).encounter, bandits)
	var ambush := FakeContent.poi(&"ambush", [FakeContent.message("!")], PoiDef.Trigger.ON_ENTER)
	_map.set_poi(Vector2i(3, 0), ambush)
	var outcome := exploration.step_to(Vector2i(3, 0))
	assert_eq(outcome.triggered_poi, ambush)
	assert_null(outcome.encounter, "no random battle on top of a POI that triggers")


func _explore(has_fog: bool, sight: int = 3) -> Exploration:
	return Exploration.new(_session, _map, _session.enter_map(_map.id, Vector2i.ZERO), has_fog, sight)
