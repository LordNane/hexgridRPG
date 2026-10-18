extends GutTest
## The stand-in AI, for fighters with Move 4 who punch one hex away.

var _map: BattleMap


func before_each() -> void:
	_map = FakeBattle.flat_map(6)


func test_attacks_a_foe_in_reach() -> void:
	var hero := FakeBattle.unit("Hero", BattleUnit.Team.PARTY, Vector2i(1, 0))
	var foe := FakeBattle.unit("Foe", BattleUnit.Team.ENEMY, Vector2i(0, 0))
	var battle := _started([foe, hero])
	var action := PlaceholderAi.next_action(battle, foe) as AbilityAction
	assert_not_null(action)
	assert_eq(action.target, hero.hex)


func test_picks_the_weakest_foe_in_reach() -> void:
	var sturdy := FakeBattle.unit("Sturdy", BattleUnit.Team.PARTY, Vector2i(1, 0))
	var hurt := FakeBattle.unit("Hurt", BattleUnit.Team.PARTY, Vector2i(-1, 0))
	hurt.character.hp = 5
	var foe := FakeBattle.unit("Foe", BattleUnit.Team.ENEMY, Vector2i(0, 0))
	var battle := _started([foe, sturdy, hurt])
	assert_eq((PlaceholderAi.next_action(battle, foe) as AbilityAction).target, hurt.hex)


func test_walks_into_reach_then_attacks() -> void:
	var hero := FakeBattle.unit("Hero", BattleUnit.Team.PARTY, Vector2i(3, 0))
	var foe := FakeBattle.unit("Foe", BattleUnit.Team.ENEMY, Vector2i(-1, 0))
	var battle := _started([foe, hero])
	var move := PlaceholderAi.next_action(battle, foe) as MoveAction
	assert_not_null(move)
	assert_eq(Hex.distance(move.destination, hero.hex), 1)
	battle.execute(move)
	assert_is(PlaceholderAi.next_action(battle, foe), AbilityAction)


func test_heads_for_a_foe_out_of_reach_then_waits_facing_it() -> void:
	var hero := FakeBattle.unit("Hero", BattleUnit.Team.PARTY, Vector2i(3, 0))
	var foe := FakeBattle.unit("Foe", BattleUnit.Team.ENEMY, Vector2i(-3, 0))
	var battle := _started([foe, hero])
	var move := PlaceholderAi.next_action(battle, foe) as MoveAction
	assert_eq(Hex.distance(move.destination, hero.hex), 2, "as close as Move 4 gets")
	battle.execute(move)
	var wait := PlaceholderAi.next_action(battle, foe) as WaitAction
	assert_not_null(wait)
	assert_eq(wait.facing, Hex.direction_to(foe.hex, hero.hex))


## A battle with [param units], already on the first one's turn.
func _started(units: Array[BattleUnit]) -> Battle:
	var battle := FakeBattle.battle(_map, units)
	battle.start_turn()
	assert_same(battle.active, units[0])
	return battle
