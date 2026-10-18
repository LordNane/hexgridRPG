extends GutTest
## Battle's turn flow, actions and outcomes, on a flat map with two evenly matched fighters: each
## has 40 HP, 10 Attack, 6 Defense and 6 Speed, so a punch deals 12 damage give or take 10%.

var _map: BattleMap
var _hero: BattleUnit
var _foe: BattleUnit
var _battle: Battle


func before_each() -> void:
	_map = FakeBattle.flat_map()
	_hero = FakeBattle.unit("Hero", BattleUnit.Team.PARTY, Vector2i(0, 0))
	_foe = FakeBattle.unit("Foe", BattleUnit.Team.ENEMY, Vector2i(2, 0))
	_battle = FakeBattle.battle(_map, [_hero, _foe])


func test_turns_go_by_charge_time_and_ties_go_to_the_party() -> void:
	var events := _battle.start_turn()
	assert_eq(events.size(), 1)
	assert_is(events[0], TurnStartedEvent)
	assert_same(_battle.active, _hero)
	_battle.execute(WaitAction.new(_hero, Hex.Dir.SE))
	assert_null(_battle.active)
	_battle.start_turn()
	assert_same(_battle.active, _foe)


func test_moving_walks_the_cheapest_way_and_faces_along_it() -> void:
	_battle.start_turn()
	var events := _battle.execute(MoveAction.new(_hero, Vector2i(1, 0)))
	var moved := events[0] as UnitMovedEvent
	var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	assert_eq(moved.path, path)
	assert_eq(_hero.hex, Vector2i(1, 0))
	assert_eq(_hero.facing, Hex.Dir.SE)
	assert_eq(_battle.check(MoveAction.new(_hero, Vector2i(0, 0))), "Hero has already moved this turn.")


func test_actions_are_refused_with_reasons() -> void:
	_battle.start_turn()
	assert_eq(_battle.check(WaitAction.new(_foe, 0)), "It isn't Foe's turn.")
	assert_eq(_battle.check(MoveAction.new(_hero, Vector2i(2, 0))), "Hero can't get there.", "someone stands there")
	assert_eq(_battle.check(MoveAction.new(_hero, Vector2i(9, 0))), "Hero can't get there.", "off the map")
	var punch := _hero.character.attack_ability()
	assert_eq(_battle.check(AbilityAction.new(_hero, punch, Vector2i(2, 0))), "That's out of range.")
	assert_eq(_battle.check(AbilityAction.new(_hero, punch, Vector2i(1, 0))), "There's nobody there.")
	assert_eq(_battle.check(AbilityAction.new(_hero, FakeContent.ability(&"slash"), Vector2i(2, 0))), "Slash can't be used in battle yet.")


func test_an_attack_deals_damage_once_per_turn() -> void:
	_battle.start_turn()
	_battle.execute(MoveAction.new(_hero, Vector2i(1, 0)))
	var punch := _hero.character.attack_ability()
	var events := _battle.execute(AbilityAction.new(_hero, punch, Vector2i(2, 0)))
	assert_is(events[0], AbilityUsedEvent)
	var damaged := events[1] as UnitDamagedEvent
	assert_between(damaged.amount, 11, 13, "12 give or take 10%")
	assert_eq(damaged.hp, 40 - damaged.amount)
	assert_eq(_foe.character.hp, damaged.hp)
	assert_eq(_battle.check(AbilityAction.new(_hero, punch, Vector2i(2, 0))), "Hero has already acted this turn.")


func test_the_same_seed_rolls_the_same_damage() -> void:
	var amounts: Array[int] = []
	for _i: int in 2:
		before_each()
		_battle.start_turn()
		_battle.execute(MoveAction.new(_hero, Vector2i(1, 0)))
		var events := _battle.execute(AbilityAction.new(_hero, _hero.character.attack_ability(), Vector2i(2, 0)))
		amounts.append((events[1] as UnitDamagedEvent).amount)
	assert_eq(amounts[0], amounts[1])


func test_abilities_cost_mp_and_need_enough_of_it() -> void:
	var spark := FakeContent.attack(&"spark", 1, 3)
	spark.mp_cost = 4
	_battle.start_turn()
	_battle.execute(AbilityAction.new(_hero, spark, Vector2i(2, 0)))
	assert_eq(_hero.character.mp, 6)
	spark.mp_cost = 50
	_hero.acted = false
	assert_eq(_battle.check(AbilityAction.new(_hero, spark, Vector2i(2, 0))), "Spark needs 50 MP.")


func test_targets_too_far_above_are_out_of_reach() -> void:
	_map.set_height(Vector2i(1, 0), 3)
	var spear := FakeContent.attack(&"spear", 1, 1)
	spear.targeting.vertical_reach = 2
	_foe.hex = Vector2i(1, 0)
	_battle.start_turn()
	assert_eq(_battle.check(AbilityAction.new(_hero, spear, Vector2i(1, 0))), "That's too far above or below.")
	spear.targeting.vertical_reach = 3
	assert_eq(_battle.check(AbilityAction.new(_hero, spear, Vector2i(1, 0))), "")


func test_defeating_every_enemy_wins_the_battle() -> void:
	_foe.character.hp = 1
	_battle.start_turn()
	_battle.execute(MoveAction.new(_hero, Vector2i(1, 0)))
	var events := _battle.execute(AbilityAction.new(_hero, _hero.character.attack_ability(), Vector2i(2, 0)))
	assert_is(events[2], UnitDefeatedEvent)
	assert_is(events[3], BattleEndedEvent)
	assert_eq((events[3] as BattleEndedEvent).result, BattleOutcome.Result.VICTORY)
	assert_true(_battle.is_over())
	assert_null(_battle.unit_at(Vector2i(2, 0)), "the fallen don't hold their hex")
	assert_eq(_battle.check(WaitAction.new(_hero, 0)), "The battle is over.")


func test_losing_the_whole_party_loses_the_battle() -> void:
	_hero.character.hp = 1
	_battle.start_turn()
	_battle.execute(WaitAction.new(_hero, Hex.Dir.SE))
	_battle.start_turn()
	_battle.execute(MoveAction.new(_foe, Vector2i(1, 0)))
	_battle.execute(AbilityAction.new(_foe, _foe.character.attack_ability(), Vector2i(0, 0)))
	assert_eq(_battle.result, BattleOutcome.Result.DEFEAT)


func test_a_whole_battle_plays_out_the_same_from_the_same_seed() -> void:
	var endings: Array[String] = []
	for _i: int in 2:
		var units: Array[BattleUnit] = [
			FakeBattle.unit("Ann", BattleUnit.Team.PARTY, Vector2i(-3, 0)),
			FakeBattle.unit("Bo", BattleUnit.Team.PARTY, Vector2i(-3, 1)),
			FakeBattle.unit("Cy", BattleUnit.Team.ENEMY, Vector2i(3, 0)),
			FakeBattle.unit("Di", BattleUnit.Team.ENEMY, Vector2i(3, -1)),
		]
		var battle := FakeBattle.battle(FakeBattle.flat_map(), units, 99)
		for _turn: int in 200:
			if battle.is_over():
				break
			battle.start_turn()
			var action := PlaceholderAi.next_action(battle, battle.active)
			while not battle.is_over():
				battle.execute(action)
				if action is WaitAction or battle.is_over():
					break
				action = PlaceholderAi.next_action(battle, battle.active)
		assert_true(battle.is_over(), "the AI finishes the fight")
		var ending := PackedStringArray()
		for unit: BattleUnit in units:
			ending.append("%s:%d@%s" % [unit.name, unit.character.hp, unit.hex])
		endings.append(" ".join(ending))
	assert_eq(endings[0], endings[1])


func test_turn_order_lists_the_coming_turns() -> void:
	_battle.start_turn()
	var expected: Array[BattleUnit] = [_hero, _foe, _hero, _foe]
	assert_eq(_battle.turn_order(4), expected)
	assert_eq(_hero.ct, 102, "previewing changes nothing")
