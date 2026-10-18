extends GutTest

var _map: ExploreMap
var _explored: Dictionary[Vector2i, bool]
var _fog: FogOfWar


func before_each() -> void:
	_map = FakeContent.uniform_map(6, FakeContent.terrain(&"grass"))
	_explored = {}
	_fog = FogOfWar.new(_map, _explored)


func test_sees_everything_within_the_radius_on_open_ground() -> void:
	_fog.look_from(Vector2i.ZERO, 2)
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, 2):
		assert_true(_fog.is_visible(hex), "sees %s" % hex)
		assert_true(_fog.is_explored(hex))
	assert_false(_fog.is_visible(Vector2i(3, 0)))
	assert_false(_fog.is_explored(Vector2i(3, 0)))


func test_a_forest_is_seen_but_hides_what_is_behind_it() -> void:
	_map.set_feature(Vector2i(1, 0), FakeContent.feature(&"forest", 1.0, false, true))
	_fog.look_from(Vector2i.ZERO, 3)
	assert_true(_fog.is_visible(Vector2i(1, 0)), "the forest itself")
	assert_false(_fog.is_visible(Vector2i(2, 0)), "right behind it")
	assert_false(_fog.is_visible(Vector2i(3, 0)), "further behind it")
	assert_true(_fog.is_visible(Vector2i(0, 3)), "other directions are clear")


func test_looking_again_reports_changes_and_remembers_what_was_seen() -> void:
	_fog.look_from(Vector2i.ZERO, 1)
	var changed := _fog.look_from(Vector2i(3, 0), 1)
	assert_true(changed.has(Vector2i(-1, 0)), "left behind: now remembered, not visible")
	assert_true(changed.has(Vector2i(4, 0)), "newly seen")
	assert_false(changed.has(Vector2i(5, 0)), "still unseen")
	assert_false(_fog.is_visible(Vector2i(-1, 0)))
	assert_true(_fog.is_explored(Vector2i(-1, 0)))


func test_seen_hexes_land_in_the_saved_explored_set() -> void:
	_fog.look_from(Vector2i.ZERO, 1)
	assert_eq(_explored.size(), 7)


func test_nothing_changes_when_looking_from_the_same_place() -> void:
	_fog.look_from(Vector2i.ZERO, 2)
	assert_true(_fog.look_from(Vector2i.ZERO, 2).is_empty())
