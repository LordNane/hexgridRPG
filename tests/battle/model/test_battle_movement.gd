extends GutTest
## Battle movement: Move 4 and Jump 3 for the test fighters.

var _map: BattleMap
var _hero: BattleUnit


func before_each() -> void:
	_map = FakeBattle.flat_map(5)
	_hero = FakeBattle.unit("Hero", BattleUnit.Team.PARTY, Vector2i.ZERO)


func test_move_reaches_every_hex_within_its_steps() -> void:
	var battle := FakeBattle.battle(_map, [_hero])
	assert_eq(BattleMovement.destinations(battle, _hero).size(), Hex.disc(Vector2i.ZERO, 4).size())


func test_rough_terrain_costs_more_move() -> void:
	var swamp := FakeContent.terrain(&"swamp")
	swamp.battle_move_cost = 2
	for hex: Vector2i in _map.hexes():
		_map.set_cell(hex, swamp)
	var battle := FakeBattle.battle(_map, [_hero])
	assert_eq(BattleMovement.destinations(battle, _hero).size(), Hex.disc(Vector2i.ZERO, 2).size())


func test_a_step_cant_climb_or_drop_more_than_jump() -> void:
	_map.set_height(Vector2i(1, 0), 3)
	_map.set_height(Vector2i(0, 1), 4)
	var battle := FakeBattle.battle(_map, [_hero])
	var reach := BattleMovement.reach(battle, _hero)
	assert_eq(reach.cost_to(Vector2i(1, 0)), 1.0, "three levels up is within Jump 3")
	assert_eq(reach.cost_to(Vector2i(0, 1)), 2.0, "four levels up has to be reached from a ledge")
	assert_true(reach.path_to(Vector2i(0, 1)).has(Vector2i(1, 0)), "by way of the 3-high hex")


func test_foes_block_the_way_and_allies_can_be_passed_but_not_stopped_on() -> void:
	var corridor := BattleMap.new()
	for q: int in 4:
		corridor.set_cell(Vector2i(q, 0), FakeContent.terrain(&"grass"))
	var ally := FakeBattle.unit("Ally", BattleUnit.Team.PARTY, Vector2i(1, 0))
	var battle := FakeBattle.battle(corridor, [_hero, ally])
	var destinations := BattleMovement.destinations(battle, _hero)
	assert_true(destinations.has(Vector2i(3, 0)), "walks past the ally")
	assert_false(destinations.has(Vector2i(1, 0)), "can't stop on the ally")
	var foe := FakeBattle.unit("Foe", BattleUnit.Team.ENEMY, Vector2i(1, 0))
	battle = FakeBattle.battle(corridor, [_hero, foe])
	assert_false(BattleMovement.destinations(battle, _hero).has(Vector2i(3, 0)), "the foe blocks the corridor")


func test_impassable_terrain_and_blocking_props_cant_be_entered() -> void:
	_map.set_cell(Vector2i(1, 0), FakeContent.terrain(&"water", 1.0, false))
	_map.set_prop(Vector2i(0, 1), FakeContent.prop(&"tree"))
	_map.set_prop(Vector2i(-1, 0), FakeContent.prop(&"grass_tuft", false))
	var battle := FakeBattle.battle(_map, [_hero])
	var destinations := BattleMovement.destinations(battle, _hero)
	assert_false(destinations.has(Vector2i(1, 0)))
	assert_false(destinations.has(Vector2i(0, 1)))
	assert_true(destinations.has(Vector2i(-1, 0)), "a prop that doesn't block can be stood on")
