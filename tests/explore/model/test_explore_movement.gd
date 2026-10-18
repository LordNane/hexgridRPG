extends GutTest

var _map: ExploreMap


func before_each() -> void:
	_map = FakeContent.uniform_map(3, FakeContent.terrain(&"grass"))


func test_a_step_costs_the_terrain_plus_the_feature() -> void:
	_map.set_terrain(Vector2i(1, 0), FakeContent.terrain(&"swamp", 2.0))
	_map.set_feature(Vector2i(1, 0), FakeContent.feature(&"forest", 1.0))
	var movement := ExploreMovement.new(_map)
	assert_eq(movement.step_cost(Vector2i.ZERO, Vector2i(1, 0)), 3.0)
	assert_eq(movement.step_cost(Vector2i.ZERO, Vector2i(0, 1)), 1.0)


func test_blocked_hexes_cost_inf() -> void:
	_map.set_terrain(Vector2i(1, 0), FakeContent.terrain(&"water", 1.0, false))
	_map.set_feature(Vector2i(0, 1), FakeContent.feature(&"peaks", 0.0, true))
	var sign_post := FakeContent.poi(&"sign", [FakeContent.message("North")])
	sign_post.blocks_movement = true
	_map.set_poi(Vector2i(-1, 0), sign_post)
	var movement := ExploreMovement.new(_map)
	assert_eq(movement.step_cost(Vector2i.ZERO, Vector2i(1, 0)), INF, "impassable terrain")
	assert_eq(movement.step_cost(Vector2i.ZERO, Vector2i(0, 1)), INF, "sheer feature")
	assert_eq(movement.step_cost(Vector2i.ZERO, Vector2i(-1, 0)), INF, "blocking POI")
	assert_eq(movement.step_cost(Vector2i(3, 0), Vector2i(4, 0)), INF, "off the map")


func test_unseen_hexes_cant_be_entered_on_fogged_maps() -> void:
	var explored: Dictionary[Vector2i, bool] = {Vector2i.ZERO: true, Vector2i(1, 0): true}
	var movement := ExploreMovement.new(_map, FogOfWar.new(_map, explored))
	assert_eq(movement.step_cost(Vector2i.ZERO, Vector2i(1, 0)), 1.0)
	assert_eq(movement.step_cost(Vector2i.ZERO, Vector2i(0, 1)), INF)


func test_min_step_cost_is_the_cheapest_passable_terrain() -> void:
	_map.set_terrain(Vector2i(2, 0), FakeContent.terrain(&"road", 0.5))
	_map.set_terrain(Vector2i(0, 2), FakeContent.terrain(&"lava", 0.1, false))
	assert_eq(ExploreMovement.new(_map).min_step_cost(), 0.5)
